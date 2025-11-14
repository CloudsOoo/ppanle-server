#!/bin/bash

if [ -f /tmp/http-server.pid ]; then
    PID=$(cat /tmp/http-server.pid)
    kill $PID 2>/dev/null && echo "✓ HTTP 服务器已停止 (PID: $PID)" || echo "进程不存在"
    rm -f /tmp/http-server.pid
else
    echo "PID 文件不存在，尝试查找进程..."
    pkill -f "python3 -m http.server 8888" && echo "✓ 已停止 HTTP 服务器" || echo "未找到运行中的进程"
fi
