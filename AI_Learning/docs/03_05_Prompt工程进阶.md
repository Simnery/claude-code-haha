# 03_05 — Prompt 工程进阶

> Prompt Engineering 是 Agent 开发的"源代码"。本项目的 System Prompt 约 10,000+ 字，理解如何管理和优化 Prompt 是高级 Agent 工程师的核心能力。

---

## 一、Prompt 即代码

### 核心理念

```
Prompt 不是"提示词"，而是"行为规范"。
就像代码定义了程序逻辑，Prompt 定义了 Agent 的行为边界。
代码需要版本管理、测试、审查 → Prompt 也需要。
```

### Prompt 的四层结构

以 Claude Code 为例：

```
Layer 1: 角色定义 (~5%)
  "你是一个软件工程师助手..."
  → 定义 Agent 的身份和行为基线

Layer 2: 规则约束 (~25%)
  "不要猜测...先读文件再修改...不引入不必要的抽象..."
  → 定义什么是"正确的行为"

Layer 3: 工具说明 (~50%)
  "Read: 读取文件... Bash: 执行命令... 使用时机:..."
  → 定义 Agent 能做什么、什么时候做

Layer 4: 上下文注入 (~20%)
  "当前工作目录: /project ... Git 分支: main ..."
  → 动态信息，每轮更新
```

---

## 二、Prompt 版本管理

### 为什么需要？

```
场景: 改了 System Prompt 后，Agent 反而变差了
问题: 不知道改了什么、什么时候改的、影响多大
解决: Prompt 也走 Git 流程
```

### 实践

```
prompts/
├── system/
│   ├── base_prompt.txt          ← 当前生产版本
│   ├── base_prompt_v0.12.txt    ← 历史版本
│   ├── base_prompt_v0.13.txt
│   └── base_prompt_v0.14.txt    ← 实验版本
├── tools/
│   ├── read_file.txt
│   ├── write_file.txt
│   └── bash.txt
└── rules/
    ├── code_style.txt
    └── safety_rules.txt
```

### 或用 Git 管理

```bash
# Prompt 变更也走 PR 流程
git log --oneline prompts/
a1b2c3d feat: 调整 Write 工具说明，强调 prefer Edit over Write
e4f5g6h fix: 补充 Bash 工具的安全约束
```

---

## 三、Prompt 调试技巧

### 3.1 隔离变量

```python
# 怀疑是某个 Prompt 片段导致的问题 → 逐个移除测试
prompts = {
    "base": "你是一个编码助手",
    "rules": "不要猜测...",
    "tools": "你可以使用以下工具...",
    "context": "当前项目是 TypeScript..."
}

# A/B 测试
result_with_rules = run_agent(prompts["base"] + prompts["rules"] + prompts["tools"])
result_without_rules = run_agent(prompts["base"] + prompts["tools"])

# 对比两个结果的差异
compare(result_with_rules, result_without_rules)
```

### 3.2 Token 分析

```python
# 监控 Prompt 各部分的 token 占比
import tiktoken

enc = tiktoken.encoding_for_model("gpt-4o")

for name, content in prompts.items():
    tokens = len(enc.encode(content))
    print(f"{name}: {tokens} tokens ({tokens/200000*100:.1f}% of context)")
```

### 3.3 日志对比

```python
# 记录每次 Agent 执行的关键决策
log = {
    "prompt_version": "v0.14",
    "model": "claude-sonnet-4-6",
    "task": "创建 logger.ts",
    "tool_calls": ["Write", "Bash"],
    "result": "success",
    "user_feedback": "好"  # or "不好"
}
```

---

## 四、A/B 测试 Prompt

### 流程

```
1. 定义指标（任务完成率、工具选择准确率、用户满意度）
2. 准备测试集（30-100 个代表性任务）
3. 跑基线（当前 Prompt → 基线分数）
4. 改 Prompt
5. 跑实验组（新 Prompt → 新分数）
6. 对比 → 变好合入，变差回滚
```

### 最小化 A/B 脚本

```python
def ab_test(prompt_a, prompt_b, test_cases):
    results_a = []
    results_b = []
    
    for case in test_cases:
        # 跑 Prompt A
        resp_a = agent.run(case["input"], system_prompt=prompt_a)
        score_a = evaluate(resp_a, case["expected"])
        results_a.append(score_a)
        
        # 跑 Prompt B
        resp_b = agent.run(case["input"], system_prompt=prompt_b)
        score_b = evaluate(resp_b, case["expected"])
        results_b.append(score_b)
    
    avg_a = sum(results_a) / len(results_a)
    avg_b = sum(results_b) / len(results_b)
    
    print(f"Prompt A 平均分: {avg_a:.2f}")
    print(f"Prompt B 平均分: {avg_b:.2f}")
    print(f"差异: {avg_b - avg_a:+.2f}")
    
    return {"a": avg_a, "b": avg_b, "winner": "B" if avg_b > avg_a else "A"}
```

---

## 五、Prompt 优化策略

### 5.1 精简

```
❌ 啰嗦: "请你仔细阅读以下文件的全部内容，在充分理解之后..."
✅ 精炼: "读取文件。理解后修改。"

规则: 每句话都要有信息量。删掉所有客套话。
```

### 5.2 具体化

```
❌ 模糊: "要写出好代码"
✅ 具体: "优先使用项目现有的工具函数。函数不超过 40 行。用 const 而非 let。"
```

### 5.3 给反例

```
✅ "不要这样做: rm -rf node_modules && npm install
   应该这样做: npm ci (用 package-lock.json 保证一致性)"
```

### 5.4 分层组织

```
❌ 所有规则混在一起
✅ 用 XML 标签分层:
<role>...</role>
<tool_usage>...</tool_usage>
<code_style>...</code_style>
<safety_rules>...</safety_rules>
```

---

## 六、Agent 的 System Prompt 审计清单

在发布 Prompt 变更前，检查：

```
[ ] 是否无意中放宽了某个安全约束？
[ ] 新增的规则是否和已有规则冲突？
[ ] 工具使用说明是否准确（参数、使用时机）？
[ ] 示例是否正确（没给错误示例当成正确示例）？
[ ] Token 消耗是否在预算内？
[ ] 是否跑过评估集（分数不降才能合）？
```

---

## 七、常用工具

| 工具 | 用途 |
|------|------|
| **LangSmith Hub** | Prompt 共享 + 版本管理 |
| **Braintrust** | Prompt 实验 + 评估 |
| **PromptLayer** | Prompt 日志 + 追踪 |
| **Helicone** | Prompt 监控 + 成本追踪 |
| **TikToken** | Token 计数 |
