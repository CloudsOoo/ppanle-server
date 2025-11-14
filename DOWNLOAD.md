# PPanel Server 部署包下载指南

## 文件信息
- **文件路径**: `/home/user/ppanle-server/deploy/ppanel-server.tar.gz`
- **文件大小**: 16MB
- **包含内容**: 完整的 PPanel Server 部署包

---

## 📥 下载方法

### 方法 1: 使用 1Panel 文件管理（推荐）✅

1. 登录 1Panel 面板
2. 进入 **文件** → **文件管理**
3. 导航到目录: `/home/user/ppanle-server/deploy/`
4. 找到文件: `ppanel-server.tar.gz`
5. 点击文件后的 **下载** 按钮

---

### 方法 2: 使用 SCP 命令下载

**在你的本地电脑上执行：**

```bash
# 下载到当前目录
scp root@your-server-ip:/home/user/ppanle-server/deploy/ppanel-server.tar.gz ./

# 或下载到指定目录
scp root@your-server-ip:/home/user/ppanle-server/deploy/ppanel-server.tar.gz ~/Downloads/
```

---

### 方法 3: 如果在同一台服务器上部署

**直接解压使用，无需下载：**

```bash
# 直接解压到 /opt
tar -xzf /home/user/ppanle-server/deploy/ppanel-server.tar.gz -C /opt

# 进入目录
cd /opt/ppanel-server

# 配置
nano etc/ppanel.yaml

# 启动
./start.sh
```

---

### 方法 4: 使用 SFTP 客户端

**推荐工具：**
- Windows: WinSCP, FileZilla
- Mac: Cyberduck, FileZilla
- Linux: FileZilla

**连接信息：**
- 主机: 你的服务器 IP
- 端口: 22
- 用户名: root
- 协议: SFTP
- 文件路径: `/home/user/ppanle-server/deploy/ppanel-server.tar.gz`

---

### 方法 5: 复制到其他服务器

**从当前服务器复制到其他服务器：**

```bash
scp /home/user/ppanle-server/deploy/ppanel-server.tar.gz root@target-server:/tmp/
```

---

## 🔧 部署步骤

下载后按照以下步骤部署：

```bash
# 1. 解压
tar -xzf ppanel-server.tar.gz -C /opt

# 2. 配置（必须！）
nano /opt/ppanel-server/etc/ppanel.yaml
# 配置数据库、Redis 等

# 3. 启动
cd /opt/ppanel-server
./start.sh

# 4. 查看日志
tail -f logs/ppanel.log
```

---

## 📋 配置示例

编辑 `/opt/ppanel-server/etc/ppanel.yaml`:

```yaml
# 数据库配置
Database:
  Host: localhost
  Port: 3306
  Username: root
  Password: your_password
  Database: ppanel

# Redis 配置
Redis:
  Host: localhost
  Port: 6379
  Password: ""

# 服务器配置
Server:
  Host: your-domain.com
  Port: 8080
```

---

## ❓ 常见问题

**Q: 文件在哪里？**
A: `/home/user/ppanle-server/deploy/ppanel-server.tar.gz`

**Q: 如何验证文件完整性？**
A: 执行 `ls -lh /home/user/ppanle-server/deploy/ppanel-server.tar.gz`
   应该显示大小约为 16MB

**Q: 下载后如何验证？**
A: 执行 `tar -tzf ppanel-server.tar.gz | head` 查看内容

---

需要帮助？查看 INSTALL.txt 或联系技术支持。
