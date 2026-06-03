# 02_12 — 多 Agent 协作模式

> 单个 Agent 能解决的任务有限。多个 Agent 如何分工协作？各有什么模式？

---

## 一、为什么需要多 Agent？

### 单个 Agent 的天花板

```
1. 上下文窗口有限 — 一个 Agent 装不下整个大型项目
2. 注意力分散 — 同时做前后端 + 测试 + 部署，容易出错
3. 权限冲突 — 有些操作需要特定权限，混在一起不安全
4. 单点瓶颈 — 一个 Agent 做所有事，慢
```

### 多 Agent 的价值

```
用户: "实现用户认证系统"

单 Agent:  一个人做全部 (慢 + 容易出错)
多 Agent:
  ├─ DB Agent:    设计 users/sessions 表
  ├─ Backend Agent: 写 POST /login API + JWT 中间件
  ├─ Frontend Agent: 写 LoginForm 组件
  └─ Test Agent:   写集成测试
  → 同时进行 + 各司其职 + 最后合并
```

---

## 二、五种协作模式

### 2.1 顺序流水线 (Sequential Pipeline)

```
Agent A → Agent B → Agent C → 最终结果

适用: 有明确先后依赖的任务
例:  设计 schema → 写后端 → 写前端
```

```typescript
// 伪代码
const schema = await dbAgent.design(requirement)
const api = await backendAgent.implement(schema)
const ui = await frontendAgent.build(api.spec)
```

### 2.2 并行协作 (Parallel)

```
          ┌─ Agent A →
用户请求 ─┼─ Agent B → 合并 → 最终结果
          └─ Agent C →

适用: 互不依赖的子任务
例:   前端组件 + 后端 API + 测试 同时进行
```

```typescript
const [api, ui, tests] = await Promise.all([
  backendAgent.implement(req),
  frontendAgent.build(req),
  testAgent.writeTests(req),
])
```

### 2.3 编排者模式 (Orchestrator)

```
              用户
               │
         ┌─────▼─────┐
         │ Orchestrator│ ← 中央调度者
         └──┬──┬──┬──┘
            │  │  │
        ┌───▼──▼──▼───┐
        │  Worker Agents│
        └──────────────┘

适用: 复杂任务，需要动态分配
例:  大型项目重构
```

```typescript
// Orchestrator 的逻辑
class Orchestrator {
  async execute(task: ComplexTask) {
    // 1. 分解任务
    const subtasks = await this.planner.decompose(task)

    // 2. 分配给最合适的 Agent
    const assignments = subtasks.map(st => ({
      subtask: st,
      agent: this.selectBestAgent(st),  // 按技能匹配
    }))

    // 3. 调度执行（有依赖的串行，无依赖的并行）
    const results = await this.scheduler.run(assignments)

    // 4. 合并结果
    return this.merger.combine(results)
  }
}
```

### 2.4 辩论/评审模式 (Debate/Review)

```
Agent A (提案) → 产出方案
  ↓
Agent B (评审) → 审查方案，提出修改意见
  ↓
Agent A → 根据意见修改
  ↓
Agent B → 再次评审
  ↓ (直到达成一致)
最终方案
```

```typescript
// Claude Code 的 /review 命令就是这个模式
const code = await coderAgent.write(requirement)
const review = await reviewerAgent.review(code)

while (review.hasIssues) {
  code = await coderAgent.fix(code, review.issues)
  review = await reviewerAgent.review(code)
}
```

### 2.5 层级委托 (Hierarchical)

```
            Lead Agent
           /    |    \
      Sub-Agent Sub-Agent Sub-Agent
        │           │
     Sub-Agent  Sub-Agent

适用: 大型组织式开发团队
例:  项目经理 Agent → 技术负责人 Agent → 开发 Agent
```

---

## 三、多 Agent 通信方式

| 方式 | 说明 | 适用 |
|------|------|------|
| **共享上下文** | 所有 Agent 读写同一个消息列表 | 进程内子 Agent |
| **消息传递** | Agent 之间发送结构化消息 | A2A 协议 |
| **共享文件** | 通过文件系统交换中间产物 | 编码 Agent 最常见 |
| **共享记忆** | 通过 MEMORY.md 或 DB 交换知识 | 跨会话协作 |
| **事件总线** | Agent 发布/订阅事件 | 松耦合协作 |

### 本项目 (Claude Code) 的实现

```
主 Agent (REPL 进程)
  └─ AgentTool.spawn()
       ├─ 创建子进程 (独立 Bun 进程)
       ├─ 复制必要上下文 (System Prompt + 工具 + 文件状态)
       ├─ 子 Agent 独立执行
       ├─ 完成后返回 summary 给主 Agent
       └─ Worktree 隔离文件操作

优点: 简单、隔离好
局限: 进程开销大、不能跨机器
```

---

## 四、多 Agent 的工程挑战

| 挑战 | 说明 | 解决方向 |
|------|------|---------|
| **上下文传递** | 子 Agent 需要知道多少父 Agent 的上下文？ | 摘要压缩 + 按需传递 |
| **结果合并** | 多个 Agent 改了同一个文件怎么办？ | Git merge + 冲突解决 Agent |
| **任务分配** | 谁来决定哪个 Agent 做什么？ | 基于技能的自动匹配 |
| **错误传播** | 子 Agent 失败会影响全局吗？ | 隔离 + 重试 + 降级 |
| **成本控制** | 多 Agent 并行 = 多倍 API 调用成本 | 小任务用小模型 |
| **死锁/循环** | 两个 Agent 互相等待 | 超时机制 + 编排者仲裁 |

---

## 五、框架选型

| 框架 | 模式 | 语言 | 特点 |
|------|------|------|------|
| **CrewAI** | 角色扮演式编排 | Python | 最简单的多 Agent 框架 |
| **AutoGen** | 对话式多 Agent | Python | 微软出品 |
| **LangGraph** | 状态机式编排 | Python/TS | 灵活，可自定义 |
| **OpenAI Swarm** | 轻量 Agent 切换 | Python | 实验性，OpenAI 出品 |
| **Agno** | 高性能多 Agent | Python | 新兴，速度快 |
| **本项目 AgentTool** | 进程内子 Agent | TS | 内置，简单 |

### 选型建议

```
刚开始学多 Agent → CrewAI (5 行代码跑起来)
需要灵活编排 → LangGraph (状态机)
已有的 Agent 系统加协作 → A2A 协议
追求性能 → Agno
```
