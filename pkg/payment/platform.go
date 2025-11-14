package payment

import "github.com/perfect-panel/server/internal/types"

type Platform int

const (
    UNSUPPORTED Platform = iota
    Stripe
    AlipayF2F
    EPay
    CryptoSaaS
    Balance
    UPayPro    
)

var platformNames = map[string]Platform{
	"CryptoSaaS":  CryptoSaaS,
	"Stripe":      Stripe,
	"AlipayF2F":   AlipayF2F,
	"EPay":        EPay,
	"balance":     Balance,
	"UPayPro":     UPayPro, 
	"unsupported": UNSUPPORTED,
}

func (p Platform) String() string {
	for k, v := range platformNames {
		if v == p {
			return k
		}
	}
	return "unsupported"
}

func ParsePlatform(s string) Platform {
	if p, ok := platformNames[s]; ok {
		return p
	}
	return UNSUPPORTED
}

func GetSupportedPlatforms() []types.PlatformInfo {
	return []types.PlatformInfo{
		{
			Platform:    Stripe.String(),
			PlatformUrl: "https://stripe.com",
			PlatformFieldDescription: map[string]string{
				"public_key":     "Publishable key",
				"secret_key":     "Secret key",
				"webhook_secret": "Webhook secret",
				"payment":        "Payment Method, only supported card/alipay/wechat_pay",
			},
		},
		{
			Platform:    AlipayF2F.String(),
			PlatformUrl: "https://alipay.com",
			PlatformFieldDescription: map[string]string{
				"app_id":       "App ID",
				"private_key":  "Private Key",
				"public_key":   "Public Key",
				"invoice_name": "Invoice Name",
				"sandbox":      "Sandbox Mode",
			},
		},
		{
			Platform:    EPay.String(),
			PlatformUrl: "",
			PlatformFieldDescription: map[string]string{
				"pid":  "PID",
				"url":  "URL",
				"key":  "Key",
				"type": "Type",
			},
		},
		{
			Platform:    CryptoSaaS.String(),
			PlatformUrl: "https://t.me/CryptoSaaSBot",
			PlatformFieldDescription: map[string]string{
				"endpoint":   "API Endpoint",
				"account_id": "Account ID",
				"secret_key": "Secret Key",
			},
		},
		// 新增 UPayPro 配置
		{
			Platform:    UPayPro.String(),
			PlatformUrl: "https://github.com/wangegou/UPAY_PRO",
    		PlatformFieldDescription: map[string]string{
				"base_url":   "应用地址 (例如: http://your-domain:8090)",
        		"secret_key": "系统密钥 (从 UPAY_PRO 后台获取)",
			},
		},
	}
}
