# Claude Code Haha (cc-haha) — 手动安装指南

> 适用平台：Windows / macOS / Linux  
> 运行环境：[Bun](https://bun.sh) (>=1.x)  
> 项目地址：`E:\AI_Agent_Tool\cc-haha`

---

## 目录

1. [安装 Bun 运行时](#1-安装-bun-运行时)
2. [拉取项目 & 安装依赖](#2-拉取项目--安装依赖)
3. [配置 API Key 与环境变量](#3-配置-api-key-与环境变量)
4. [一键启动脚本](#4-一键启动脚本)
5. [全局使用（任意目录启动）](#5-全局使用任意目录启动)
6. [多提供商切换示例](#6-多提供商切换示例)
7. [常见问题排查](#7-常见问题排查)

---

## 1. 安装 Bun 运行时

### Windows

```powershell
# PowerShell（推荐）
powershell -c "irm bun.sh/install.ps1 | iex"
```

安装后**重新打开终端**，验证：

```bash
bun --version
# 应输出: 1.x.x
```

### macOS / Linux

```bash
curl -fsSL https://bun.sh/install | bash
```

验证：

```bash
bun --version
```

> 如果提示 `command not found`，手动添加到 PATH：
> ```bash
> export PATH="$HOME/.bun/bin:$PATH"
> ```

---

## 2. 拉取项目 & 安装依赖

```bash
# 进入项目目录
cd E:\AI_Agent_Tool\cc-haha

# 安装依赖（只需执行一次）
bun install
```

> 如遇网络问题，可设置镜像：
> ```bash
# bun 镜像（阿里云）
export BUN_CONFIG_REGISTRY=https://registry.npmmirror.com
# 或使用 npm 镜像
bun install --registry https://registry.npmmirror.com
> ```

---

## 3. 配置 API Key 与环境变量

### 3.1 快速配置（推荐新手）

直接从示例模板创建 `.env` 文件：

```bash
cp .env.example .env
```

### 3.2 各提供商配置参考

打开 `.env` 文件，**取消注释**你要使用的提供商配置段，填入你的 API Key：

---

#### 方案 A：MiniMax（直连，国内可用）

```bash
ANTHROPIC_AUTH_TOKEN=your_minimax_api_key_here
ANTHROPIC_BASE_URL=https://api.minimaxi.com/anthropic
ANTHROPIC_MODEL=MiniMax-M2.7
ANTHROPIC_DEFAULT_SONNET_MODEL=MiniMax-M2.7
ANTHROPIC_DEFAULT_HAIKU_MODEL=MiniMax-M2.7-highspeed
ANTHROPIC_DEFAULT_OPUS_MODEL=MiniMax-M2.7
API_TIMEOUT_MS=3000000
```

- 海外用户将 `minimaxi.com` 换成 `minimax.io`
- 获取 Key：https://platform.minimaxi.com

---

#### 方案 B：OpenRouter（直连）

```bash
ANTHROPIC_AUTH_TOKEN=sk-or-v1-xxxxxx
ANTHROPIC_BASE_URL=https://openrouter.ai/api/v1
ANTHROPIC_MODEL=openai/gpt-4o
ANTHROPIC_DEFAULT_SONNET_MODEL=openai/gpt-4o
ANTHROPIC_DEFAULT_HAIKU_MODEL=openai/gpt-4o-mini
ANTHROPIC_DEFAULT_OPUS_MODEL=openai/gpt-4o
```

---

#### 方案 C：LiteLLM 代理（接入 OpenAI / DeepSeek 等）

先安装并启动 LiteLLM：

```bash
pip install litellm
litellm --config litellm_config.yaml --port 4000
```

然后 `.env` 配置：

```bash
ANTHROPIC_AUTH_TOKEN=sk-anything
ANTHROPIC_BASE_URL=http://localhost:4000
ANTHROPIC_MODEL=gpt-4o
ANTHROPIC_DEFAULT_SONNET_MODEL=gpt-4o
ANTHROPIC_DEFAULT_HAIKU_MODEL=gpt-4o
ANTHROPIC_DEFAULT_OPUS_MODEL=gpt-4o
API_TIMEOUT_MS=3000000
```

> 模型名改为 `deepseek-chat` 即可切换到 DeepSeek。

---

#### 通用设置（建议始终启用）

```bash
DISABLE_TELEMETRY=1
CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

### 3.3 环境变量参考

| 变量 | 必填 | 说明 |
|------|:--:|------|
| `ANTHROPIC_AUTH_TOKEN` | 是 | API Key，Bearer Token 认证 |
| `ANTHROPIC_BASE_URL` | 否 | 自定义 API 端点 |
| `ANTHROPIC_MODEL` | 否 | 默认模型名 |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | 否 | Sonnet 级别模型 |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | 否 | Haiku 级别模型 |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | 否 | Opus 级别模型 |
| `API_TIMEOUT_MS` | 否 | 超时毫秒，默认 600000 |
| `DISABLE_TELEMETRY` | 否 | 设为 `1` 禁用遥测 |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | 否 | 设为 `1` 禁用非必要网络 |

---

## 4. 一键启动脚本

### 4.1 Windows 一键脚本（`start.bat`）

在项目根目录 `E:\AI_Agent_Tool\cc-haha\` 下创建 `start.bat`：

```bat
@echo off
cd /d "%~dp0"

REM 检查 Bun 是否安装
where bun >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 未找到 Bun，请先安装: https://bun.sh
    pause
    exit /b 1
)

REM 检查 .env 是否存在
if not exist ".env" (
    echo [ERROR] 未找到 .env 文件，请先执行: cp .env.example .env 并填写 API Key
    pause
    exit /b 1
)

echo [INFO] 启动 Claude Code Haha...
bun run ./bin/claude-haha %*
```

双击 `start.bat` 即可启动。

---

### 4.2 macOS / Linux 一键脚本（`start.sh`）

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 检查 Bun
if ! command -v bun &>/dev/null; then
    echo "[ERROR] 未找到 Bun，请先安装: curl -fsSL https://bun.sh/install | bash"
    exit 1
fi

# 检查 .env
if [ ! -f ".env" ]; then
    echo "[ERROR] 未找到 .env 文件，请先执行: cp .env.example .env 并填写 API Key"
    exit 1
fi

echo "[INFO] 启动 Claude Code Haha..."
exec bun run ./bin/claude-haha "$@"
```

赋予执行权限并运行：

```bash
chmod +x start.sh
./start.sh
```

---

### 4.3 直达 CLI（最简单）

如果已配置好 `.env`，直接运行：

```bash
# 方式 1：用 bun run
bun run start

# 方式 2：直接执行 bin 脚本
./bin/claude-haha

# 方式 3：带参数启动
./bin/claude-haha --model MiniMax-M2.7    # 指定模型
./bin/claude-haha --no-computer-use        # 禁用桌面控制
./bin/claude-haha --help                   # 查看所有参数
```

---

## 5. 全局使用（任意目录启动）

### macOS / Linux

在 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
# 方式一：PATH（推荐）
export PATH="$HOME/path/to/cc-haha/bin:$PATH"

# 方式二：alias
alias claude-haha="$HOME/path/to/cc-haha/bin/claude-haha"
```

```bash
source ~/.bashrc   # 或 source ~/.zshrc
```

### Windows (Git Bash)

在 `~/.bashrc` 中添加：

```bash
export PATH="/e/AI_Agent_Tool/cc-haha/bin:$PATH"
```

### 验证

```bash
cd ~/任意项目目录
claude-haha
# 应自动识别当前目录为工作目录
```

---

## 6. 多提供商切换示例

`.env` 文件中可以准备好多个提供商的配置，**取消注释**你要用的那一套即可：

```bash
# ============================================================
# 当前激活：MiniMax（国内）
# ============================================================
ANTHROPIC_AUTH_TOKEN=your_minimax_api_key_here
ANTHROPIC_BASE_URL=https://api.minimaxi.com/anthropic
ANTHROPIC_MODEL=MiniMax-M2.7

# ============================================================
# 备用 1：OpenRouter（注释掉不用）
# ============================================================
# ANTHROPIC_AUTH_TOKEN=sk-or-v1-xxx
# ANTHROPIC_BASE_URL=https://openrouter.ai/api/v1
# ANTHROPIC_MODEL=openai/gpt-4o

# ============================================================
# 备用 2：本地 LiteLLM（注释掉不用）
# ============================================================
# ANTHROPIC_AUTH_TOKEN=sk-anything
# ANTHROPIC_BASE_URL=http://localhost:4000
# ANTHROPIC_MODEL=gpt-4o

DISABLE_TELEMETRY=1
CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

---

## 7. 常见问题排查

| 问题 | 原因 | 解决 |
|------|------|------|
| `bun: command not found` | Bun 未安装或未加入 PATH | 重新打开终端，或手动 `export PATH="$HOME/.bun/bin:$PATH"` |
| 启动报 `API key missing` | `.env` 未配置 | 执行 `cp .env.example .env` 后编辑填入 Key |
| 连接超时 | 国内访问海外 API | 换用 MiniMax 国内域名 `minimaxi.com` 或配置代理 |
| `EACCES: permission denied` | 脚本无执行权限 | `chmod +x bin/claude-haha` |
| 模型返回 404 | 模型名不正确 | 确认 `ANTHROPIC_MODEL` 与提供商支持的模型名一致 |
| 桌面端安装问题 | macOS Gatekeeper | 参考 `docs/desktop/04-installation.md` |
```

---

> **文档站点**: https://claudecode-haha.relakkesyang.org  
> **GitHub**: https://github.com/NanmiCoder/cc-haha  
> **环境变量参考**: `docs/guide/env-vars.md`  
> **全局使用**: `docs/guide/global-usage.md`
