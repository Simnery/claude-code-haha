# 02_03 — 市面定制化 Agent 商用方案调研

> 调研当前主流的编码 Agent 产品，分析各自的架构组成和商业定位。

---

## 一、方案总览对比

| 产品 | 公司 | 形态 | 开源 | 核心特色 |
|------|------|------|------|---------|
| **Claude Code** | Anthropic | CLI + Desktop | 否(源码泄露) | MCP 协议、强推理、TUI 体验 |
| **Devin** | Cognition | Web IDE | 否 | 全自主、"AI 软件工程师"、PR 级输出 |
| **Cursor** | Cursor Inc | IDE (fork VS Code) | 部分 | AI-first IDE、多文件编辑、Composer |
| **GitHub Copilot** | Microsoft | IDE 插件 + Agent Mode | 否 | 生态最大、Workspace 级上下文 |
| **Cline** | 开源社区 | VS Code 插件 | 是 | 开源可自部署、支持多种模型、MCP |
| **Codex CLI** | OpenAI | CLI | 是 | 轻量 CLI Agent、OpenAI 官方 |
| **Aider** | 开源社区 | CLI | 是 | 最早的开源编码 Agent 之一、Git 集成深 |
| **Windsurf** | Codeium | IDE (fork VS Code) | 否 | Flow 模式、多文件感知 |
| **Continue** | 开源社区 | IDE 插件 | 是 | 可插拔模型、企业级 |

---

## 二、逐个详解

### 2.1 Claude Code (Anthropic)

```
架构组成:
  CLI 入口 (cli.tsx)
  → Agent 核心循环 (query.ts while+yield)
  → 工具系统 (40+ 内置工具 + MCP 扩展)
  → 权限系统 (4 级权限模式)
  → 记忆系统 (MEMORY.md)
  → TUI 界面 (Ink + React)

关键特点:
  - MCP 协议: 标准化工具接入，社区贡献工具越来越多
  - 强推理: Claude 4.x 系列的推理能力 + thinking 模式
  - 权限模型: 从完全自主到只读，四级可控
  - 无 IDE 依赖: 纯 CLI，任何终端都能跑
```

### 2.2 Devin (Cognition)

```
架构组成:
  Web IDE (浏览器内)
  → 任务规划器 (Planner)
  → 代码编辑器 (内建 IDE)
  → Shell 终端 (沙箱环境)
  → Browser 浏览器 (用于查文档、测试 Web 应用)
  → Git 集成 (自动 commit + PR)

关键特点:
  - 最接近"AI 员工": 给它一个 issue，它给你一个 PR
  - 沙箱环境: 每个任务独立容器
  - 多 Agent 协作: 主 Agent 调度子 Agent
  - 全自主: 无权限询问，直接干
```

### 2.3 Cursor (Cursor Inc)

```
架构组成:
  VS Code fork → 深度定制的 IDE
  → Composer (Agent 模式编辑器)
  → Tab (行级补全)
  → Chat (侧边栏对话)
  → Agent (多文件自动编辑)
  → Context (自动选取相关文件作为上下文)

关键特点:
  - AI-first IDE: 不是插件，是替换了整个编辑器
  - Composer 模式: 同时编辑多个文件
  - 上下文感知: 自动选取相关代码文件
  - 多种模型可选: GPT-4o / Claude 4.x / Gemini
```

### 2.4 GitHub Copilot (Microsoft)

```
架构组成:
  IDE 插件 (VS Code / JetBrains)
  → 代码补全 (行级)
  → Chat (侧边栏)
  → Agent Mode (多文件编辑 + 终端)
  → Workspace (项目级上下文)
  → Code Review (PR 审查)

关键特点:
  - 用户量最大: 依托 GitHub 生态
  - Agent Mode: 2024.10 发布，从补全升级为 Agent
  - Workspace 感知: 不只是当前文件，理解整个项目
  - Copilot Extensions: 第三方工具接入
```

### 2.5 Cline (开源社区)

```
架构组成:
  VS Code 插件
  → Agent 循环 (类 Claude Code 的 while 模式)
  → 工具系统 (文件 + 终端 + 浏览器)
  → MCP 支持 (可扩展工具)
  → 支持多种模型 API (OpenAI / Anthropic / 本地)

关键特点:
  - 完全开源，Apache 2.0
  - 可自部署，不依赖特定模型提供商
  - MCP 协议支持
  - 轻量: 一个 VS Code 插件就搞定
```

### 2.6 Codex CLI (OpenAI)

```
架构组成:
  CLI 工具 (npm install -g @openai/codex)
  → Agent 循环
  → 工具系统 (文件 + Shell + 网络)
  → OpenAI 模型 (GPT-4o / o3 / o4-mini)
  → 沙箱执行 (可选 Docker)

关键特点:
  - 官方开源 (Apache 2.0)
  - 轻量极简: 核心逻辑不到 2000 行
  - 多种执行模式: 本地 / Docker 沙箱
  - 和 Claude Code 最接近的竞品
```

---

## 三、架构模式分类

### 按产品形态

| 形态 | 代表产品 | 优势 | 劣势 |
|------|---------|------|------|
| **CLI** | Claude Code, Codex CLI, Aider | 灵活、可脚本化、不依赖 IDE | 学习曲线、无图形化 |
| **IDE 插件** | Copilot, Cline, Continue | 无缝融入工作流 | 受 IDE 限制 |
| **定制 IDE** | Cursor, Windsurf | 深度定制、体验最好 | 需要切换编辑器 |
| **Web 平台** | Devin | 零安装、沙箱安全 | 网络延迟、不够本地化 |

### 按自主程度

| 自主度 | 代表产品 | 适用场景 |
|--------|---------|---------|
| **全手动** (Coding Assistant) | Copilot 补全 | 写代码时提示下一行 |
| **半自动** (默认权限) | Claude Code, Cursor | 开发时 AI 辅助，人审核 |
| **全自动** (bypass/plan mode off) | Devin, Claude Code bypass | 分配任务后完全不管 |

---

## 四、各方案的共同组成

把以上方案拆开，会发现它们都包含这些模块：

```
┌─────────────────────────────────────────┐
│              用户界面                     │
│  CLI / IDE 插件 / Web / 定制 IDE         │
├─────────────────────────────────────────┤
│           Agent 核心循环                  │
│  感知 → 规划 → 行动 → 观察 → 循环        │
├─────────────────────────────────────────┤
│              工具系统                     │
│  文件读写 / Shell / 网络 / Git / LSP     │
├─────────────────────────────────────────┤
│              上下文管理                   │
│  项目文件 / 对话历史 / 压缩 / 记忆        │
├─────────────────────────────────────────┤
│              模型层                       │
│  模型选择 / API 调用 / 流式处理 / 重试   │
├─────────────────────────────────────────┤
│              安全与权限                   │
│  沙箱 / 权限模式 / 审批流 / 审计日志     │
└─────────────────────────────────────────┘
```

差异主要在：
- **模型层**: 各家用不同模型（自家或第三方）
- **工具接入方式**: MCP 标准 vs 各家私有协议
- **上下文策略**: 压缩策略不同
- **产品形态**: CLI vs IDE vs Web
