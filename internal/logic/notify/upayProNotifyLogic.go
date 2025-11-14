package notify

import (
	"encoding/json"

	"github.com/perfect-panel/server/pkg/constant"

	"github.com/perfect-panel/server/pkg/xerr"
	"github.com/pkg/errors"

	"github.com/gin-gonic/gin"

	"github.com/hibiken/asynq"
	"github.com/perfect-panel/server/internal/model/payment"
	"github.com/perfect-panel/server/internal/svc"
	"github.com/perfect-panel/server/internal/types"
	"github.com/perfect-panel/server/pkg/logger"
	"github.com/perfect-panel/server/pkg/payment/upaypro"

	queueType "github.com/perfect-panel/server/queue/types"
)

type UPayProNotifyLogic struct {
	logger.Logger
	ctx    *gin.Context
	svcCtx *svc.ServiceContext
}

// NewUPayProNotifyLogic UPayPro notify
func NewUPayProNotifyLogic(ctx *gin.Context, svcCtx *svc.ServiceContext) *UPayProNotifyLogic {
	return &UPayProNotifyLogic{
		Logger: logger.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *UPayProNotifyLogic) UPayProNotify(req *types.UPayProNotifyRequest) error {
	// Find payment config
	data, ok := l.ctx.Request.Context().Value(constant.CtxKeyPayment).(*payment.Payment)
	if !ok {
		l.Logger.Error("[UPayProNotify] Payment not found in context")
		return errors.Wrapf(xerr.NewErrCode(xerr.ERROR), "payment config not found")
	}
	l.Infof("[UPayProNotify] Payment config: %+v", data)

	// Find order by order_id
	orderInfo, err := l.svcCtx.OrderModel.FindOneByOrderNo(l.ctx, req.OrderID)
	if err != nil {
		l.Logger.Error("[UPayProNotify] Find order failed", logger.Field("error", err.Error()), logger.Field("orderNo", req.OrderID))
		return errors.Wrapf(xerr.NewErrCode(xerr.OrderNotExist), "order not exist: %v", req.OrderID)
	}

	// Parse UPayPro configuration
	var config payment.UPayProConfig
	if err := json.Unmarshal([]byte(data.Config), &config); err != nil {
		l.Logger.Errorw("[UPayProNotify] Unmarshal config failed", logger.Field("error", err.Error()))
		return err
	}

	// Initialize UPayPro client and verify callback signature
	client := upaypro.NewClient(config.BaseURL, config.SecretKey, config.Type)
	callback := upaypro.PaymentCallback{
		TradeID:   req.TradeID,
		OrderID:   req.OrderID,
		Amount:    req.Amount,
		Status:    req.Status,
		PayTime:   req.PayTime,
		TxHash:    req.TxHash,
		Signature: req.Signature,
	}

	// Verify callback signature (skip in debug mode)
	if !client.VerifyCallback(callback) && !l.svcCtx.Config.Debug {
		l.Logger.Error("[UPayProNotify] Verify signature failed")
		return errors.Wrapf(xerr.NewErrCode(xerr.ERROR), "signature verification failed")
	}

	// Check if payment was successful
	if req.Status != "success" {
		l.Logger.Error("[UPayProNotify] Payment status is not success", logger.Field("orderNo", req.OrderID), logger.Field("status", req.Status))
		return nil
	}

	// Skip if order already completed
	if orderInfo.Status == 5 {
		return nil
	}

	// Update order status to paid (status = 2)
	err = l.svcCtx.OrderModel.UpdateOrderStatus(l.ctx, req.OrderID, 2)
	if err != nil {
		l.Logger.Error("[UPayProNotify] Update order status failed", logger.Field("error", err.Error()), logger.Field("orderNo", req.OrderID))
		return err
	}

	// Create activate order task
	payload := queueType.ForthwithActivateOrderPayload{
		OrderNo: req.OrderID,
	}
	bytes, err := json.Marshal(&payload)
	if err != nil {
		l.Logger.Error("[UPayProNotify] Marshal payload failed", logger.Field("error", err.Error()))
		return err
	}
	task := asynq.NewTask(queueType.ForthwithActivateOrder, bytes)
	taskInfo, err := l.svcCtx.Queue.EnqueueContext(l.ctx, task)
	if err != nil {
		l.Logger.Error("[UPayProNotify] Enqueue task failed", logger.Field("error", err.Error()))
		return err
	}
	l.Logger.Info("[UPayProNotify] Enqueue task success", logger.Field("taskInfo", taskInfo))
	return nil
}
