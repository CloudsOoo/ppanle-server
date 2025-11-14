#!/bin/bash

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "  PPanel Server GitHub Release 发布"
echo "========================================"
echo ""

# 获取版本号（从 git tag 或输入）
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LATEST_TAG" ]; then
    SUGGESTED_VERSION="v1.0.0"
else
    SUGGESTED_VERSION=$LATEST_TAG
fi

echo -e "${YELLOW}当前最新 tag: ${LATEST_TAG:-无}${NC}"
echo "建议版本号: $SUGGESTED_VERSION"
echo ""
read -p "请输入版本号 (例如 v1.0.0): " VERSION

if [ -z "$VERSION" ]; then
    echo "错误: 版本号不能为空"
    exit 1
fi

# 确认版本号格式
if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
    echo "警告: 版本号格式不标准 (建议格式: vX.Y.Z)"
    read -p "是否继续? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        exit 1
    fi
fi

# 创建 release 目录
RELEASE_DIR="release-$VERSION"
rm -rf $RELEASE_DIR
mkdir -p $RELEASE_DIR

echo ""
echo -e "${GREEN}1. 准备发布文件...${NC}"

# 复制部署包
cp deploy/ppanel-server.tar.gz $RELEASE_DIR/ppanel-server-$VERSION.tar.gz

# 生成 SHA256 校验文件
cd $RELEASE_DIR
sha256sum ppanel-server-$VERSION.tar.gz > ppanel-server-$VERSION.tar.gz.sha256
cd ..

echo "   ✓ 部署包: ppanel-server-$VERSION.tar.gz"
echo "   ✓ 校验文件: ppanel-server-$VERSION.tar.gz.sha256"

# 生成 Release Notes
echo ""
echo -e "${GREEN}2. 生成 Release Notes...${NC}"

cat > $RELEASE_DIR/RELEASE_NOTES.md << EOF
# PPanel Server $VERSION

## 🎉 新增功能

### UPayPro 加密货币支付集成
- ✅ 支持 USDT/USDC 多链支付（TRC20, ERC20, Polygon, BSC, ArbitrumOne）
- ✅ 完整的支付回调处理和签名验证
- ✅ 与现有支付系统无缝集成
- ✅ 支持 10+ 种加密货币支付类型

### 构建和部署工具
- ✅ 一键编译脚本 (quick-build.sh)
- ✅ 部署包生成工具 (create-deploy-package.sh)
- ✅ HTTP 下载服务器脚本
- ✅ 完整的部署文档

## 📦 下载

