# 01_02 — Agent 主循环

> 覆盖文件：`src/query.ts`, `src/QueryEngine.ts`, `src/replLauncher.tsx`, `src/screens/REPL.tsx`, `src/components/App.tsx`, `src/query/*.ts`

---

## 一、两条路径概览

```
用户输入
  ├─ REPL 路径 (交互式 TUI)
  │    └─ replLauncher.tsx → App.tsx → REPL.tsx
  │         └─ 内部调用 query() → Agent 循环
  │
  └─ SDK/无头路径 ( -p 模式 / 外部调用 )
       └─ QueryEngine.submitMessage()
            └─ 内部调用 query() → Agent 循环
```

两条路径最终都收敛到 `src/query.ts` 中的 `query()` 异步生成器。

---

## 二、QueryEngine (`src/QueryEngine.ts`)

### 职责
SDK/无头模式的 **会话级管理者**，一个 QueryEngine 实例 = 一个完整的对话。

### 核心类结构 (L186-209)
```typescript
class QueryEngine {
  private config: QueryEngineConfig
  private mutableMessages: Message[]         // 对话历史
  private abortController: AbortController
  private permissionDenials: SDKPermissionDenial[]
  private totalUsage: NonNullableUsage       // 累计 token usage
  private readFileState: FileStateCache
}
```

### 构造函数接收
- `tools`, `commands`, `mcpClients`, `agents` → 可用工具/命令
- `canUseTool` → 权限检查回调
- `getAppState/setAppState` → 状态管理
- `initialMessages` → 初始/恢复消息
- `customSystemPrompt/appendSystemPrompt` → 自定义 prompt
- `userSpecifiedModel/fallbackModel` → 模型配置
- `thinkingConfig` → 思考模式
- `maxTurns/maxBudgetUsd/taskBudget` → 预算限制
- `jsonSchema` → 结构化输出 schema

### 主入口 `submitMessage()` (L211)
- **输入**: 用户文本 或 ContentBlock 数组
- **输出**: `AsyncGenerator<SDKMessage>` (流式消息)
- 每次调用 = 一个 turn
- 内部调用 `fetchSystemPromptParts()` → 构建 system prompt
- 调用 memory/autoMem 路径注入记忆
- 最终调用 `query()` 进入 Agent 循环

---

## 三、核心 Agent 循环 (`src/query.ts`)

### 整体架构

```
query() → queryLoop()
  └─ while(true)  // 无限循环，按条件退出
       ├─ 1. memory prefetch          (并行预取记忆)
       ├─ 2. skill discovery prefetch (技能发现)
       ├─ 3. tool result budget       (工具结果大小限制)
       ├─ 4. snip compaction          (过期消息裁剪)
       ├─ 5. microcompact             (缓存编辑)
       ├─ 6. context collapse         (上下文折叠)
       ├─ 7. autocompact              (自动压缩)
       ├─ 8. token blocking check     (硬限制检查)
       ├─ 9. API 调用 (streaming)     (调用模型)
       │    └─ yield 每个 streaming event
       ├─ 10. 后处理
       │    ├─ max_output_tokens 恢复
       │    ├─ reactive compact (响应式压缩)
       │    ├─ fallback 重试
       │    └─ stop hooks
       ├─ 11. 工具执行
       │    ├─ runTools() → 工具编排
       │    ├─ StreamingToolExecutor → 流式工具执行
       │    └─ yield 每个 tool_result
       └─ 12. 判断退出
            ├─ 无 tool_use → return terminal
            ├─ 达到 maxTurns → return
            └─ 否则 → continue (下一步迭代)
```

### 循环状态 (`State` 类型, L206-219)

| 字段 | 说明 |
|------|------|
| `messages` | 当前对话消息列表 |
| `toolUseContext` | 工具上下文 (权限/选项/abort) |
| `autoCompactTracking` | 自动压缩追踪 |
| `maxOutputTokensRecoveryCount` | 输出超限恢复计数 |
| `hasAttemptedReactiveCompact` | 是否尝试过响应式压缩 |
| `turnCount` | 当前 turn 计数 |
| `stopHookActive` | stop hook 是否激活 |
| `transition` | 上一轮迭代原因 (Continue) |

### 退出条件
- **normal**: 最后一条 assistant 消息无 tool_use → `{ reason: 'finished' }`
- **interrupted**: 用户中断 → `{ reason: 'interrupted' }`
- **max_turns**: 达到最大轮数 → `{ reason: 'max_turns' }`
- **blocking_limit**: token 超限 → `{ reason: 'blocking_limit' }`
- **budget_exceeded**: 预算超出 → `{ reason: 'budget_exceeded' }`

