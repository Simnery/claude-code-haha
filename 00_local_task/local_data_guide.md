# 00_local_task — 本地开发任务数据区

> 位于项目根目录，不在 `.claude/` 下，避免保护区权限弹窗。

## 目录功能

| 类型 | 路径 | Git | 用途 |
|------|------|-----|------|
| 规则/模板 | `.claude/memory/tasks/` | 仅本地 | `_template.md`、`task_tracking_rules.md`、索引模板 |
| 任务数据 | `00_local_task/tasks/{任务ID}/` | 排除 | 主文档、附件、脚本 |
| 任务索引 | `00_local_task/task_index.md` | 排除 | 状态总览 |

## 创建任务

1. 在 `tasks/` 下创建文件夹 `{任务ID}/`，内含 `{任务ID}.md`（模板：`.claude/memory/tasks/_template.md`）
2. `{任务ID}` = `{日期}_{类别}_{简要描述}`，**文件夹名与 .md 文件名相同**
3. 若 `task_index.md` 缺失，从 `.claude/memory/tasks/task_index.template.md` 复制
4. 新建任务写入索引：`id | status | owner | last_update | task_file`

## 进度更新（强制执行）

每完成一个子步骤，**先更新主文档再继续**（6 处，顺序不变）：

| # | 位置 | 操作 |
|---|------|------|
| 1 | `> **更新时间**` | 刷新为当前时间 |
| 2 | `## TL;DR` | 一句话当前状态 |
| 3 | `## 进度表` | 完成行 `✅`，下一行 `⏳` |
| 4 | `## 当前操作` | 下一步 checklist |
| 5 | `## 已完成操作` | 追加刚完成项 |
| 6 | `## 进度日志` | 追加一行 |

原则：文档优先、即时更新、**进度表为唯一状态来源**、失败也记录、会话结束前文档最新。

## 任务目录结构

```
00_local_task/
├── local_data_guide.md          ← 本文件
├── task_index.md                ← 索引（本地）
└── tasks/
    └── {任务ID}/
        ├── {任务ID}.md          ← 主文档（唯一入口）
        ├── data/
        ├── outputs/
        └── notes/
```

## 恢复任务

```
继续 {任务ID}
```

恢复后标准动作：
1. 打开 `00_local_task/tasks/{任务ID}/{任务ID}.md`
2. 读 `## TL;DR`、`## 当前操作`、`## 进度日志` 最新 3 行
3. 直接继续，不追问、不翻旧对话
