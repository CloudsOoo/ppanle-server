#!/bin/bash

cd /home/user/ppanle-server/deploy

# 启动 HTTP 服务器
nohup python3 -m http.server 8888 > /tmp/http-server.log 2>&1 &
echo $! > /tmp/http-server.pid

sleep 2

# 获取 IP 地址
IP=$(hostname -I | awk '{print $1}')

echo "✓ HTTP 下载服务器已启动！"
echo ""
echo "════════════════════════════════════════"
echo "📥 下载地址："
echo "════════════════════════════════════════"
echo ""
echo "方式1 - 内网地址："
echo "  http://${IP}:8888/ppanel-server.tar.gz"
echo ""
echo "方式2 - 本地地址："
echo "  http://127.0.0.1:8888/ppanel-server.tar.gz"
echo ""
echo "方式3 - 使用 wget 下载："
echo "  wget http://${IP}:8888/ppanel-server.tar.gz"
echo ""
echo "方式4 - 使用 curl 下载："
echo "  curl -O http://${IP}:8888/ppanel-server.tar.gz"
echo ""
echo "════════════════════════════════════════"
echo "📋 服务器信息："
echo "════════════════════════════════════════"
echo "  端口: 8888"
echo "  PID: $(cat /tmp/http-server.pid)"
echo "  目录: /home/user/ppanle-server/deploy"
echo "  文件大小: $(ls -lh ppanel-server.tar.gz | awk '{print $5}')"
echo ""
echo "════════════════════════════════════════"
echo "🛑 停止服务器："
echo "════════════════════════════════════════"
echo "  bash /home/user/ppanle-server/stop-download-server.sh"
echo "  或直接: kill $(cat /tmp/http-server.pid)"
echo ""
