# 02_01 — Agent 概念与背景

> 本文回答：什么是 AI Agent？它和普通程序/聊天机器人有什么区别？经历了怎样的发展？

---

## 一、什么是 AI Agent？

### 一句话定义

> AI Agent（智能体）是一个能**自主感知环境、做出决策、执行行动**来完成目标的 AI 系统。

### 和三个容易混淆的概念对比

| | 传统程序 | 聊天机器人 (Chatbot) | AI Agent |
|---|---|---|---|
| **输入** | 确定的参数 | 自然语言 | 自然语言 + 环境信息 |
| **输出** | 确定的结果 | 文本回复 | 文本 + 实际行动 (改文件/调API/发请求) |
| **决策方式** | 写死的 if/else | 模型推理 → 文本 | 模型推理 → 行动计划 → 执行 |
| **工具使用** | 调固定函数 | 不支持 | 动态选择工具并执行 |
| **记忆** | 变量/数据库 | 短窗口对话 | 长期记忆 + 工作记忆 |
| **自主性** | 零（按代码走） | 低（一问一答） | 高（多步规划、自我纠错） |
| **典型例子** | `ls`, `grep` | ChatGPT 对话 | Claude Code、Cursor、Devin |

### Agent 的本质公式

```
Agent = LLM (大脑) + Planning (规划) + Tools (手脚) + Memory (记忆)
```

---

## 二、Agent 的核心能力

### 2.1 推理与规划 (Reasoning & Planning)

将用户的模糊目标分解为可执行的步骤序列。

```
用户: "帮我把这个 Python 项目改成 TypeScript"

Agent 内部规划:
  1. 读取项目结构 (tool: Glob)
  2. 逐文件翻译 .py → .ts (tool: Write/Edit)
  3. 安装依赖 (tool: Bash: npm install)
  4. 运行测试 (tool: Bash: npm test)
  5. 修复类型错误 (tool: Edit)
  6. 报告完成
```

关键能力：
- **任务分解**：复杂目标 → 可执行子任务
- **依赖性排序**：哪些先做，哪些可以并行
- **失败恢复**：某步失败后调整计划

### 2.2 工具使用 (Tool Use)

Agent 必须能**操作外部世界**，光会说话没用。

| 工具类型 | 示例 |
|---------|------|
| 文件系统 | 读/写/编辑文件 |
| Shell/终端 | 执行命令、运行脚本 |
| 网络 | API 调用、网页抓取 |
| 数据库 | SQL 查询、数据迁移 |
| 浏览器 | 点击、填表单、截图 |
| Git | commit、push、branch |
| 其他服务 | Slack 发消息、Jira 建 ticket |

### 2.3 记忆系统 (Memory)

| 记忆类型 | 作用 | 类比 |
|---------|------|------|
| **工作记忆** | 当前对话的上下文窗口 | 人脑的"正在想的事" |
| **短期记忆** | 当前会话的历史记录 | "今天都聊了什么" |
| **长期记忆** | 跨会话持久化的知识 | 笔记、MEMORY.md |

关键挑战：
- 上下文窗口有限 → 需要压缩/总结机制
- 跨会话一致性 → 记忆检索和更新策略

### 2.4 自我纠错 (Self-Correction)

Agent 必须能发现自己犯错并修正：

```
1. 执行工具 → 结果不符合预期
2. 分析错误原因
3. 调整策略 → 换工具/换参数/问用户
4. 重新执行
```

---

## 三、Agent 的分类

### 按自主程度

| 级别 | 名称 | 说明 | 例子 |
|------|------|------|------|
| L1 | 辅助型 | 人类做决策，AI 提建议 | ChatGPT 给代码建议 |
| L2 | 协同型 | AI 执行，每步需人类确认 | Claude Code 默认权限模式 |
| L3 | 半自主 | AI 独立执行，人类可随时干预 | Claude Code bypass 模式 |
| L4 | 全自主 | AI 独立完成端到端任务 | Devin 修复 bug 并提 PR |

### 按架构模式

| 架构 | 说明 | 适用场景 |
|------|------|---------|
| **单 Agent** | 一个模型 + 工具，循环执行 | 个人编码助手 |
| **多 Agent 协作** | 多个 Agent 分工，一个编排者 | 复杂项目（前端+后端+测试） |
| **Agent Swarm** | 大量轻量 Agent 并行工作 | 代码扫描、批量重构 |

