# 02_02 — Claude Code 的 Agent 模式剖析

> 基于 cc-haha 源码分析，提取 Claude Code 作为 Agent 的核心设计模式。

---

## 一、Claude Code 是什么？

从 Agent 视角看，Claude Code 是一个**代码领域的专业 Agent**：

```
用户: "帮我在 src/utils 下新建一个 logger.ts"

Claude Code (Agent):
  1. 理解需求 → 需要创建 TypeScript 日志模块
  2. 规划 → 创建文件、写内容、验证语法
  3. 执行:
     - Write(src/utils/logger.ts, 内容)
     - Bash(bun run check) → 验证
  4. 报告结果
```

---

## 二、Claude Code 的 Agent 架构

### 2.1 四层架构

```
┌─────────────────────────────────────────────┐
│            用户界面层 (UI Layer)              │
│  REPL.tsx  ·  Ink TUI  ·  输入框  ·  渲染器   │
├─────────────────────────────────────────────┤
│            Agent 核心层 (Core Loop)          │
│  query.ts (while true + yield)               │
│  QueryEngine.ts (SDK/无头模式)               │
├─────────────────────────────────────────────┤
│            能力层 (Capabilities)             │
│  ┌──────────┐ ┌──────────┐ ┌─────────────┐ │
│  │ 工具系统  │ │ 命令系统  │ │ 权限系统     │ │
│  │ 40+ 工具  │ │ 40+ 命令  │ │ canUseTool  │ │
│  └──────────┘ └──────────┘ └─────────────┘ │
├─────────────────────────────────────────────┤
│            基础设施层 (Infrastructure)        │
│  API客户端  ·  MCP协议  ·  会话存储  ·  遥测  │
└─────────────────────────────────────────────┘
```

### 2.2 核心 Agent 循环

```
while (任务未完成) {
  // Step 1: 上下文准备
  ├─ 加载系统提示词 (system prompt)
  ├─ 注入工具列表 + 使用说明
  ├─ 注入 CLAUDE.md / MEMORY.md
  └─ 压缩历史消息 (如需要)

  // Step 2: 调用模型
  ├─ 组装 messages + system + tools
  ├─ 发送到 API
  └─ 流式接收回复 (streaming)

  // Step 3: 解析模型回复
  ├─ 普通文本 → 直接展示
  └─ tool_use 块 → 进入 Step 4

  // Step 4: 执行工具
  ├─ 权限检查 (canUseTool)
  ├─ 执行工具 (tool.execute)
  ├─ 结果注入对话历史
  └─ 回到 Step 1
}
```

### 2.3 关键设计：Generator 模式

Claude Code 用 `async function*` 实现流式 Agent 循环：

```typescript
async function* query(params): AsyncGenerator<Message> {
  while (true) {
    // 压缩检查
    if (needCompact) { /* ... */ yield compactMsg }

    // API 调用 — 逐 token 产出
    for await (const event of callModel(...)) {
      yield event  // 实时渲染
    }

    // 工具调用 — 逐个执行
    for (const toolUse of assistantMessage.toolUses) {
      yield toolUse
      const result = await executeTool(toolUse)
      yield result
    }

    // 判断退出
    if (!hasToolUse) return { reason: 'finished' }
  }
}
```

---

## 三、Claude Code 的独有设计

### 3.1 System Prompt 工程

Claude Code 的 system prompt 是整个 Agent 行为的"宪法"：

- 工具使用说明（每个工具怎么用、什么时候用）
- 行为约束（不要修改工作区以外的文件、prefer Edit over Write）
- 代码风格偏好（不引入无意义的抽象、不过度工程化）
- 安全规则（不执行危险命令、敏感信息脱敏）

### 3.2 工具权限模型

```
每个工具调用 → canUseTool(tool, input, context)
  ├─ bypass 模式       → 直接允许
  ├─ plan 模式         → 拒绝修改类工具
  ├─ 已保存的规则      → 按规则判断
  ├─ isReadOnly 工具   → 自动允许
  └─ 其余              → 弹出对话框询问用户
```

### 3.3 上下文压缩

```
四层压缩，每轮循环按需触发：

Snip → 裁剪过期工具结果
  ↓
Microcompact → 缓存编辑，清除冗余内容
  ↓
Context Collapse → 折叠对话段落为摘要
  ↓
Autocompact → 完整压缩 + 摘要生成（最重）
```

### 3.4 内存系统

```
MEMORY.md (跨会话持久化):
  - user:     用户偏好/知识背景
  - project:  项目状态/决策
  - feedback: 用户反馈/纠正
  - reference: 外部资源链接

加载时机: 每次对话开始时注入 system prompt
更新时机: Agent 判断有必要记录时主动写入
```

### 3.5 多 Agent 模型

```
主 Agent (REPL)
  └─ AgentTool → fork 子 Agent
       ├─ 独立上下文窗口
       ├─ 独立工具权限
       ├─ 独立工作目录 (worktree)
       └─ 返回摘要给主 Agent
```

---

## 四、从 Claude Code 学到什么？

### 可复用的模式

| 模式 | 实现方式 | 适用场景 |
|------|---------|---------|
| Agent Loop | while + Generator | 任何需要多轮交互的 Agent |
| 工具抽象 | `interface Tool { name, schema, execute }` | 统一工具接口 |
| 权限层 | 独立于工具执行的 canUseTool | 安全敏感场景 |
| 上下文管理 | 多层压缩策略 | 长任务场景 |
| 记忆系统 | 结构化 MARKDOWN 文件 | 跨会话持久化 |
| 流式输出 | AsyncGenerator + yield | 实时反馈体验 |

### 可以改进的地方

| 问题 | Claude Code 的做法 | 替代思路 |
|------|-------------------|---------|
| 单线程 Agent Loop | while(true) 串行 | 考虑并行工具执行 (Promise.all) |
| 压缩不可逆 | 压缩后历史消息丢失 | 分数式压缩 + 保留关键原文 |
| 权限粒度粗 | 工具级权限 | 参数级权限（如只允许读特定目录） |
| 记忆被动 | 只记录 Agent 认为重要的 | 主动提取 + 向量检索 |
