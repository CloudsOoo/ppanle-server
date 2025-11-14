#!/bin/bash
set -e

echo "======================================"
echo "  PPanel Server 一键编译脚本"
echo "======================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查并安装 Go
check_go() {
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        echo -e "${GREEN}✓${NC} Go 已安装: $GO_VERSION"
        return 0
    else
        echo -e "${YELLOW}!${NC} Go 未安装，开始安装 Go 1.21.6..."

        cd /tmp
        wget -q --show-progress https://go.dev/dl/go1.21.6.linux-amd64.tar.gz

        if [ -d /usr/local/go ]; then
            echo "删除旧版本 Go..."
            rm -rf /usr/local/go
        fi

        tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz

        # 设置环境变量
        export PATH=$PATH:/usr/local/go/bin
        export GOPATH=$HOME/go
        export GO111MODULE=on
        export GOPROXY=https://goproxy.cn,direct

        # 写入 bashrc
        if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
            echo 'export GOPATH=$HOME/go' >> ~/.bashrc
            echo 'export GO111MODULE=on' >> ~/.bashrc
            echo 'export GOPROXY=https://goproxy.cn,direct' >> ~/.bashrc
        fi

        echo -e "${GREEN}✓${NC} Go 安装完成: $(go version)"
        cd - > /dev/null
    fi
}

# 检查并安装 make
check_make() {
    if command -v make &> /dev/null; then
        echo -e "${GREEN}✓${NC} Make 已安装"
        return 0
    else
        echo -e "${YELLOW}!${NC} Make 未安装，开始安装..."
        apt update -qq
        apt install -y make
        echo -e "${GREEN}✓${NC} Make 安装完成"
    fi
}

# 下载依赖
download_deps() {
    echo ""
    echo "下载 Go 依赖..."
    go mod download
    echo -e "${GREEN}✓${NC} 依赖下载完成"
}

# 编译项目
build_project() {
    echo ""
    echo "编译项目..."

    # 创建 bin 目录
    mkdir -p bin

    # 编译
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
        -trimpath \
        -ldflags '-w -s -buildid=' \
        -o bin/ppanel-server \
        .

    chmod +x bin/ppanel-server

    echo -e "${GREEN}✓${NC} 编译完成！"
}

# 创建部署包
create_deploy_package() {
    echo ""
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
    kill $PID 2>/dev/null && echo "PPanel Server 已停止 (PID: $PID)" || echo "进程不存在"
    rm -f ppanel.pid
else
    echo "PID 文件不存在，尝试查找进程..."
    pkill -f ppanel-server && echo "已停止 ppanel-server 进程" || echo "未找到运行中的进程"
fi
STOPSCRIPT
    chmod +x ${DEPLOY_DIR}/ppanel-server/stop.sh

    # 创建 systemd 服务文件
    cat > ${DEPLOY_DIR}/ppanel-server/ppanel-server.service << 'SERVICEUNIT'
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
SERVICEUNIT

    # 创建安装说明
    cat > ${DEPLOY_DIR}/ppanel-server/README.md << 'README'
# PPanel Server 部署包

## 快速部署

### 方法一：直接运行

```bash
# 1. 解压到 /opt
sudo tar -xzf ppanel-server.tar.gz -C /opt

# 2. 配置数据库和 Redis
sudo nano /opt/ppanel-server/etc/ppanel.yaml

# 3. 启动服务
cd /opt/ppanel-server
./start.sh

# 4. 查看日志
tail -f logs/ppanel.log

# 停止服务
./stop.sh
```

### 方法二：systemd 服务（推荐）

```bash
# 1. 解压到 /opt
sudo tar -xzf ppanel-server.tar.gz -C /opt

# 2. 配置数据库和 Redis
sudo nano /opt/ppanel-server/etc/ppanel.yaml

# 3. 安装服务
sudo cp /opt/ppanel-server/ppanel-server.service /etc/systemd/system/

# 4. 启动并设置开机自启
sudo systemctl daemon-reload
sudo systemctl enable ppanel-server
sudo systemctl start ppanel-server

# 5. 查看状态
sudo systemctl status ppanel-server

# 6. 查看日志
sudo journalctl -u ppanel-server -f
```

## 访问

默认端口: 8080
访问地址: http://your-server-ip:8080

## 在 1Panel 中配置反向代理

1. 进入 1Panel → 网站 → 创建网站
2. 选择反向代理
3. 代理地址: http://127.0.0.1:8080
4. 绑定域名并配置 SSL
README

    # 打包
    cd ${DEPLOY_DIR}
    tar -czf ppanel-server.tar.gz ppanel-server/

    echo -e "${GREEN}✓${NC} 部署包创建完成！"
}

# 主函数
main() {
    # 检查环境
    check_go
    check_make

    # 下载依赖
    download_deps

    # 编译
    build_project

    # 创建部署包
    create_deploy_package

    echo ""
    echo "======================================"
    echo -e "${GREEN}编译完成！${NC}"
    echo "======================================"
    echo ""
    echo "编译文件位置:"
    echo "  - 二进制文件: $(pwd)/bin/ppanel-server"
    ls -lh bin/ppanel-server
    echo ""
    echo "部署包位置:"
    echo "  - $(pwd)/deploy/ppanel-server.tar.gz"
    ls -lh deploy/ppanel-server.tar.gz
    echo ""
    echo "下一步:"
    echo "  1. 上传 deploy/ppanel-server.tar.gz 到服务器"
    echo "  2. 解压: tar -xzf ppanel-server.tar.gz -C /opt"
    echo "  3. 配置: nano /opt/ppanel-server/etc/ppanel.yaml"
    echo "  4. 启动: cd /opt/ppanel-server && ./start.sh"
    echo ""
}

# 运行
main