\`\`\`bash
# 下载部署包
wget https://github.com/CloudsOoo/ppanle-server/releases/download/$VERSION/ppanel-server-$VERSION.tar.gz

# 验证文件完整性
wget https://github.com/CloudsOoo/ppanle-server/releases/download/$VERSION/ppanel-server-$VERSION.tar.gz.sha256
sha256sum -c ppanel-server-$VERSION.tar.gz.sha256
\`\`\`

## 🚀 快速部署

\`\`\`bash
# 1. 解压
tar -xzf ppanel-server-$VERSION.tar.gz -C /opt

# 2. 配置
nano /opt/ppanel-server/etc/ppanel.yaml

# 3. 启动
cd /opt/ppanel-server
./start.sh
\`\`\`

## 📋 完整部署指南

查看项目中的 [DOWNLOAD.md](https://github.com/CloudsOoo/ppanle-server/blob/main/DOWNLOAD.md) 获取详细的下载和部署说明。

## 🔧 配置 UPayPro 支付

在管理后台添加支付方式时配置：
- **base_url**: UPayPro 应用地址
- **secret_key**: 系统密钥
- **type**: 支付类型（如 USDT-TRC20）

支持的支付类型：
- USDT: TRC20, ERC20, Polygon, BSC, ArbitrumOne
- USDC: ERC20, Polygon, BSC, ArbitrumOne
- TRX

## 📊 文件信息

- **文件名**: ppanel-server-$VERSION.tar.gz
- **大小**: $(ls -lh deploy/ppanel-server.tar.gz | awk '{print $5}')
- **SHA256**: \`$(sha256sum deploy/ppanel-server.tar.gz | awk '{print $1}')\`

## 🔗 相关链接

- [项目主页](https://github.com/CloudsOoo/ppanle-server)
- [下载指南](https://github.com/CloudsOoo/ppanle-server/blob/main/DOWNLOAD.md)
- [问题反馈](https://github.com/CloudsOoo/ppanle-server/issues)

## 📝 变更日志

查看完整的提交历史：
\`\`\`bash
git log --oneline
\`\`\`

---

**完整的部署包包含：**
- ✅ 编译好的二进制文件
- ✅ 配置文件模板
- ✅ 启动/停止脚本
- ✅ systemd 服务文件
- ✅ 安装说明文档
EOF

echo "   ✓ Release Notes 已生成"

# 创建 Git tag
echo ""
echo -e "${GREEN}3. 创建 Git Tag...${NC}"

if git tag -l | grep -q "^$VERSION\$"; then
    echo -e "${YELLOW}   警告: Tag $VERSION 已存在${NC}"
    read -p "   是否删除并重新创建? (y/n): " RECREATE
    if [ "$RECREATE" = "y" ]; then
        git tag -d $VERSION
        git push origin :refs/tags/$VERSION 2>/dev/null || true
    else
        echo "   跳过创建 tag"
    fi
fi

if ! git tag -l | grep -q "^$VERSION\$"; then
    git tag -a $VERSION -m "Release $VERSION - UPayPro Integration"
    echo "   ✓ Tag $VERSION 已创建"
fi

# 推送 tag
echo ""
echo -e "${GREEN}4. 推送 Tag 到 GitHub...${NC}"
read -p "   是否推送 tag 到远程? (y/n): " PUSH_TAG
if [ "$PUSH_TAG" = "y" ]; then
    git push origin $VERSION
    echo "   ✓ Tag 已推送"
fi

# 生成上传说明
echo ""
echo "========================================"
echo -e "${GREEN}✓ Release 准备完成！${NC}"
echo "========================================"
echo ""
echo "📁 Release 文件位置: $RELEASE_DIR/"
ls -lh $RELEASE_DIR/
echo ""
echo "========================================"
echo "下一步操作："
echo "========================================"
echo ""
echo "方式 1: 使用 GitHub Web 界面（推荐）"
echo "----------------------------------------"
echo "1. 访问: https://github.com/CloudsOoo/ppanle-server/releases/new"
echo "2. 选择 tag: $VERSION"
echo "3. 标题: PPanel Server $VERSION"
echo "4. 描述: 复制 $RELEASE_DIR/RELEASE_NOTES.md 的内容"
echo "5. 上传文件:"
echo "   - $RELEASE_DIR/ppanel-server-$VERSION.tar.gz"
echo "   - $RELEASE_DIR/ppanel-server-$VERSION.tar.gz.sha256"
echo "6. 点击 'Publish release'"
echo ""
echo "方式 2: 使用 GitHub CLI (如果已安装)"
echo "----------------------------------------"
echo "gh release create $VERSION \\"
echo "  $RELEASE_DIR/ppanel-server-$VERSION.tar.gz \\"
echo "  $RELEASE_DIR/ppanel-server-$VERSION.tar.gz.sha256 \\"
echo "  --title 'PPanel Server $VERSION' \\"
echo "  --notes-file $RELEASE_DIR/RELEASE_NOTES.md"
echo ""
echo "========================================"
echo ""

# 显示 Release Notes 预览
echo "📝 Release Notes 预览："
echo "========================================"
head -30 $RELEASE_DIR/RELEASE_NOTES.md
echo "..."
echo ""
