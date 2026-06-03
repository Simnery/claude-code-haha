# 01_07 — Desktop 桌面端

> 覆盖文件：`desktop/`, `src/server/`

---

## 一、架构概览

```
┌─────────────────────────────────────────────┐
│                  Tauri Shell                  │
│  ┌──────────────┐  ┌──────────────────────┐ │
│  │  Rust Backend │  │  WebView (React/TSX) │ │
│  │  (src-tauri/) │  │  (desktop/src/)      │ │
│  └──────┬───────┘  └──────────┬───────────┘ │
│         │ Tauri IPC            │              │
│         └──────────┬───────────┘              │
│                    │                          │
│         ┌──────────▼───────────┐              │
│         │   Sidecar Process     │              │
│         │   (Claude CLI 子进程)  │              │
│         └──────────────────────┘              │
└─────────────────────────────────────────────┘
```

---

## 二、Tauri 后端 (`desktop/src-tauri/`)

### 技术栈
- **语言**: Rust
- **框架**: Tauri v2
- **IPC**: Tauri Commands (invoke/emit)

### 核心职责
- 窗口管理 (创建/销毁/大小/位置)
- 系统托盘 (tray icon + 菜单)
- 全局快捷键
- 文件系统访问 (沙箱内)
- Sidecar 进程管理 (启动/监控/关闭 CLI 子进程)
- 自动更新 (Tauri updater)
- 原生通知

---

## 三、WebView 前端 (`desktop/src/`)

### 技术栈
- **语言**: TypeScript/React
- **渲染**: Ink → WebView 渲染适配
- **构建**: Bun + bundled builds

### 核心页面
- 主聊天界面 (REPL 渲染)
- 设置页面 (模型切换/权限配置)
- 会话管理 (新建/恢复/删除)
- 插件管理界面
- 快捷键设置

### 与 CLI 进程通信
- **WebView → Sidecar**: Tauri IPC → Rust → stdin/stdout
- **Sidecar → WebView**: stdout JSON → Rust → Tauri event → WebView
- 使用结构化 JSON 消息协议

---

## 四、CLI Sidecar 进程

### 启动
```
桌面端启动 → Tauri Rust 后台 → spawn CLI 子进程
CLI: bun ./src/entrypoints/cli.tsx --desktop
```

### 协议
- stdin: 用户输入 / 命令
- stdout: JSON 结构化输出 (渲染/事件)
- 信号处理: SIGTERM → 优雅关闭

### 防止孤儿进程 (Bug Fix)
- `d222b47` / `4b3eb16`: 确保桌面预览关闭时正确清理 CLI sidecar

---

## 五、服务端 (`src/server/`)

### 功能
- **Localhost HTTP Server**: 为桌面 WebView 提供 API
- RESTful 接口:
  - `/api/conversation` — 会话 CRUD
  - `/api/settings` — 设置读写
  - `/api/mcp` — MCP 配置
  - `/api/bridge` — Bridge 模式

### 会话服务 (`conversationService.ts`)
- 会话列表/创建/删除
- 会话搜索 (按标题/日期)
- Transcript 导出
- 环境变量管理 (`CLAUDE_CODE_MODEL_CONTEXT_WINDOWS` 等)

### Provider 预设 (`providerPresets.json`)
- 预配置的第三方 API 提供商:
  - DeepSeek (deepseek-v4-pro, deepseek-v4-flash)
  - Zhipu GLM (glm-5.1, glm-4.5-air)
  - Kimi (kimi-k2.6)
  - MiniMax (MiniMax-M2.7)
  - OpenRouter (可自定义)
  - LM Studio / Ollama (本地模型)

---

## 六、IPC 通信模式

### 请求-响应
```
WebView: invoke('api_call', { method: 'GET', path: '/settings' })
  → Rust: handle_api_call()
    → HTTP localhost:PORT → CLI Server
    → 返回 JSON
  ← WebView 接收结果
```

### 事件流
```
CLI stdout JSON event
  → Rust: 解析 + 转发 emit('claude_event', payload)
    → WebView: listen('claude_event', ...)
      → React state 更新 → UI 重渲染
```

---

## 七、适配器层 (`adapters/`)

独立的 TypeScript 项目，处理 IM 平台集成：
- 消息格式转换
- 平台特定协议适配
- 类型安全 bridge

---

## 八、构建产物
- `desktop/src-tauri/target/` — Rust 编译产物
- `artifacts/` — 打包后的安装程序
- `.omx/` — 中间构建文件
