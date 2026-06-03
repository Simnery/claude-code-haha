# 02_05 — 脱离平台自建 Agent 的技术栈与框架选型

> 如果不基于 Claude Code 平台，从零开发一个定制化 Agent，该用什么技术？

---

## 一、技术选型决策树

```
你的需求是什么?
  ├─ 编码 Agent (类似 Claude Code)
  │   ├─ 要 TUI → Bun/Node + Ink + Anthropic SDK
  │   ├─ 要 IDE 插件 → VS Code Extension API
  │   └─ 要 Web → Next.js + Monaco Editor
  │
  ├─ 通用 Agent (不限领域)
  │   ├─ 快速原型 → Python + LangChain / CrewAI
  │   ├─ 生产级 → TypeScript + 自研框架
  │   └─ 低代码 → Dify / Coze / Flowise
  │
  └─ 企业 Agent (内部工具)
      ├─ 简单工作流 → n8n / Temporal
      └─ 复杂编排 → 自研 + MCP + A2A
```

---

## 二、编程语言选型

| 语言 | 优势 | 劣势 | 适合 |
|------|------|------|------|
| **TypeScript** | 前后端统一、类型安全、Web 生态好 | 异步模型学习曲线 | Web Agent、IDE 插件 |
| **Python** | AI 生态最全、库最多、上手快 | 类型系统弱、并发模型复杂 | 快速原型、数据处理 Agent |
| **Go** | 性能好、部署简单(单二进制) | AI 库较少 | 高性能 Agent 服务 |
| **Rust** | 极致性能、内存安全 | 开发效率低、AI 生态弱 | Agent 底层引擎 |

**推荐**: 起步用 TypeScript（和本项目技术栈一致），原型验证后再考虑其他语言。

---

## 三、Agent 框架对比

### 3.1 轻量级（推荐先看）

| 框架 | 语言 | 特点 | 适用 |
|------|------|------|------|
| **Vercel AI SDK** | TS | 流式 Agent、多 Provider、工具定义简洁 | Web + Node Agent |
| **OpenAI Agents SDK** | Python | OpenAI 官方、轻量 | OpenAI 生态 |
| **Anthropic Claude API** | TS/Python | 原生 Tool Use、MCP 支持 | 编码 Agent |
| **Mastra** | TS | 新兴框架、类似 Vercel AI SDK 但更专注 Agent | 通用 Agent |

### 3.2 重量级框架

| 框架 | 语言 | 特点 | 适用 |
|------|------|------|------|
| **LangChain** | Python/TS | 生态最大、组件最多 | 复杂 RAG + Agent 系统 |
| **LangGraph** | Python/TS | 状态机式 Agent 编排 | 多步推理 Agent |
| **CrewAI** | Python | 多 Agent 协作框架 | 角色扮演式 Agent Team |
| **AutoGen** | Python | 微软出品、对话式多 Agent | 多 Agent 对话系统 |
| **Semantic Kernel** | C#/Python/Java | 微软出品、企业级 | .NET 企业用户 |

### 3.3 低代码/可视化

| 工具 | 特点 | 适用 |
|------|------|------|
| **Dify** | 开源、可视化编排、RAG 内置 | 快速搭建内部 Agent |
| **Coze** | 字节出品、多平台发布（飞书/微信） | 对话机器人 |
| **Flowise** | 开源、节点拖拽、LangChain 底层 | 可视化 RAG |
| **n8n** | 开源工作流自动化 | 自动化 Agent 工作流 |

---

## 四、组件级技术选型

### 4.1 模型接入

| 方案 | 说明 |
|------|------|
| **直连 API** | OpenAI / Anthropic / DeepSeek 官方 SDK，最简单 |
| **LiteLLM Proxy** | 统一代理，一套接口调所有模型（本项目用的方案） |
| **OpenRouter** | 第三方聚合 API，按量付费，免去管理多个 Key |

### 4.2 工具系统

| 方案 | 说明 |
|------|------|
| **MCP 协议** | 标准化工具接入，社区生态快速增长 |
| **自研 Tool Interface** | 简单场景直接用代码定义 |
| **Function Calling** | OpenAI/Anthropic 原生支持 |

### 4.3 向量数据库（RAG 场景）

| 方案 | 类型 | 适用 |
|------|------|------|
| **Chroma** | 嵌入式 | 原型/小规模 |
| **Qdrant** | 独立服务 | 生产级 |
| **Pinecone** | 云服务 | 不想自运维 |
| **pgvector** | PostgreSQL 扩展 | 已有 PG 的项目 |

### 4.4 记忆系统

| 方案 | 说明 |
|------|------|
| **文件存储** (类似 MEMORY.md) | 最简单，适合个人 Agent |
| **SQLite + Embedding** | 结构化 + 语义检索 |
| **Mem0 / Letta** | 专业 Agent 记忆框架 |

### 4.5 执行环境

| 方案 | 说明 |
|------|------|
| **本地执行** | 直接在当前环境跑（简单但风险大） |
| **Docker 沙箱** | 隔离执行环境，安全 |
| **E2B / Code Interpreter** | 云端沙箱，开箱即用 |

---

## 五、推荐技术栈组合

### 场景 A: 个人编码 Agent（类似 Claude Code 简化版）

```
运行时:    Bun / Node.js
语言:      TypeScript
模型:      Anthropic API / OpenRouter
框架:      Vercel AI SDK (或自研 while + Generator)
工具系统:  MCP 协议
界面:      CLI (Ink) 或 VS Code 插件
存储:      JSONL (会话) + Markdown (记忆)
```

### 场景 B: 企业内部 Agent 平台

```
运行时:    Node.js / Python
语言:      TypeScript (前端 + BFF) / Python (Agent 引擎)
模型:      LiteLLM Proxy (统一接入)
框架:      LangGraph (复杂编排) + 自研 Tool 层
工具系统:  MCP 协议 + REST API
界面:      Web (Next.js + React)
存储:      PostgreSQL + pgvector
安全:      Docker 沙箱 + OAuth + 审计日志
```

### 场景 C: 快速原型验证

```
运行时:    Python
框架:      CrewAI / OpenAI Agents SDK
模型:      OpenAI API
工具:      Function Calling
界面:      Streamlit / Gradio (最快出 GUI)
存储:      SQLite
```

---

## 六、选型核心原则

1. **先跑通最小闭环，再加复杂度**: 模型 → 工具 → 记忆 → UI，一步步来
2. **模型无关**: 不要绑死一个模型提供商，用抽象层隔离
3. **MCP 优先**: 工具接入走 MCP 标准，生态兼容性好
4. **安全第一**: 如果你永远不需要考虑安全问题，说明你的 Agent 还不够有用
5. **TypeScript 长期看**: 全栈统一、类型安全，AI SDK 生态在快速追赶 Python
