#!/bin/bash

cd /home/user/ppanle-server/release-v1.0.0-upay-pro

# 启动 HTTP 服务器
nohup python3 -m http.server 9999 > /tmp/release-server.log 2>&1 &
echo $! > /tmp/release-server.pid

sleep 2

# 获取 IP 地址
IP=$(hostname -I | awk '{print $1}')

echo "✅ 下载页面已启动！"
echo ""
echo "════════════════════════════════════════"
echo "📥 在浏览器中打开下面的地址下载："
echo "════════════════════════════════════════"
echo ""
echo "内网地址: http://${IP}:9999"
echo ""
echo "本地地址: http://127.0.0.1:9999"
echo ""
echo "如果是公网服务器，请替换为你的公网IP"
echo ""
echo "════════════════════════════════════════"
echo ""
echo "停止下载服务器："
echo "  kill $(cat /tmp/release-server.pid)"
echo ""
