# 01 — async/await 深入详解

> 面向人群：已了解 async/await 基本用法，想要深入理解"等待不阻塞"的原理。

---

## 一、为什么需要异步？

### 问题场景

```typescript
// 假设 JS 是同步的（阻塞 I/O）：
const data = readFileSync("huge_file.txt")  // 卡住 3 秒
console.log("文件读完了")                     // 3 秒后才执行
console.log("这行也等了 3 秒...")             // 用户界面完全卡死
```

### JS 的答案：事件循环

JS 是**单线程**的——同一时刻只能做一件事。如果读文件卡 3 秒，整个程序（包括 UI）就冻住 3 秒。

**解决方案**：把耗时操作交给系统后台（libuv / 浏览器内核），完成后通知 JS 回来取结果。JS 主线程在等待期间继续处理其他任务。

---

## 二、事件循环 (Event Loop)

> 用洗衣服类比理解事件循环。

```
你（JS 主线程）
  ↓ 把衣服丢进洗衣机（发起 I/O 请求）
  ↓ 去干别的事（继续执行后面的代码）
  ↓                                         洗衣机在洗（操作系统 I/O）
  ↓                                         洗衣机响了（I/O 完成）
  ↓ 回来取衣服（执行回调）

这个过程就叫"事件循环"
```

### 技术视角

```
  调用栈 (Call Stack)
  └─ 当前正在执行的函数（同步代码一行行往下走）

  任务队列 (Task Queue / Macrotask)
  ├─ setTimeout 回调
  ├─ I/O 完成回调
  └─ UI 事件

  微任务队列 (Microtask Queue)
  ├─ Promise.then() 回调
  ├─ async/await 的后续代码
  └─ queueMicrotask()
```

### 执行顺序规则

```
1. 执行完当前调用栈的所有同步代码
2. 清空所有微任务（Microtask Queue）
3. 从任务队列（Macrotask Queue）取一个执行
4. 重复 2-3
```

### 实例

```typescript
console.log("1. 同步代码")

setTimeout(() => {
  console.log("4. setTimeout 回调 → Macrotask")
}, 0)

Promise.resolve().then(() => {
  console.log("3. Promise.then → Microtask")
})

console.log("2. 同步代码")

// 输出顺序：1 → 2 → 3 → 4
//
// 原因：
//   setTimeout 进 Macrotask 队列
//   Promise.then 进 Microtask 队列
//   同步代码执行完 → 先清空 Microtask（3）→ 再取 Macrotask（4）
```

---

## 三、Promise 的本质

> Promise 不是"让代码异步执行"，而是**更容易管理异步操作**。

### 没有 Promise 的时代（回调地狱）

```typescript
readFile("a.txt", (err, dataA) => {
  if (err) return console.error(err)
  readFile("b.txt", (err, dataB) => {
    if (err) return console.error(err)
    readFile("c.txt", (err, dataC) => {
      if (err) return console.error(err)
      console.log(dataA, dataB, dataC)  // 回调嵌套越来越深...
    })
  })
})
```

### Promise 链式调用

```typescript
readFilePromise("a.txt")
  .then(dataA => readFilePromise("b.txt"))
  .then(dataB => readFilePromise("c.txt"))
  .then(dataC => console.log(dataC))
  .catch(err => console.error(err))    // 一个 catch 处理所有错误
```

### Promise 的三种状态

```
pending（等待中）
  ↓ resolve()
fulfilled（成功）
  ↓ .then() 执行

pending（等待中）
  ↓ reject()
rejected（失败）
  ↓ .catch() 执行

一旦状态从 pending 变成 fulfilled 或 rejected，就不可再变。
```

### 手动创建 Promise

```typescript
function delay(ms: number): Promise<void> {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      resolve()   // ms 毫秒后，"完成"这个 Promise
    }, ms)
  })
}

// 使用时：
await delay(1000)   // 等待 1 秒（不阻塞！）
console.log("1 秒后")

// resolve 的参数会传给 .then() 或 await：
function fetchUser(id: number): Promise<User> {
  return new Promise((resolve, reject) => {
    api.getUser(id, (err, user) => {
      if (err) reject(err)           // 失败
      else resolve(user)             // 成功，user 传给 .then()
    })
  })
}
```

---

## 四、async/await 的本质

### await 到底做了什么？

```typescript
async function demo() {
  console.log("A")
  const result = await somePromise   // ← 暂停 demo()，不暂停主线程！
  console.log("B", result)
}
demo()
console.log("C")

// 输出：A → C → B
//
// 过程：
//   1. 执行 A
//   2. 遇到 await → demo() 暂停，返回的 Promise 还没 resolve
//   3. 主线程继续 → 执行 C
//   4. somePromise resolve 了
//   5. await 后面的代码被放入 Microtask 队列
//   6. 同步代码执行完毕 → 执行 Microtask → 执行 B
```

