# 02_04 — Agent 通用架构模型

> 抽象出独立于具体产品的通用 Agent 架构，作为自建 Agent 的蓝图。

---

## 一、六层通用架构

```
┌──────────────────────────────────────────────────────┐
│  Layer 6: 用户界面 (UI Layer)                         │
│  CLI · IDE插件 · Web · API · Chat Interface          │
├──────────────────────────────────────────────────────┤
│  Layer 5: Agent 编排 (Orchestration)                  │
│  任务规划 · 工作流 · 多Agent调度 · 状态机            │
├──────────────────────────────────────────────────────┤
│  Layer 4: Agent 核心循环 (Core Loop)                  │
│  while(未完成): 推理→行动→观察→判断                   │
├──────────────────────────────────────────────────────┤
│  Layer 3: 能力模块 (Capabilities)                     │
│  工具执行 · 记忆检索 · 知识库(RAG) · 代码执行        │
├──────────────────────────────────────────────────────┤
│  Layer 2: 模型接入 (Model Gateway)                    │
│  模型路由 · API调用 · 流式处理 · 重试/降级           │
├──────────────────────────────────────────────────────┤
│  Layer 1: 基础设施 (Infrastructure)                   │
│  会话存储 · 事件总线 · 日志/遥测 · 认证/安全         │
└──────────────────────────────────────────────────────┘
```

---

## 二、各层详解

### Layer 1: 基础设施

| 组件 | 作用 | 技术选型 |
|------|------|---------|
| 会话存储 | 持久化对话历史和状态 | SQLite / JSONL / PostgreSQL |
| 事件总线 | Agent 各模块间通信 | EventEmitter / RxJS / Message Queue |
| 日志/遥测 | 调试、监控、成本分析 | OpenTelemetry / Pino / 自研 |
| 认证/安全 | API Key 管理、沙箱隔离 | OAuth / API Key / Docker |

### Layer 2: 模型接入

```
模型网关 (Model Gateway)
  ├─ 统一接口: 屏蔽不同提供商的 API 差异
  ├─ 模型路由: 根据任务复杂度选模型
  ├─ 流式处理: SSE → AsyncGenerator
  ├─ 重试/降级: 主模型挂了切备用
  └─ Token 计数: 上下文预算管理
```

支持多 Provider 是必备能力：

```typescript
interface ModelProvider {
  name: string
  baseURL: string
  apiKey: string
  models: ModelInfo[]
  chat(params: ChatParams): AsyncGenerator<StreamEvent>
}

// OpenAI / Anthropic / DeepSeek / 本地模型 统一接口
```

### Layer 3: 能力模块

#### 3.1 工具系统

```typescript
interface Tool {
  name: string
  description: string          // 给模型看的，帮助它判断什么时候用
  parameters: JSONSchema       // 参数约束
  execute(input, context): Promise<ToolResult>
  requiresApproval?: boolean   // 是否需要用户确认
  isDangerous?: boolean        // 是否高危（标记给权限系统）
}
```

工具分类：
- **读操作**: ReadFile, Grep, Glob, ListDir, SQL Select
- **写操作**: WriteFile, EditFile, Bash, SQL Insert
- **网络**: HTTP Request, WebFetch, API Call
- **外部服务**: Slack, Jira, GitHub API

#### 3.2 记忆系统

```
工作记忆 (Working Memory)
  = 当前对话历史 + System Prompt + 工具结果
  → 受上下文窗口限制，需要压缩策略

短期记忆 (Short-term Memory)
  = 当前会话的所有消息
  → JSONL 存储，可恢复

长期记忆 (Long-term Memory)
  = 跨会话持久化的结构化信息
  → 实现方式:
    A) 文件存储 (MEMORY.md 模式，简单直观)
    B) 向量数据库 (Embedding + 语义搜索，适合大量记忆)
    C) 知识图谱 (结构化关系查询)
```

#### 3.3 知识库 (RAG)

```
用户问题
  ↓
Embedding 检索 → 从知识库找相关文档
  ↓
文档片段 + 原问题 → 注入 System Prompt
  ↓
模型回答（基于检索到的知识）
```

### Layer 4: Agent 核心循环

