# snippets/ — 常用模式速查

## 用途

从项目中摘录的高频代码模式，标注好注释，供快速查阅和模仿。

和 `docs/` 的区别：
- `docs/` = 完整教程（从概念到示例）
- `snippets/` = 纯代码片段（已经懂了概念，只是忘了怎么写）

## 使用方式

- 读到一段典型的项目代码，摘到对应的 snippets 文件里
- 加注释解释"为什么这么写"
- 积累多了就是自己的代码模式库

## 建议分类

```
snippets/
├── async_patterns.ts       ← async/await 常用写法
├── generator_patterns.ts   ← 生成器常用写法
├── type_patterns.ts        ← TS 类型体操
├── error_handling.ts       ← 错误处理模式
├── tool_patterns.ts        ← 工具定义/执行模式
└── react_patterns.ts       ← Ink 组件写法
```

## 片段格式

每个片段用 `// ==== 标题 ====` 分隔，包含：
1. 这段代码在项目的哪个文件
2. 它解决了什么问题
3. 核心代码（加注释）
4. 关键点说明
