# 03_03 — Agent 评估体系 (Evals)

> "如果你不能评估你的 Agent，你就无法改进它。"

---

## 一、为什么 Agent 评估这么难？

### 传统软件 vs Agent

| | 传统软件 | Agent |
|---|---|---|
| 预期输出 | 确定的（`add(2,3)` 一定等于 5） | 不确定（同一问题每次回答可能不同） |
| 测试方式 | `assertEqual(expected, actual)` | 需要判断"好不好"而非"对不对" |
| Bug 来源 | 代码逻辑错误 | Prompt 不清晰 / 工具缺失 / 模型推理偏差 |
| 回归测试 | 改完代码跑一遍 | 改完 Prompt 跑一遍——但怎么判断"过"还是"没过"？ |

---

## 二、评估层次

### L1: 单元评估（单个工具/步骤）

```
测试: "Agent 是否选择了正确的工具？"
输入: "帮我读 README.md"
预期: Agent 调用 Read 工具，参数 path="README.md"
判断: tool_name == "Read" && args.path == "README.md"
```

### L2: 任务评估（端到端）

```
测试: "Agent 能否完成一个完整任务？"
输入: "在 src/utils 下创建一个 logger.ts"
判断: 
  ✅ 文件存在
  ✅ 内容包含预期的导出函数
  ✅ TypeScript 类型正确
```

### L3: 行为评估（质量判断）

```
测试: "Agent 的行为是否合理？"
输入: "帮我改一下登录逻辑"
判断:
  ✅ Agent 先读文件理解现状再改（不是直接覆盖）
  ✅ 修改后运行了测试
  ✅ 危险操作前请求了确认
```

---

## 三、评估方法

### 3.1 规则判断

```python
# 确定性的检查
def test_tool_selection():
    result = agent.run("读取 package.json")
    assert result.tool_calls[0].name == "Read"
    assert result.tool_calls[0].args["path"] == "package.json"
```

**适用**: 工具选择、文件操作结果、格式检查

### 3.2 LLM-as-Judge

用另一个模型（通常是更强的模型）来打分：

```python
eval_prompt = f"""
你是一个 Agent 评估者。请根据以下标准给 Agent 的回答打分 (1-5):

标准:
- 是否准确回答了问题？
- 是否基于提供的文档？
- 是否在不确定时诚实地说明？

用户问题: {user_question}
Agent 回答: {agent_response}
参考文档: {reference_docs}

请只输出分数 (1-5):
"""

score = call_stronger_model(eval_prompt)
```

**适用**: 回答质量、语气、完整性等主观指标

### 3.3 人工评估

找真人（或领域专家）对 Agent 的回答打分。最准但最慢。

### 3.4 A/B 测试

```
模型 A (GPT-4o) + Prompt A → 100 个任务的完成率 72%
模型 B (Claude 4.5) + Prompt B → 100 个任务的完成率 81%
→ B 胜出
```

---

## 四、评估数据集设计

### 好的评估集特征

```
1. 代表性: 覆盖常见场景 + 边缘情况
2. 标注: 每个问题有"标准答案"或"评判标准"
3. 独立: 不能拿训练 Prompt 时用的例子当测试集
4. 分层: 简单/中等/困难 各占一定比例
```

### 测试集结构

```json
[
  {
    "id": "task_001",
    "difficulty": "easy",
    "input": "创建 src/utils/math.ts，导出 add 函数",
    "expected_tools": ["Write"],
    "expected_files": ["src/utils/math.ts"],
    "eval_type": "rule"  // rule 或 llm_judge
  },
  {
    "id": "task_052",
    "difficulty": "hard", 
    "input": "重构 src/api/ 的错误处理，统一用 Result 类型",
    "expected_tools": ["Read", "Grep", "Edit"],
    "expected_behavior": "先探索再修改，不破坏现有接口",
    "eval_type": "llm_judge"
  }
]
```

---

## 五、评估工具

| 工具 | 类型 | 适用 |
|------|------|------|
| **LangSmith** | 商业 (有免费层) | LangChain 生态、Agent 追踪+评估 |
| **Braintrust** | 商业 (有免费层) | Prompt 实验 + 评估 + 数据集管理 |
| **Arize Phoenix** | 开源 | LLM 可观测性 + 评估 |
| **Ragas** | 开源 | RAG 系统专用评估 (faithfulness/relevancy) |
| **DeepEval** | 开源 | 通用 LLM 评估框架、支持多种指标 |
| **Promptfoo** | 开源 | Prompt 安全测试 + 评估 |
| **自建测试集** | 自研 | 用 JSON/YAML 定义测试用例，配合脚本 |

---

## 六、评估流程 (Eval Pipeline)

```
1. 定义评估集
   └─ 30-100 个代表性任务，标注预期行为

2. 建立基线
   └─ 跑一遍当前 Agent，记录分数 = "当前水平"

3. 每次改动后评估
   ├─ 改了 Prompt → 跑评估
   ├─ 换了模型 → 跑评估
   └─ 加了工具 → 跑评估

4. 对比分数
   ├─ 变好了 → 合入
   └─ 变差了 → 排查原因、回滚

5. 定期扩充评估集
   └─ 把线上发现的 Bad Case 加入评估集
```

---

## 七、实战：最小化评估脚本

```python
# 一个最简单的 Agent 评估脚本
import json

def evaluate_agent(agent, test_cases):
    results = {"passed": 0, "failed": 0, "details": []}
    
    for case in test_cases:
        response = agent.run(case["input"])
        
        if case["eval_type"] == "rule":
            passed = check_rules(response, case["expected"])
        else:
            passed = llm_judge(response, case["criteria"])
        
        results["details"].append({
            "id": case["id"],
            "passed": passed,
            "response": response
        })
        
        if passed:
            results["passed"] += 1
        else:
            results["failed"] += 1
    
    results["pass_rate"] = results["passed"] / len(test_cases)
    print(f"通过率: {results['pass_rate']:.1%}")
    return results
```

---

## 八、关键认知

1. **评估不是一劳永逸**: 每改 Prompt/工具/模型都要重跑
2. **评估集会腐败**: 如果反复针对评估集调 Prompt，评估集就失效了（过拟合）
3. **LLM-as-Judge 有偏差**: 评估模型可能偏好某种风格（比如 GPT-4 可能偏爱 GPT-4o 的输出）
4. **评估成本**: 30 道题 × 每次改动跑一遍 × LLM-as-Judge 的 API 费用 —— 控制规模
5. **没有银弹**: 规则判断 + LLM 打分 + 人工抽检 组合使用
