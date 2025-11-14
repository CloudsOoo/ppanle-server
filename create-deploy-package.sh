#!/bin/bash
set -e

echo "创建部署包..."

DEPLOY_DIR="deploy"
rm -rf ${DEPLOY_DIR}
mkdir -p ${DEPLOY_DIR}/ppanel-server

# 复制文件
cp bin/ppanel-server ${DEPLOY_DIR}/ppanel-server/
cp -r etc ${DEPLOY_DIR}/ppanel-server/
mkdir -p ${DEPLOY_DIR}/ppanel-server/{logs,data}

# 创建启动脚本
cat > ${DEPLOY_DIR}/ppanel-server/start.sh << 'STARTSCRIPT'
#!/bin/bash
cd "$(dirname "$0")"
nohup ./ppanel-server run --config etc/ppanel.yaml > logs/ppanel.log 2>&1 &
echo $! > ppanel.pid
echo "PPanel Server 已启动，PID: $(cat ppanel.pid)"
echo "查看日志: tail -f logs/ppanel.log"
STARTSCRIPT
chmod +x ${DEPLOY_DIR}/ppanel-server/start.sh

# 创建停止脚本
cat > ${DEPLOY_DIR}/ppanel-server/stop.sh << 'STOPSCRIPT'
#!/bin/bash
cd "$(dirname "$0")"
if [ -f ppanel.pid ]; then
    PID=$(cat ppanel.pid)
    kill $PID 2>/dev/null && echo "已停止 PPanel Server (PID: $PID)" || echo "进程不存在"
    rm -f ppanel.pid
else
    echo "PID 文件不存在，尝试查找进程..."
    pkill -f ppanel-server && echo "已停止 ppanel-server" || echo "未找到运行中的进程"
fi
STOPSCRIPT
chmod +x ${DEPLOY_DIR}/ppanel-server/stop.sh

# 创建 systemd 服务
cat > ${DEPLOY_DIR}/ppanel-server/ppanel-server.service << 'SERVICE'
[Unit]
Description=PPanel Server
After=network.target mysql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ppanel-server
ExecStart=/opt/ppanel-server/ppanel-server run --config /opt/ppanel-server/etc/ppanel.yaml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
SERVICE

# 创建安装说明
cat > ${DEPLOY_DIR}/ppanel-server/INSTALL.txt << 'INSTALL'
====================================
  PPanel Server 部署说明
====================================

一、快速部署（脚本方式）
------------------------
1. 解压到 /opt 目录
   tar -xzf ppanel-server.tar.gz -C /opt

2. 配置文件（必须）
   nano /opt/ppanel-server/etc/ppanel.yaml
   （配置数据库、Redis 等）

3. 启动服务
   cd /opt/ppanel-server
   ./start.sh

4. 查看日志
   tail -f logs/ppanel.log

5. 停止服务
   ./stop.sh


二、systemd 服务方式（推荐生产环境）
---------------------------------
1. 解压到 /opt 目录
   tar -xzf ppanel-server.tar.gz -C /opt

2. 配置文件（必须）
   nano /opt/ppanel-server/etc/ppanel.yaml

3. 安装 systemd 服务
   cp /opt/ppanel-server/ppanel-server.service /etc/systemd/system/
   systemctl daemon-reload

4. 启动服务
   systemctl enable ppanel-server
   systemctl start ppanel-server

5. 查看状态
   systemctl status ppanel-server

6. 查看日志
   journalctl -u ppanel-server -f


三、在 1Panel 中配置反向代理
--------------------------
1. 进入 1Panel 面板
2. 网站 → 创建网站
3. 选择 反向代理
4. 代理地址: http://127.0.0.1:8080
5. 绑定域名
6. 配置 SSL（可选）


四、验证安装
-----------
curl http://localhost:8080/health

或浏览器访问: http://your-ip:8080


五、注意事项
-----------
1. 确保 MySQL/MariaDB 已安装并运行
2. 确保 Redis 已安装并运行
3. 配置文件中的数据库密码、Redis 密码需要正确
4. 防火墙需要开放 8080 端口（或使用反向代理）
INSTALL

# 打包
cd ${DEPLOY_DIR}
tar -czf ppanel-server.tar.gz ppanel-server/

echo "✓ 部署包创建完成！"
echo ""
echo "文件位置:"
echo "  - 二进制文件: $(pwd)/../bin/ppanel-server ($(ls -lh ../bin/ppanel-server | awk '{print $5}'))"
echo "  - 部署包: $(pwd)/ppanel-server.tar.gz ($(ls -lh ppanel-server.tar.gz | awk '{print $5}'))"
echo ""
