#!/bin/bash
# AIChatPro 项目构建脚本
#
# 功能：
# 1. 自动下载仓颉 SDK 和 STDX 扩展库（如果尚未安装）
# 2. 配置 cjpm.toml 中的 STDX 路径
# 3. 编译项目
#
# 使用方式：
#   chmod +x setup.sh
#   ./setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_DIR="${HOME}/.cache/cangjie-doc-validator"
SDK_DIR="${CACHE_DIR}/cangjie"
STDX_DIR="${CACHE_DIR}/cangjie-stdx"

SDK_URL="https://github.com/SunriseSummer/CangjieSDK/releases/download/1.0.5/cangjie-sdk-linux-x64-1.0.5.tar.gz"
STDX_URL="https://github.com/SunriseSummer/CangjieSDK/releases/download/1.0.5/cangjie-stdx-linux-x64-1.0.5.1.zip"

echo "==============================="
echo "  AIChatPro 项目构建脚本"
echo "==============================="

# 1. 下载并安装 SDK
if [ ! -d "${SDK_DIR}/cangjie" ]; then
    echo "[1/3] 下载仓颉 SDK..."
    mkdir -p "${SDK_DIR}"
    local sdk_tmp
    sdk_tmp="$(mktemp /tmp/cangjie-sdk-XXXXXX.tar.gz)"
    wget -q "${SDK_URL}" -O "${sdk_tmp}"
    tar xzf "${sdk_tmp}" -C "${SDK_DIR}"
    rm -f "${sdk_tmp}"
    echo "  ✅ SDK 安装完成"
else
    echo "[1/3] SDK 已安装，跳过"
fi

# 加载 SDK 环境
source "${SDK_DIR}/cangjie/envsetup.sh"

# 2. 下载并安装 STDX
STDX_STATIC="${STDX_DIR}/linux_x86_64_cjnative/static/stdx"
if [ ! -d "${STDX_STATIC}" ]; then
    echo "[2/3] 下载 STDX 扩展库..."
    mkdir -p "${STDX_DIR}"
    local stdx_tmp
    stdx_tmp="$(mktemp /tmp/cangjie-stdx-XXXXXX.zip)"
    wget -q "${STDX_URL}" -O "${stdx_tmp}"
    unzip -o -q "${stdx_tmp}" -d "${STDX_DIR}"
    rm -f "${stdx_tmp}"
    echo "  ✅ STDX 安装完成"
else
    echo "[2/3] STDX 已安装，跳过"
fi

# 3. 配置并构建项目
echo "[3/3] 配置并构建项目..."
cd "${SCRIPT_DIR}"

# 生成 cjpm.toml（用实际 STDX 路径替换模板）
cat > cjpm.toml << EOF
[package]
  cjc-version = "1.0.5"
  name = "aichat"
  version = "1.0.0"
  output-type = "executable"

[dependencies]

[target.x86_64-unknown-linux-gnu.bin-dependencies]
  path-option = ["${STDX_STATIC}"]
EOF

cjpm build
echo "  ✅ 项目构建成功"

echo ""
echo "==============================="
echo "  构建完成！"
echo "==============================="
echo ""
echo "运行方式："
echo "  source ${SDK_DIR}/cangjie/envsetup.sh"
echo "  export KIMI_API_KEY=\"你的 Kimi API Key\""
echo "  cd ${SCRIPT_DIR}"
echo "  cjpm run"
echo ""
echo "模拟测试（无需真实 API Key）："
echo "  python3 test_aichat.py"
