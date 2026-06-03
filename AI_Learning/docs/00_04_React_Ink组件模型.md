# 03 — React + Ink 组件模型入门

> 面向人群：没有接触过 React 或终端 UI，想理解 cc-haha 的界面是如何渲染的。

---

## 一、背景：三个技术的叠加

| 技术 | 作用 | 原始用途 |
|------|------|---------|
| **React** | UI 组件化框架 | 网页开发 |
| **JSX** | 在代码中写 HTML 标签的语法 | 网页开发 |
| **Ink** | 把 React 组件渲染成终端文字 | 终端应用 |

```
React 官网教程教的是 <div> <button> → 浏览器渲染
Ink 用的是    <Box> <Text>    → 终端渲染（同样的 React 原理）
```

---

## 二、React 核心概念：组件就是函数

### 最简单的 React 组件

```tsx
// 组件就是返回 UI 标签的函数
function Hello() {
  return <Text>Hello, World!</Text>
}
//        ↑这是 JSX，编译后约等于 React.createElement(Text, null, "Hello, World!")
```

### 组件嵌套

```tsx
function App() {
  return (
    <Box flexDirection="column">      {/* Box = 容器，纵向排列 */}
      <Header />                       {/* 嵌套自定义组件 */}
      <Body />
      <Footer />
    </Box>
  )
}
```

### Ink 基础组件

| Ink 组件 | 对应 HTML | 作用 |
|----------|----------|------|
| `<Box>` | `<div>` | 容器，布局用 |
| `<Text>` | `<span>` | 显示文字 |
| `<TextInput>` | `<input>` | 用户输入 |

```tsx
import { Box, Text } from 'ink'

function MyComponent() {
  return (
    <Box flexDirection="column">
      <Text color="green">成功：文件已保存</Text>
      <Text color="red">错误：权限不足</Text>
    </Box>
  )
}
```

---

## 三、props：给组件传参数

```tsx
// 定义组件：声明 props 类型
interface GreetingProps {
  name: string
  color?: string   // 可选
}

function Greeting({ name, color = "white" }: GreetingProps) {
  return <Text color={color}>你好，{name}</Text>
  //                                   ↑ 大括号里写 JS 表达式
}

// 使用组件
<Greeting name="小明" color="green" />
<Greeting name="小红" />   {/* color 用默认值 "white" */}
```

**JSX 的核心规则**：大括号 `{}` 里写 JS 表达式，尖括号 `<>` 里写组件。

---

## 四、状态 (State)：组件自己的"记忆"

```tsx
import { useState } from 'react'

function Counter() {
  const [count, setCount] = useState(0)
  //      ↑       ↑            ↑
  //    当前值  修改函数      初始值

  return (
    <Box>
      <Text>计数：{count}</Text>
      <Text>按 Enter 键+1</Text>
      {/* 当用户按 Enter，调用 setCount → count 变了 → 组件自动重渲染 */}
    </Box>
  )
}
```

### 状态变化 = 自动重渲染

```
1. 调用 setCount(5)
2. React 标记此组件"需要更新"
3. 下一次渲染周期：React 重新执行 Counter()
4. useState(0) 知道这是更新不是初始化 → 返回 [5, setCount]
5. Ink 重新渲染终端文字
```

**和直接的变量赋值的区别**：

```typescript
let count = 0      // 改变不会触发重渲染
// vs
const [count, setCount] = useState(0)  // 改变会触发重渲染
```

---

## 五、useRef：跨渲染保持值的"盒子"

```tsx
import { useRef } from 'react'

function Timer() {
  const countRef = useRef(0)   // { current: 0 }
  // React 保证每次渲染时 ref 是同一个对象

  // 修改 ref.current 不会触发重渲染
  // 适合存"不需要显示在 UI 上"的值
  setInterval(() => {
    countRef.current++
  }, 1000)

  return <Text>已运行 {countRef.current} 秒</Text>
}
```

