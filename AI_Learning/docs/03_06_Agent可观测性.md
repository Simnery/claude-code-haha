# 03_06 — Agent 可观测性

> Agent 变得越自主，就越需要能"看到内部"。

---

## 一、什么是 Agent 可观测性？

传统程序：加断点 → 看变量 → 找到 bug。
Agent：需要看到 **每一步决策** 的上下文。

### 三个支柱

| 支柱 | 回答什么问题 | 数据来源 |
|------|-------------|---------|
| **日志 (Logging)** | 发生了什么？ | Agent 执行记录 |
| **指标 (Metrics)** | 整体情况如何？ | 聚合统计 |
| **追踪 (Tracing)** | 这个请求走了什么路径？ | 每次调用的完整链路 |

---

## 二、Agent 需要记录什么？

### 2.1 每个 Turn 的关键事件

```typescript
// Agent 执行日志
interface AgentLog {
  sessionId: string
  turnNumber: number
  timestamp: number
  
  // 输入
  userMessage: string
  systemPromptHash: string  // 哪版 Prompt
  
  // 模型调用
  modelCall: {
    model: string
    inputTokens: number
    outputTokens: number
    durationMs: number
    cost: number
  }
  
  // 工具调用
  toolCalls: Array<{
    toolName: string
    toolInput: Record<string, unknown>
    toolResult: string
    durationMs: number
    approved: boolean        // 是否通过权限检查
  }>
  
  // 结果
  response: string
  stopReason: "end_turn" | "max_tokens" | "interrupted" | "error"
}
```

### 2.2 关键指标

```typescript
// Agent Metrics Dashboard 指标
const metrics = {
  // 成功率
  taskCompletionRate: 0.85,     // 85% 的任务完成
  toolSuccessRate: 0.92,        // 92% 的工具调用成功
  
  // 性能
  avgTimeToFirstToken: 1200,    // 首 token 延迟 (ms)
  avgTaskDuration: 45000,       // 任务平均耗时 (ms)
  
  // 成本
  totalCost: 123.45,            // 总费用 (USD)
  avgCostPerTask: 0.15,         // 每任务平均费用
  
  // 安全
  toolApprovalRate: 0.35,       // 35% 的工具调用需要用户确认
  deniedToolCalls: 12,          // 被拒绝的工具调用数
  
  // 质量
  avgUserRating: 4.2,           // 用户平均评分
  retryRate: 0.08,              // 8% 的任务需要重试
}
```

---

## 三、工具选型

### 3.1 通用可观测性平台

| 工具 | 类型 | 适用 |
|------|------|------|
| **LangSmith** | 商业 | LangChain 生态首选，一站式 Agent 追踪 |
| **Arize Phoenix** | 开源 | LLM 专用可观测性 |
| **LangFuse** | 开源 | LLM 追踪 + 评估 + Prompt 管理 |
| **Weights & Biases** | 商业 | 模型训练 + Agent 追踪 |
| **OpenTelemetry** | 开源标准 | 通用（本项目 claude code 用的就是这个）|

### 3.2 专项工具

| 工具 | 用途 |
|------|------|
| **Helicone** | API 级别监控 + 成本追踪 |
| **Braintrust** | Prompt 实验 + 评估 |
| **Datadog LLM Observability** | 企业级全栈监控 |

---

## 四、最小化可观测性实现

### 4.1 结构化日志

```typescript
// agent-logger.ts — 最简实现
import fs from 'fs'

interface LogEntry {
  timestamp: string
  level: 'info' | 'warn' | 'error'
  event: string
  data: Record<string, unknown>
}

class AgentLogger {
  private stream: fs.WriteStream
  
  constructor(path: string) {
    this.stream = fs.createWriteStream(path, { flags: 'a' })
  }
  
  log(entry: Omit<LogEntry, 'timestamp'>) {
    const record = { timestamp: new Date().toISOString(), ...entry }
    this.stream.write(JSON.stringify(record) + '\n')
  }
}

// 使用
logger.log({
  level: 'info',
  event: 'tool_executed',
  data: { toolName: 'Read', path: 'src/main.ts', durationMs: 45 }
})
```

### 4.2 成本追踪

```typescript
// 追踪每次 API 调用的 token 和费用
class CostTracker {
  private totalCost = 0
  private usageByModel: Record<string, { tokens: number; cost: number }> = {}
  
  recordUsage(model: string, inputTokens: number, outputTokens: number) {
    const cost = this.calculateCost(model, inputTokens, outputTokens)
    this.totalCost += cost
    
    if (!this.usageByModel[model]) {
      this.usageByModel[model] = { tokens: 0, cost: 0 }
    }
    this.usageByModel[model].tokens += inputTokens + outputTokens
    this.usageByModel[model].cost += cost
  }
  
  calculateCost(model: string, inputTokens: number, outputTokens: number): number {
    // 各模型定价
    const pricing: Record<string, { input: number; output: number }> = {
      'claude-sonnet-4-6': { input: 3/1_000_000, output: 15/1_000_000 },
      'gpt-4o': { input: 2.5/1_000_000, output: 10/1_000_000 },
    }
    const p = pricing[model] ?? { input: 0, output: 0 }
    return inputTokens * p.input + outputTokens * p.output
  }
  
  getReport() {
    console.log(`总费用: $${this.totalCost.toFixed(4)}`)
    for (const [model, usage] of Object.entries(this.usageByModel)) {
      console.log(`  ${model}: ${usage.tokens} tokens, $${usage.cost.toFixed(4)}`)
    }
  }
}
```

### 4.3 Agent 决策追踪

```typescript
// 记录 Agent 每一步决策，方便回溯
interface TraceSpan {
  name: string
  startTime: number
  endTime?: number
  input?: unknown
  output?: unknown
  error?: string
  children: TraceSpan[]
}

class AgentTracer {
  private spans: TraceSpan[] = []
  private currentSpan: TraceSpan | null = null
  
  startSpan(name: string, input?: unknown) {
    const span: TraceSpan = {
      name, startTime: Date.now(), input, children: []
    }
    if (this.currentSpan) {
      this.currentSpan.children.push(span)
    } else {
      this.spans.push(span)
    }
    this.currentSpan = span
    return span
  }
  
  endSpan(output?: unknown, error?: string) {
    if (this.currentSpan) {
      this.currentSpan.endTime = Date.now()
      this.currentSpan.output = output
      this.currentSpan.error = error
      // 回到父 span (简化处理)
    }
  }
  
  getTrace(): TraceSpan[] {
    return this.spans
  }
}

// 使用示例
const tracer = new AgentTracer()

tracer.startSpan('agent_turn', { prompt: '创建 utils/logger.ts' })
  tracer.startSpan('model_call')
  tracer.endSpan({ tokens: 500 })
  
  tracer.startSpan('tool_execute', { tool: 'Write' })
  tracer.endSpan({ result: 'success' })
tracer.endSpan({ status: 'completed' })
```

---

## 五、告警规则

```yaml
# 生产环境建议配置的告警
alerts:
  - name: 成本异常
    condition: cost_per_day > $50  # 日常费用突然翻倍
    action: 通知开发者 + 自动限制并发

  - name: 错误率飙升
    condition: error_rate > 10%
    action: 通知开发者 + 检查模型 API 状态

  - name: 任务卡死
    condition: task_duration > 5min  # 单任务超过5分钟
    action: 自动中断 + 通知用户

  - name: 危险命令检测
    condition: tool_call matches dangerous_pattern
    action: 立即拦截 + 告警通知
```
