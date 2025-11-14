package upaypro

import (
    "crypto/md5"
    "encoding/hex"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "sort"
    "strings"
    "time"
)

// Config UPAY_PRO 配置
type Config struct {
    BaseURL   string `json:"base_url"`
    APIKey    string `json:"api_key"`
    SecretKey string `json:"secret_key"`
    NotifyURL string `json:"notify_url"`
}

// Client UPAY_PRO 客户端
type Client struct {
    config Config
}

// NewClient 创建客户端
func NewClient(config Config) *Client {
    return &Client{config: config}
}

// CreateOrderRequest 创建订单请求
type CreateOrderRequest struct {
    Type        string  `json:"type"`         // USDT-TRC20, USDT-ERC20 等
    OrderID     string  `json:"order_id"`     // 商户订单号
    Amount      float64 `json:"amount"`       // 金额(USDT)
    NotifyURL   string  `json:"notify_url"`   // 回调地址
    RedirectURL string  `json:"redirect_url"` // 跳转地址
    Signature   string  `json:"signature"`    // 签名
}

// CreateOrderResponse 创建订单响应
type CreateOrderResponse struct {
    Code    int    `json:"code"`
    Message string `json:"message"`
    Data    struct {
        TradeID string  `json:"trade_id"` // 交易ID
        PayURL  string  `json:"pay_url"`  // 支付页面URL
        Amount  float64 `json:"amount"`   // 实际金额
        Address string  `json:"address"`  // 收款地址
    } `json:"data"`
}

// CreateOrder 创建支付订单
func (c *Client) CreateOrder(req CreateOrderRequest) (*CreateOrderResponse, error) {
    // 设置回调地址
    req.NotifyURL = c.config.NotifyURL

    // 生成签名
    req.Signature = c.generateSignature(map[string]interface{}{
        "type":         req.Type,
        "order_id":     req.OrderID,
        "amount":       req.Amount,
        "notify_url":   req.NotifyURL,
        "redirect_url": req.RedirectURL,
    })

    // 序列化请求
    body, err := json.Marshal(req)
    if err != nil {
        return nil, fmt.Errorf("marshal request failed: %w", err)
    }

    // 发送 HTTP 请求
    httpReq, err := http.NewRequest("POST", c.config.BaseURL+"/api/create_order", strings.NewReader(string(body)))
    if err != nil {
        return nil, fmt.Errorf("create request failed: %w", err)
    }
    httpReq.Header.Set("Content-Type", "application/json")

    client := &http.Client{Timeout: 30 * time.Second}
    resp, err := client.Do(httpReq)
    if err != nil {
        return nil, fmt.Errorf("http request failed: %w", err)
    }
    defer resp.Body.Close()

    // 读取响应
    respBody, err := io.ReadAll(resp.Body)
    if err != nil {
        return nil, fmt.Errorf("read response failed: %w", err)
    }

    // 解析响应
    var result CreateOrderResponse
    if err := json.Unmarshal(respBody, &result); err != nil {
        return nil, fmt.Errorf("unmarshal response failed: %w", err)
    }

    if result.Code != 200 {
        return nil, fmt.Errorf("create order failed: %s", result.Message)
    }

    return &result, nil
}

// PaymentCallback 支付回调数据
type PaymentCallback struct {
    TradeID   string  `form:"trade_id"`
    OrderID   string  `form:"order_id"`
    Amount    float64 `form:"amount"`
    Status    string  `form:"status"` // success/failed
    PayTime   string  `form:"pay_time"`
    TxHash    string  `form:"tx_hash"`
    Signature string  `form:"signature"`
}

// VerifyCallback 验证回调签名
func (c *Client) VerifyCallback(callback PaymentCallback) bool {
    expectedSign := c.generateSignature(map[string]interface{}{
        "trade_id": callback.TradeID,
        "order_id": callback.OrderID,
        "amount":   callback.Amount,
        "status":   callback.Status,
        "pay_time": callback.PayTime,
        "tx_hash":  callback.TxHash,
    })

    return callback.Signature == expectedSign
}

// CheckOrderStatus 查询订单状态
func (c *Client) CheckOrderStatus(tradeID string) (string, error) {
    resp, err := http.Get(c.config.BaseURL + "/pay/check-status/" + tradeID)
    if err != nil {
        return "", fmt.Errorf("http request failed: %w", err)
    }
    defer resp.Body.Close()

    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return "", fmt.Errorf("read response failed: %w", err)
    }

    var result struct {
        Code   int    `json:"code"`
        Status string `json:"status"` // pending/success/failed
    }
    if err := json.Unmarshal(body, &result); err != nil {
        return "", fmt.Errorf("unmarshal response failed: %w", err)
    }

    return result.Status, nil
}

// generateSignature 生成 MD5 签名
func (c *Client) generateSignature(params map[string]interface{}) string {
    // 1. 参数排序
    keys := make([]string, 0, len(params))
    for k := range params {
        keys = append(keys, k)
    }
    sort.Strings(keys)

    // 2. 拼接字符串
    var builder strings.Builder
    for _, k := range keys {
        builder.WriteString(fmt.Sprintf("%s=%v&", k, params[k]))
    }
    // 添加密钥
    builder.WriteString("key=")
    builder.WriteString(c.config.SecretKey)

    // 3. MD5 加密
    hash := md5.Sum([]byte(builder.String()))
    return hex.EncodeToString(hash[:])
}