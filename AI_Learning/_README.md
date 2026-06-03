# AI_Learning — Claude Code 源码学习工作区

## 目录结构

```
AI_Learning/
├── docs/           ← 教程文档 + 架构分析（16 篇）
├── notes/          ← 个人学习笔记
├── practice/       ← 动手练习代码
├── code-trace/     ← 真实代码路径追踪
├── snippets/       ← 项目常用代码模式摘录
└── checklists/     ← 学习进度清单
```

## 学习路线

```
1. docs/00_00_学习指导.md         ← 从这里开始，了解全局框架
2. docs/00_01~00_06               ← 语法和概念教程
3. practice/                      ← 动手写代码，验证理解
4. docs/01_01~01_09               ← 项目架构分析
5. code-trace/                    ← 追踪真实代码路径
6. notes/ + snippets/ + checklists/  ← 持续积累
```

## 外部参考：cc-haha 官方文档

项目根目录 `docs/` 是 cc-haha 开发者维护的 VitePress 文档站，涵盖本项目特有功能的详细说明，可作为学习参考：

| 目录 | 内容 | 重点推荐 |
|------|------|---------|
| [`docs/guide/`](../docs/guide/) | 快速开始、环境变量、FAQ、第三方模型接入 | `quick-start.md` `third-party-models.md` |
| [`docs/agent/`](../docs/agent/) | 多 Agent 系统的使用、实现、框架 | `01-usage-guide.md` |
| [`docs/skills/`](../docs/skills/) | Skills 技能系统的使用和实现 | `01-usage-guide.md` |
| [`docs/memory/`](../docs/memory/) | 记忆系统（AutoDream 等） | `01-usage-guide.md` |
| [`docs/desktop/`](../docs/desktop/) | 桌面端快速开始、架构、特性、FAQ | `02-architecture.md` |
| [`docs/im/`](../docs/im/) | IM 接入（Telegram/飞书/微信/钉钉） | 各平台接入指南 |
| [`docs/features/`](../docs/features/) | Computer Use 功能 | `computer-use.md` |
| [`docs/channel/`](../docs/channel/) | Channel 通道机制 | — |
| [`docs/superpowers/`](../docs/superpowers/) | 增强能力 | — |

> 区别：`AI_Learning/docs/` = 源码级教程（语言 + 架构）；根目录 `docs/` = 产品级文档（功能怎么用）。

## 使用建议

- **每天至少写一点**：笔记、代码、追踪都可以，关键是持续
- **遇到不懂就问**：把问题记在 notes/ 里，攒一批后问我
- **不要追求完美**：笔记潦草没关系，练习没写完也没关系，重要的是动笔
- **源码和产品文档对照看**：本目录 docs/ 讲代码原理，根目录 docs/ 讲功能用法，两者互补