---

## 四、Agent 发展脉络

### 2023 — 概念验证期

| 时间 | 事件 | 意义 |
|------|------|------|
| 2023.03 | **AutoGPT** 发布 | 第一个引起广泛关注的自主 Agent，循环执行+工具 |
| 2023.04 | **BabyAGI** 发布 | 极简 Agent 架构（~140 行代码），证明核心循环很简单 |
| 2023.06 | **GPT-4 Function Calling** | OpenAI 官方支持工具调用 |
| 2023.11 | **OpenAI Assistants API** | 托管 Agent 服务（自带记忆/检索/代码解释器） |

### 2024 — 产品化元年

| 时间 | 事件 | 意义 |
|------|------|------|
| 2024.03 | **Devin (Cognition)** | 第一个"AI 软件工程师"，能独立完成 bug 修复并提 PR |
| 2024.03 | **Claude 3 + Tool Use** | Anthropic 官宣工具调用能力 |
| 2024.05 | **Claude Code** (内部发布) | Anthropic 内部编码 Agent |
| 2024.06 | **Cline (VS Code 插件)** | 开源编码 Agent 插件，VS Code 内直接操作 |
| 2024.08 | **Cursor Composer** | AI-first IDE，Agent 模式自动编辑多文件 |
| 2024.10 | **GitHub Copilot Agent Mode** | 微软发布 Agent 模式，自动 PR/issue 处理 |

### 2025 — 规模化与专业化

| 时间 | 事件 | 意义 |
|------|------|------|
| 2025.02 | **Claude Code** 正式发布 | Anthropic 正式产品化，支持 MCP 协议 |
| 2025.03 | **MCP 协议** 开源推广 | Anthropic 推动 Agent-工具标准化 |
| 2025.05 | **A2A 协议** (Google) | Agent-to-Agent 通信协议 |
| 2025.06 | **Codex CLI** (OpenAI) | OpenAI 开源 CLI Agent |
| 2025.08 | **Devin 2.0** | 多 Agent 协作，项目管理级能力 |

### 2026 — 当前

| 趋势 | 表现 |
|------|------|
| **协议标准化** | MCP (工具)、A2A (Agent通信) 成为事实标准 |
| **多 Agent 协作** | 不再是单个 Agent 干活，而是团队协作 |
| **Agent 即服务** | Agent 作为 API/服务嵌入到各种产品中 |
| **垂直领域 Agent** | 不只写代码，法律/医疗/金融都有专业 Agent |

---

## 五、当前赛道的几个关键共识

### 1. "未来没有 SaaS，只有 Agent"

传统 SaaS 给你一个界面（Dashboard → 按钮 → 表单），Agent 直接帮你完成操作。用户不需要学用 Jira，只需说"帮我在这个 sprint 建一个 bug ticket"。

### 2. Agent ≠ 模型

模型（GPT、Claude）是引擎，Agent 是整车。你能换引擎，但车的架构（工具系统、记忆、权限）才是核心壁垒。

### 3. 工具生态决定天花板

模型的推理能力是下限，工具的数量和质量是上限。MCP 协议就是来解决"Agent 怎么接入成千上万种工具"这个问题的。

### 4. 记忆和上下文管理是最大工程挑战

不是模型不够聪明，而是"聊天太长装不下"。压缩、总结、检索——这些工程问题决定了 Agent 能否做长任务。

---

## 六、核心术语速查

| 术语 | 全称 | 解释 |
|------|------|------|
| LLM | Large Language Model | 大语言模型（GPT-4o、Claude 4.5、DeepSeek-V3 等） |
| RAG | Retrieval-Augmented Generation | 检索增强生成：先搜索相关知识，再生成回答 |
| MCP | Model Context Protocol | Anthropic 提出的 Agent-工具通信标准 |
| A2A | Agent-to-Agent | Google 提出的 Agent 间通信协议 |
| Function Calling | — | 模型输出结构化函数调用而不是自由文本 |
| Tool Use | — | Agent 使用外部工具的能力 |
| Agent Loop | — | 感知→规划→行动→观察的循环 |
| Prompt Engineering | — | 设计提示词来引导模型行为 |
| Chain-of-Thought | CoT | 让模型"一步一步想"，提高推理质量 |
| ReAct | Reasoning + Acting | 推理和行动交替进行的 Agent 模式 |