```typescript
// 通用 Agent Loop 伪代码
async function* agentLoop(goal: string): AsyncGenerator<AgentEvent> {
  const messages = [buildSystemPrompt(), userMessage(goal)]

  while (true) {
    // 1. 上下文管理
    messages = manageContext(messages)    // 压缩/裁剪
    messages = injectMemory(messages)     // 注入长期记忆
    messages = injectRAG(messages)        // 注入相关知识

    // 2. 调用模型
    const response = await callModel(messages, tools)

    // 3. 解析响应
    if (response.isText) {
      yield { type: 'text', content: response.text }
    }

    // 4. 工具执行
    for (const toolCall of response.toolCalls) {
      yield { type: 'tool_start', ...toolCall }

      // 权限检查
      if (toolCall.requiresApproval) {
        const decision = await askUser(toolCall)
        if (decision === 'deny') continue
      }

      // 执行
      const result = await executeTool(toolCall)
      yield { type: 'tool_result', ...result }

      // 结果注入
      messages.push(toolResultMessage(result))
    }

    // 5. 终止判断
    if (response.stopReason === 'end_turn') break
    if (turnCount > maxTurns) break
  }
}
```

### Layer 5: Agent 编排

#### 单任务编排（简单场景）

```
Goal → Planner分解 → Step1 → Step2 → Step3 → Done
```

#### 多 Agent 编排（复杂场景）

```
用户: "实现完整的用户登录系统"

编排者 Agent:
  ├─ 分配 Agent A: 后端 API (POST /login, JWT)
  ├─ 分配 Agent B: 前端表单 (React Login component)
  ├─ 分配 Agent C: 数据库 (users table migration)
  └─ 分配 Agent D: 测试 (integration tests)

编排模式:
  - 顺序: A → B → C → D
  - 并行: A, B, C 同时进行，D 最后
  - 管道: A的输出 → B的输入 → C的输入
```

#### 状态机式编排

```
        ┌─────────┐
        │  IDLE   │ ← 初始状态
        └────┬────┘
             │ 收到用户输入
        ┌────▼────┐
        │ PLANNING│ → 分解任务
        └────┬────┘
             │
        ┌────▼────┐
    ┌───│EXECUTING│───┐
    │   └────┬────┘   │
    │        │tool_use│
    │   ┌────▼────┐   │
    │   │AWAITING │   │ 等待权限审批
    │   └────┬────┘   │
    │        │approved│
    │   ┌────▼────┐   │
    └───│ RUNNING │───┘ 执行工具
        └────┬────┘
             │ 无更多 tool_use
        ┌────▼────┐
        │  DONE   │
        └─────────┘
```

### Layer 6: 用户界面

| 界面类型 | 适用场景 | 技术栈 |
|---------|---------|--------|
| CLI | 开发者工具、自动化 | Node.js + Ink / Python + Rich |
| IDE 插件 | 编码 Agent | VS Code Extension API |
| Web UI | 通用、非技术人员 | React / Next.js |
| API | 被其他系统调用 | REST / WebSocket / gRPC |
| Chat 界面 | 对话式 Agent | React Chat UI / Slack Bot |

---

## 三、几个关键的通用模块

### 3.1 System Prompt 管理

```typescript
// System Prompt 不是写死的，而是动态拼装的
function buildSystemPrompt(context) {
  return [
    BASE_PROMPT,           // 基础角色定义
    TOOL_PROMPTS,          // 工具说明
    MEMORY_PROMPTS,        // 记忆内容
    RAG_CONTEXT,           // 检索到的知识
    RULES,                 // 项目规则 (.claude/ 或 .cursor/ 下的配置)
    DATE_CONTEXT,          // 当前日期/环境信息
  ].join('\n')
}
```

### 3.2 上下文窗口管理

```
上下文窗口 = 模型能处理的最大 token 数

管理策略:
  1. 精确计数: 用 tiktoken 等库计算实际 token 数
  2. 预留空间: 给模型输出留 buffer (通常 20-30%)
  3. 分层裁剪:
     - 最新消息 → 保留
     - 工具结果 → 压缩或删除
     - 早期对话 → 总结后删除
  4. 自动压缩: 接近上限时触发
```

### 3.3 错误处理与恢复

```typescript
// Agent 执行流程中的多层错误处理
try {
  // Level 1: API 调用错误
  const response = await callModelWithRetry(params, { maxRetries: 3 })

  // Level 2: 工具执行错误
  for (const toolCall of response.toolCalls) {
    try {
      const result = await executeTool(toolCall)
    } catch (e) {
      // 工具失败 → 以错误消息形式还给模型，让它自己修正
      messages.push(toolError(toolCall.id, e.message))
    }
  }
} catch (e) {
  // Level 3: 致命错误 → 终止或降级
  if (isFatal(e)) throw e
  // 非致命 → 告诉模型重试
  messages.push(systemMessage(`出错了: ${e.message}. 请用另一种方式重试。`))
}
```
