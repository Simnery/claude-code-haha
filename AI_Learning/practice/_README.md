# practice/ — 动手练习

## 用途

写完能跑的代码来巩固学到的概念。光看教程不动手，过两天就忘了。

## 使用方式

- 每个 `.ts` 文件是一个独立的练习
- 用 `bun run practice/文件名.ts` 直接跑
- 验证自己对概念的理解——如果写不出来，说明还没真懂

## 建议练习（按难度排序）

### ⭐ 入门

| 练习 | 练什么 | 对应教程 |
|------|--------|---------|
| 手写 `sum()` 函数 | 函数声明、参数、返回值 | TS 教程 §8 |
| 手写 `filter()` | 数组遍历、回调函数 | TS 教程 §10 |
| 手写 `map()` | 数组变换、箭头函数 | TS 教程 §10 |

### ⭐⭐ 进阶

| 练习 | 练什么 | 对应教程 |
|------|--------|---------|
| 手写 Promise 类 | then/catch/resolve/reject 原理 | async 详解 §3 |
| 手写同步生成器 | yield/next 通信机制 | Generator 详解 §2-4 |
| 手写简单闭包 | 闭包原理、独立状态 | TS 教程 §8.5 |

### ⭐⭐⭐ 实战

| 练习 | 练什么 | 对应教程 |
|------|--------|---------|
| 模拟 Agent 循环 | while + yield + async/await | Generator 详解 §6 |
| 手写事件循环模拟 | Call Stack / Microtask / Macrotask | async 详解 §2 |
| 模拟模型调用 | async generator + 流式输出 | query.ts 逻辑 |

## 文件命名

```
practice/
├── 01_sum.ts              ← 数字序号 + 简短描述
├── 02_filter.ts
├── 03_promise.ts
├── 04_generator.ts
└── 05_agent_loop.ts
```

## 练习模板

```typescript
// practice/01_sum.ts
// 目标：实现一个 sum 函数，接收任意个数字参数，返回总和
// 对应：00_01_TS语法教程.md §8.4

// === 你的实现 ===
function sum(...nums: number[]): number {
  // TODO
}

// === 测试（不要改） ===
console.assert(sum(1, 2) === 3, "测试1失败")
console.assert(sum(1, 2, 3, 4, 5) === 15, "测试2失败")
console.assert(sum() === 0, "测试3失败")
console.log("全部通过！")
```
