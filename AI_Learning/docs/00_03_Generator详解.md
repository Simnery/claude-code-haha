# 00_03 — Generator 和 AsyncGenerator 深入详解

> 面向人群：已了解 `yield` 基本概念，想要理解项目中 `query()` 为何用生成器模式。

---

## 一、回顾：普通函数的局限

```typescript
// 普通函数：一口气执行完，中间不能停
function count(): number[] {
  const results = []
  for (let i = 1; i <= 1000000; i++) {
    results.push(i)
  }
  return results   // 全部算完才返回，内存爆炸
}
```

问题：
1. 必须等全部算完才能拿到结果
2. 100 万个数字全存在内存里
3. 调用方无法在中间干预（比如第 500 个就停）

---

## 二、生成器是什么

> **生成器 = 一个可以"暂停"和"恢复"的函数。**

```typescript
// function* 声明这是一个生成器（多了个 *）
function* count(): Generator<number> {
  console.log("开始")
  yield 1         // ← 产出 1，暂停！
  console.log("恢复")
  yield 2         // ← 产出 2，再暂停！
  console.log("恢复")
  yield 3         // ← 产出 3，再暂停！
  console.log("结束")
}

const gen = count()
console.log(gen.next())  // { value: 1, done: false }  输出"开始"
console.log(gen.next())  // { value: 2, done: false }  输出"恢复"
console.log(gen.next())  // { value: 3, done: false }  输出"恢复"
console.log(gen.next())  // { value: undefined, done: true }  输出"结束"
```

每一个 `yield`：
- 产出 `value` 给调用方
- 函数在此**冻结**（局部变量、执行位置全部保留）
- 调用方 `next()` 后，从冻结处**继续执行**

---

## 三、生成器作为"推拉"数据流

### 传统方式：推 (Push)

```typescript
// 一次性把结果全"推"给调用方
function getAllUsers(): User[] {
  return query("SELECT * FROM users")  // 全加载到内存
}
// 调用方拿到的是完整数组，等数据库全读完那一刻
```

### 生成器方式：拉 (Pull)

```typescript
// 调用方主动"拉"一个处理一个
function* getAllUsers(): Generator<User> {
  while (true) {
    const row = queryNextRow()   // 每次只读一行
    if (!row) break
    yield row
  }
}

for (const user of getAllUsers()) {
  console.log(user.name)
  // 处理完一个才"拉"下一个
  // 内存中始终只有一个 user
}
```

---

## 四、双向通信：yield 也可以接收值

```typescript
function* calculator(): Generator<number, void, string> {
  //                                  返回值 产出类型 接收类型
  const question = yield 0  // 第一次 yield 给调用方一个初始值 0
  // next('xxx') 传入的值赋给 question

  if (question === "加") {
    const a = yield 1        // 问"第一个数是多少"
    const b = yield 2        // 问"第二个数是多少"
    return a + b             // 返回结果
  }
}

const calc = calculator()
calc.next()        // { value: 0, done: false }  → 启动生成器
calc.next("加")    // { value: 1, done: false }  → 传"加"，问第一个数
calc.next(10)      // { value: 2, done: false }  → 传 10，问第二个数
calc.next(20)      // { value: 30, done: true }  → 传 20，返回 10+20=30
```

---

## 五、异步生成器 (AsyncGenerator) — 本项目核心

### 语法

```typescript
// 注意三个关键点：
//   async function*  → 异步生成器
//   yield            → 产出值
//   for await...of   → 消费方式
async function* streamData(): AsyncGenerator<string> {
  const data = await fetchSomeData()   // await 异步操作
  for (const item of data) {
    yield item     // 一个一个产出
  }
}

// 消费
for await (const item of streamData()) {
  console.log(item)
}
```

### 和同步生成器的核心区别

| | 同步 Generator | 异步 AsyncGenerator |
|---|---|---|
| 声明 | `function*` | `async function*` |
| 内部 await | ❌ 不能用 | ✅ 可以用 |
| 消费 | `for...of` | `for await...of` |
| next() 返回 | `{ value, done }` | `Promise<{ value, done }>` |

---

## 六、为什么 query() 用生成器？

### 对比：不用生成器

```typescript
// 不用生成器：必须一次性返回所有结果
async function query(params): Promise<QueryResult> {
  const allMessages: Message[] = []

  // 等 API 返回全部
  const response = await callModel(...)

  // 等工具执行全部
  const toolResults = await runTools(...)

  // 等压缩完成
  await compact(...)

  // 汇总 → 一次性返回
  return { messages: allMessages, ... }
}
// 问题：
// 1. 调用方在整个过程结束前什么也看不到
// 2. 不能实时渲染 token
// 3. 无法中途中断
```

