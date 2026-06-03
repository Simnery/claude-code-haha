# code-trace/ — 代码追踪

## 用途

逐行走读项目中真实的代码路径，理解数据是怎么流转的。

和 `notes/` 的区别：
- `notes/` = 理解概念（"闭包是什么"）
- `code-trace/` = 追踪真实代码（"项目里哪段代码用了闭包，怎么用的"）

## 使用方式

- 选一个代码路径（比如"用户输入一句话到 AI 返回"）
- 从入口开始，逐文件追踪，记录每个函数调用
- 画出调用链，标注关键变量

## 建议追踪路径

| 序号 | 路径 | 涉及文件 |
|------|------|---------|
| 1 | 启动流程 | cli.tsx → main.tsx → init.ts → replLauncher.tsx |
| 2 | 一次用户请求 | REPL.tsx → processUserInput() → query() → callModel() |
| 3 | 工具执行 | query() → runTools() → canUseTool() → tool.execute() |
| 4 | 模型切换 | /model opus → parseUserSpecifiedModel() → setMainLoopModelOverride() |
| 5 | 上下文压缩 | query() → autocompact() → buildPostCompactMessages() |

## 文件命名

```
code-trace/
├── 01_启动流程.md          ← 和 docs/01_01 对应，但用自己的话写
├── 02_一次请求完整链路.md
├── 03_工具执行追踪.md
└── 04_模型切换追踪.md
```

## 追踪模板

```markdown
# {追踪主题}

> 日期：{日期}
> 起点：{从哪个函数/事件开始}
> 终点：{最后发生了什么}

## 调用链

cli.tsx main()                                ← 起点
  └─ (await import('../main.js')).main()
       └─ main.tsx 约 2000 行处
            ├─ init()                         ← 初始化
            ├─ getUserSpecifiedModelSetting() ← 确定模型
            └─ launchRepl()                   ← 启动 UI
                 └─ REPL.tsx mount

## 关键代码片段

（每个关键跳转点放 2-3 行实际代码 + 行号）

## 我的理解

（用一句话概括整个链路做了什么）

## 疑问

- [ ] 问题
```
