# 02_06 — Agent 开发完整流程与最佳实践

> 从 0 到 1 开发一个定制化 Agent 的实操流程。

---

## 一、开发全流程

```
Phase 1: 需求定义 (1-2 天)
  → Phase 2: 最小可行 Agent (1-2 周)
    → Phase 3: 核心能力扩展 (2-4 周)
      → Phase 4: 生产化 (2-4 周)
        → Phase 5: 迭代优化 (持续)
```

---

## 二、Phase 1: 需求定义

### 回答 5 个关键问题

```
1. 你的 Agent 要解决什么具体问题？
   ❌ "做一个 AI 助手"              ← 太模糊
   ✅ "帮前端工程师把 Figma 设计稿转成 React 组件"  ← 具体

2. 用户是谁？技术水平如何？
   - 开发者 → CLI/IDE 集成
   - 非技术人员 → Web 界面/Chat 界面

3. Agent 需要什么能力？
   - 读文件 → 文件系统工具
   - 查 API 文档 → WebFetch + RAG
   - 操作数据库 → SQL 工具
   - ...列出所有需要的工具

4. 自主程度？
   - 每步需要确认？（安全但慢）
   - 完全自主？（快但有风险）
   - 分级？（推荐）

5. 成功标准是什么？
   - 完成任务的比例？
   - 用户评分？
   - 省了多少时间？
```

### 输出物

```
一份需求文档:
  - 用户画像
  - 核心场景（3-5 个）
  - 工具需求清单
  - 权限模型
  - 成功指标
```

---

## 三、Phase 2: 最小可行 Agent (MVP)

### 第 1 步：核心循环

```typescript
// 最小 Agent — 不到 50 行
async function minimalAgent(userInput: string) {
  const messages = [
    { role: 'system', content: '你是一个编码助手。使用工具来完成任务。' },
    { role: 'user', content: userInput }
  ]

  const tools = [readFileTool, writeFileTool, bashTool]

  while (true) {
    const response = await callModel(messages, tools)

    if (response.stopReason === 'end_turn') break

    for (const toolCall of response.toolUses) {
      const result = await executeTool(toolCall)
      messages.push({ role: 'user', content: JSON.stringify(result) })
    }
  }

  return response.text
}
```

### 第 2 步：定义 3-5 个核心工具

```
必备工具:
  1. ReadFile   — 读文件
  2. WriteFile  — 写文件
  3. Bash       — 执行命令

按需添加:
  4. Grep       — 搜索代码
  5. WebFetch   — 查文档
```

### 第 3 步：加最简单的 UI

```
CLI 方案: readline + console.log
Web 方案: Streamlit / 简单的 HTML 聊天框
```

### 检查点

```
✅ Agent 能完成一个简单任务（如"创建一个 hello world 项目"）
✅ 流式输出正常
✅ 工具执行正常
✅ 错误不会让整个进程崩溃
```

---

## 四、Phase 3: 核心能力扩展

### 3.1 上下文管理

```
问题: 对话长了之后，模型回复质量下降

解决:
  1. Token 计数 → 监控使用率
  2. 自动压缩 → 超过 70% 窗口时触发总结
  3. 裁剪策略 → 保留最近 N 条，旧消息 → 摘要
```

### 3.2 权限系统

```
基础三级:
  L1: bypass     → 自动执行（内部工具、信任环境）
  L2: ask        → 弹出确认（默认，修改文件等操作）
  L3: deny       → 永远禁止（rm -rf / 等危险操作）

额外:
  - 规则持久化: 用户选了"永远允许"后记住
  - 模式切换: /permission-mode bypass
```

### 3.3 记忆系统

```
短期记忆: 对话历史自动保存
长期记忆: Agent 判断重要信息后写入
  - 格式: Markdown (类似 MEMORY.md)
  - 或: 向量数据库（语义搜索）

触发写入的时机:
  - 用户说"记住这一点"
  - Agent 判断某个信息跨会话有用
  - 用户纠正 Agent 的行为
```

### 3.4 错误恢复

```
API 错误:
  → 自动重试（指数退避）
  → 重试 3 次失败 → 换备用模型
  → 还失败 → 告诉用户

工具错误:
  → 把错误信息还给模型
  → 模型自己判断怎么修正
  → 修正不了 → 问用户
```

---

## 五、Phase 4: 生产化

### 4.1 性能

```
- 流式输出: 第一个 token 延迟 < 1 秒
- 工具执行: 独立工具可并发 (Promise.all)
- 上下文压缩: 异步执行，不阻塞用户
```

### 4.2 安全

```
- API Key 管理: 环境变量，不上传 git
- 沙箱执行: Docker / 独立进程
- 命令白名单: 只允许执行特定命令
- 文件访问范围: 限制在工作目录内
- 审计日志: 记录所有操作
```

### 4.3 监控

```
- Token 用量和成本
- 任务成功率
- 平均完成时间
- 错误率（分类统计）
- 用户满意度
```

### 4.4 部署

```
CLI Agent:
  npm 包 → npm install -g my-agent

Web Agent:
  Docker 容器 → 部署到服务器

IDE 插件:
  发布到 VS Code Marketplace / JetBrains Marketplace
```

---

## 六、Phase 5: 持续优化

### 优化方向

| 方向 | 方法 |
|------|------|
| 模型效果 | A/B 测试不同模型、调 system prompt |
| 工具质量 | 优化工具描述让模型更准确调用 |
| 上下文效率 | 压缩策略、记忆检索精度 |
| 执行速度 | 并发工具、缓存、模型选择（小模型做简单任务） |
| 用户体验 | 收集反馈、优化交互流程 |

### 常见坑

```
❌ System Prompt 太长 → 模型忽略指令 → 精简到必要信息
❌ 工具描述太模糊 → 模型不知道该用哪个 → 加具体场景说明
❌ 权限太宽松 → 安全事故 → 默认 ask，重要操作二次确认
❌ 不限制 Turn 数 → 死循环 → 设 maxTurns，检测循环
❌ 忽略 Token 消耗 → 成本爆炸 → 监控 + 压缩 + 用便宜模型做简单任务
```

---

## 七、开发路线图总结

```
Week 1-2:  MVP
  ├─ 核心循环
  ├─ 5 个核心工具
  └─ 简单 CLI

Week 3-4:  核心能力
  ├─ 上下文管理
  ├─ 权限系统
  └─ 错误恢复

Week 5-6:  体验打磨
  ├─ 更好 UI (Ink/Web)
  ├─ 记忆系统
  └─ 流式渲染

Week 7-8:  生产化
  ├─ 安全加固
  ├─ 监控/日志
  └─ 打包发布
```