### 用生成器

```typescript
// 用了生成器：逐个产出事件
async function* query(params): AsyncGenerator<StreamEvent | Message> {
  while (true) {
    // 逐 token 产出
    for await (const event of callModel(...)) {
      yield event  // ← 每收到一个 token 就产出，终端实时显示
    }

    // 逐工具产出
    for (const result of await runTools(...)) {
      yield result  // ← 每个工具执行完就产出
    }

    // 压缩边界
    if (needCompact) {
      yield compactBoundaryMessage
    }

    if (done) break
  }
}
// 优势：
// 1. 调用方实时看到每个 token
// 2. 实时看到每个工具的执行状态
// 3. 随时可以中断（generator.return()）
```

---

## 七、中断生成器

```typescript
// 调用方可以随时中断
const iterator = query(params)

for await (const event of iterator) {
  if (userPressedEsc) {
    iterator.return()   // 强制终止生成器
    break
  }
  render(event)
}
```

项目中的实现 (`src/query.ts`)：

```typescript
// 通过 AbortController 信号中断
const controller = new AbortController()

// API 调用时传入信号
callModel({ signal: controller.signal })

// 用户中断 → abort
controller.abort()
// → API 请求取消
// → for await 循环中断
// → query() 返回 Terminal { reason: 'interrupted' }
```

---

## 八、嵌套生成器：yield*

```typescript
// 一个生成器委托给另一个
function* subTask(): Generator<string> {
  yield "子任务 - 步骤1"
  yield "子任务 - 步骤2"
}

function* mainTask(): Generator<string> {
  yield "主任务开始"
  yield* subTask()          // ← 委托给 subTask，把它的 yield 全部转发
  yield "主任务结束"
}

for (const msg of mainTask()) {
  console.log(msg)
}
// 输出：主任务开始, 子任务-步骤1, 子任务-步骤2, 主任务结束
```

项目中的 `query()` 就用了这个模式：

```typescript
export async function* query(params) {
  const terminal = yield* queryLoop(params, consumedCommandUuids)
  // queryLoop 的所有 yield 都会透传给 query() 的调用方
  // queryLoop 的 return 值赋给 terminal
  return terminal
}
```

---

## 九、和 Promise 对比：什么时候用哪个？

| 场景 | 用 Promise | 用 AsyncGenerator |
|------|-----------|-------------------|
| 一个异步请求，一个结果 | ✅ `await fetch(...)` | ❌ 杀鸡用牛刀 |
| 多个独立请求并发 | ✅ `Promise.all([...])` | ❌ |
| 流式数据（逐 token） | ❌ | ✅ `yield token` |
| 多轮交互（模型→工具→模型） | ❌ | ✅ while 循环 + yield |
| 分页数据（一页一页拿） | ❌ | ✅ |
| 回调/事件流 | ❌ | ✅ |

---

## 十、速查

```typescript
// 声明
function* gen(): Generator<number> { yield 1 }
async function* asyncGen(): AsyncGenerator<number> { yield 1 }

// 消费
for (const v of gen()) { ... }           // 同步
for await (const v of asyncGen()) { ... } // 异步

// 手动消费
gen.next()           // → { value, done }
gen.next(newValue)   // 传入值给 yield
gen.return()         // 强制结束
gen.throw(err)       // 注入错误

// 委托
yield* otherGen()    // 转发另一个生成器的所有产出

// 类型
Generator<T>                   // 同步，产出 T
Generator<T, R>                // 产出 T，return R
Generator<T, R, N>             // 产出 T，return R，接收 N
AsyncGenerator<T, R, N>        // 异步版本
```

---

## 十一、本项目核心生成器链路

```
query()                           ← 入口
  └─ yield* queryLoop()           ← 主循环（while true）
       ├─ yield stream_event      ← API 返回的 token
       ├─ yield tool_use          ← 工具调用
       ├─ yield tool_result       ← 工具执行结果
       ├─ yield compact_boundary  ← 压缩边界
       └─ return Terminal         ← 结束

REPL / QueryEngine                ← 消费端
  └─ for await (event of query())
       ├─ 渲染 token
       ├─ 显示工具状态
       └─ 决定是否中断
```
