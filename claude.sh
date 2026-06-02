#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CALLER_DIR="${CALLER_DIR:-$(pwd -W 2>/dev/null || pwd)}"
cd "$SCRIPT_DIR"

# 检查 Bun
if ! command -v bun &>/dev/null; then
    echo "[ERROR] 未找到 Bun，请先安装: curl -fsSL https://bun.sh/install | bash"
    exit 1
fi

# 检查 .env
if [ ! -f ".env" ]; then
    echo "[ERROR] 未找到 .env 文件，请复制 .env.example 为 .env 并填写 API Key"
    exit 1
fi

# 检查 API Key 是否已填写（检测 your_ 占位符）
if grep -q "your_" .env 2>/dev/null; then
    echo "[WARN] 检测到 .env 中仍有占位符 \"your_\"，请先填写真实的 API Key"
    exit 1
fi

echo "[INFO] 启动 Claude Code Haha..."
exec bun run ./bin/claude-haha "$@"