### async 函数 = 自动包装成 Promise

```typescript
// 这两行等价：
async function f(): Promise<number> { return 42 }
function  f(): Promise<number> { return Promise.resolve(42) }

// async 函数内部 throw = reject
async function g(): Promise<void> {
  throw new Error("出错了")   // 等价于 return Promise.reject(...)
}
g().catch(err => console.log(err.message))   // "出错了"
```

### 错误处理

```typescript
// try/catch 捕获 await 的错误
async function loadData(): Promise<string> {
  try {
    const data = await fetch("/api/data")
    return await data.text()
  } catch (error) {
    console.error("加载失败:", error)
    return ""  // 返回默认值
  }
}

// 或 .catch() 在调用处处理
loadData().catch(error => {
  // 处理错误
})
```

---

## 五、并发 vs 串行

### 串行（一个一个等）

```typescript
// 总耗时 = 1s + 1s + 1s = 3 秒
const user = await fetchUser(1)        // 等 1 秒
const posts = await fetchPosts(1)      // 再等 1 秒
const comments = await fetchComments(1) // 再等 1 秒
```

### 并发（同时开始，一起等）

```typescript
// 总耗时 ≈ 1 秒（取最慢的那个）
const [user, posts, comments] = await Promise.all([
  fetchUser(1),       // 三个请求同时发出
  fetchPosts(1),
  fetchComments(1),
])
```

### 常用并发模式

```typescript
// Promise.all：全部成功才成功，一个失败全失败
await Promise.all([a(), b(), c()])

// Promise.allSettled：等全部结束，不管成功失败
const results = await Promise.allSettled([a(), b(), c()])
// results = [{ status: "fulfilled", value: ... }, { status: "rejected", reason: ... }]

// Promise.race：哪个先完成就返回哪个
const winner = await Promise.race([slowRequest(), timeout(5000)])

// Promise.any：哪个先成功就返回哪个（全失败才报错）
const first = await Promise.any([serverA(), serverB(), serverC()])
```

---

## 六、本项目典型应用

### 1. 全局 try/catch + retry 循环（`src/query.ts`）

```typescript
async function* queryLoop(params: QueryParams) {
  while (true) {
    try {
      // 调用模型（异步流式）
      for await (const message of deps.callModel({...})) {
        yield message
      }
    } catch (error) {
      if (isRetryable(error)) {
        continue  // 重试
      }
      throw error
    }

    // 执行工具（可能是并发的）
    const results = await Promise.all(
      toolUseBlocks.map(block => executeTool(block))
    )

    // 继续循环
  }
}
```

### 2. 并发工具执行（`BatchToolExecutor`）

```typescript
// 多个独立工具同时执行，互不等待
const results = await Promise.all(
  independentTools.map(tool => runTool(tool))
)
```

### 3. 中断机制（AbortController）

```typescript
const controller = new AbortController()

// 发起请求，关联中断信号
const promise = fetch(url, { signal: controller.signal })

// 用户按 Ctrl+C → 中断请求
controller.abort()

// fetch 会抛出 AbortError，被 catch 捕获
try {
  await promise
} catch (err) {
  if (err.name === 'AbortError') {
    console.log('用户中断了请求')
  }
}
```

---

## 七、常见陷阱

### 陷阱 1：忘记 await

```typescript
// ❌ 错误：data 是 Promise<User>，不是 User
const data = fetchUser(1)
console.log(data.name)  // undefined！Promise 对象没有 name

// ✅ 正确
const data = await fetchUser(1)
console.log(data.name)  // "小明"
```

### 陷阱 2：循环中串行执行

```typescript
// ❌ 慢：每个请求等前一个完成
for (const id of ids) {
  const user = await fetchUser(id)
  results.push(user)
}

// ✅ 快：全部并发
const results = await Promise.all(ids.map(id => fetchUser(id)))
```

### 陷阱 3：forEach 中 async

```typescript
// ❌ 没用！forEach 不等 async 函数完成
ids.forEach(async (id) => {
  const user = await fetchUser(id)  // await 被忽略了
})

// ✅ 用 for-of 或 Promise.all
for (const id of ids) {
  await fetchUser(id)
}
```

---

## 八、速查

| 场景 | 写法 |
|------|------|
| 等一个异步操作 | `const x = await fn()` |
| 等多个并发 | `const [a, b] = await Promise.all([fn1(), fn2()])` |
| 等最先完成的 | `const x = await Promise.race([fn1(), timeout(5000)])` |
| 无论成败都等 | `const results = await Promise.allSettled([...])` |
| 不关心结果直接发 | `fn().catch(console.error)` (不带 await) |
| 错误处理 | `try { await fn() } catch (e) { ... }` |
| 中断操作 | 传 `{ signal: abortController.signal }` |