---

## 四、API 调用阶段 (L657-700)

### 调用参数
```typescript
deps.callModel({
  messages: prependUserContext(messagesForQuery, userContext),
  systemPrompt: fullSystemPrompt,
  thinkingConfig,        // adaptive / enabled / disabled
  tools,                 // 可用工具列表
  signal: abortController.signal,
  options: {
    model: currentModel,            // 当前模型
    fastMode,                        // 快速模式
    fallbackModel,                   // 回退模型
    maxOutputTokensOverride,         // 最大输出 token
    querySource,                     // 查询来源
    agents,                          // Agent 定义
    mcpTools,                        // MCP 工具
    effortValue,                     // effort 值
    advisorModel,                    // advisor 模型
    skipCacheWrite,                  // 跳过缓存写入
  }
})
```

### 流式接收
```typescript
for await (const message of deps.callModel({...})) {
  // message 可以是:
  //   - StreamEvent (增量文本)
  //   - AssistantMessage (完整回复)
  //   - tool_use blocks
  yield message
}
```

---

## 五、工具执行阶段

### 流程
```
assistant 消息 (含 tool_use blocks)
  → runTools() / StreamingToolExecutor
    → 对每个 tool_use:
        ├─ canUseTool() 权限检查
        ├─ tool.execute() 实际执行
        ├─ yield tool_result
        └─ post-sampling hooks
  → 结果作为 user message 注入
  → 继续 while(true) 下一轮迭代
```

### StreamingToolExecutor (`src/services/tools/StreamingToolExecutor.ts`)
- 支持流式工具输出
- 在模型还在生成时就开始执行部分工具
- 提升端到端延迟

---

## 六、压缩系统 (Compaction)

### 四层压缩，按优先级执行

| 序号 | 类型 | 文件 | 作用 |
|------|------|------|------|
| 1 | Snip | `snipCompact.ts` | 裁剪过期消息，释放内存 |
| 2 | Microcompact | `microcompact` | 缓存编辑，清除冗余 tool results |
| 3 | Context Collapse | `contextCollapse/` | 折叠对话段落为摘要 |
| 4 | Autocompact | `compact.ts` | 完整上下文压缩 + 摘要生成 |

每次迭代都先检查并执行这四层，确保上下文不超限。

---

## 七、REPL 交互层 (`src/replLauncher.tsx`)

### 启动流程
```
launchRepl(root, appProps, replProps, renderAndRun)
  → 动态 import App.tsx
  → 动态 import REPL.tsx
  → Ink 渲染: <App><REPL /></App>
```

### App.tsx
- 全局状态 Provider (AppState via React Context)
- 管理 FPS 监控、Stats、主题等

### REPL.tsx
- 用户输入处理 (Ink TextInput)
- 消息列表渲染 (ScrollBox)
- 权限对话框 (PermissionDialog)
- 模型切换 (/model 命令)
- 会话管理 (恢复/新建)

### 消息流 (REPL 内)
```
用户输入 (TextInput)
  → processUserInput()
    → query()
      → yield streaming events → 实时渲染
      → yield tool_use → 渲染工具状态
      → yield tool_result → 更新工具结果
  → 最终 assistant message → 渲染完整回复
```

---

## 八、查询配置 (`src/query/config.ts`)

`buildQueryConfig()` 在 queryLoop 入口调用一次，快照环境变量和 feature flags：

- `gates.isAnt` → 内部用户
- `gates.fastModeEnabled` → 快速模式
- `gates.streamingToolExecution` → 流式工具执行
- `sessionId` → 当前会话 ID

---

## 九、依赖注入 (`src/query/deps.ts`)

`productionDeps()` 提供可替换的依赖：

| 依赖 | 说明 |
|------|------|
| `callModel` | 实际调用 LLM API |
| `autocompact` | 自动压缩 |
| `microcompact` | 微压缩 |
| `uuid` | UUID 生成 |

便于测试时 mock。

---

## 十、关键数据流总结

```
用户输入
  ↓
processUserInput → 解析命令 / 添加附件 / 构建消息
  ↓
query() → queryLoop()
  ├── 压缩 (snip → micro → collapse → auto)
  ├── API 调用 (streaming events → 实时渲染)
  ├── 后处理 (max_tokens 恢复 / reactive compact / stop hooks)
  ├── 工具执行 (权限 → execute → hook)
  └── 循环判断 (tool_use? → continue : done)
  ↓
返回 Terminal 状态
```