项目中典型用法：
```typescript
// src/screens/REPL.tsx 中
const abortControllerRef = useRef(new AbortController())
// 这个 ref 在组件整个生命周期存在，但改变不会重渲染
```

---

## 六、useEffect：组件生命周期

```tsx
import { useEffect } from 'react'

function Chat() {
  useEffect(() => {
    // 组件挂载时执行（首次渲染后）
    console.log("聊天组件启动了")
    connectToServer()

    return () => {
      // 组件卸载时执行（清理函数）
      console.log("聊天组件关闭了")
      disconnectFromServer()
    }
  }, [])   // ← 空数组 = 只在挂载/卸载时执行

  return <Box>...</Box>
}
```

```typescript
useEffect(fn, [])        // 只在挂载时执行 fn
useEffect(fn, [count])   // count 变化时执行 fn
useEffect(fn)            // 每次渲染后都执行 fn
```

---

## 七、本项目组件结构

```
App.tsx                           ← 根组件
  ├─ Header / StatusBar           ← 顶栏（模型名、会话信息）
  ├─ REPL.tsx                     ← 主聊天界面
  │   ├─ MessageList              ← 消息列表（对话历史）
  │   │   ├─ UserMessage          ← 用户消息
  │   │   ├─ AssistantMessage     ← AI 回复
  │   │   ├─ ToolUse              ← 工具调用中
  │   │   └─ ToolResult           ← 工具执行结果
  │   ├─ TextInput                ← 底部输入框
  │   └─ PermissionDialog         ← 权限询问弹窗
  └─ Footer / CostBar             ← 底栏（token 用量、费用）
```

### 渲染流程

```
用户输入文字 → TextInput onChange
  ↓
processUserInput() → 构建 Message
  ↓
query() → AsyncGenerator 产出事件
  ↓
for await (event of query())
  ↓
setMessages(prev => [...prev, event])  // 状态更新
  ↓
React 自动重渲染 MessageList
  ↓
Ink 输出到终端
```

---

## 八、本项目关键模式：setState 回调

```tsx
// 从 AppState 获取状态，通过回调更新
function REPL({ getAppState, setAppState }: REPLProps) {
  // 读取当前状态
  const appState = getAppState()
  const messages = appState.messages

  // 更新状态（函数式更新，prev 是当前最新值）
  function addMessage(newMsg: Message) {
    setAppState(prev => ({
      ...prev,
      messages: [...prev.messages, newMsg]
    }))
  }

  return (
    <Box>
      {messages.map(msg => <Message key={msg.id} data={msg} />)}
    </Box>
  )
}
```

---

## 九、Ink 特有模式

### 终端尺寸适配

```tsx
import { useStdout } from 'ink'

function MyComponent() {
  const { stdout } = useStdout()
  // stdout.columns = 终端宽度，stdout.rows = 终端高度
  return <Text>终端大小：{stdout.columns}x{stdout.rows}</Text>
}
```

### 颜色和样式

```tsx
<Text color="green" bold>绿色加粗</Text>
<Text backgroundColor="yellow">黄底黑字</Text>
<Text dimColor>灰色（弱化显示）</Text>
<Text underline>下划线</Text>
```

### Focus 管理

```tsx
import { useFocus } from 'ink'

function Input() {
  const { isFocused } = useFocus()
  return (
    <Box borderStyle={isFocused ? "bold" : "single"}>
      <Text>当前 {isFocused ? "聚焦" : "未聚焦"}</Text>
    </Box>
  )
}
```

---

## 十、学习建议

1. **先理解 React 官方入门教程**（前 5 节足够）：组件、props、state、事件处理
2. **把 Ink 的 `<Box>`/`<Text>` 当 HTML 的 `<div>`/`<span>` 理解**
3. **从 `src/entrypoints/cli.tsx` → `src/replLauncher.tsx` → `src/screens/REPL.tsx` 追踪**：看组件怎么挂载的
4. **打开 `src/components/` 随便看几个组件**：`Message.tsx`、`TextInput.tsx` 等
