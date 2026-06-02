# Task Index

> cc-haha 开发任务状态总览

## Active

| id | status | owner | last_update | task_file |
|----|--------|-------|-------------|-----------|

## Paused

| id | status | owner | last_update | task_file |
|----|--------|-------|-------------|-----------|

## Done

| id | status | owner | last_update | task_file |
|----|--------|-------|-------------|-----------|

---
维护规则：
1. 任务新建/暂停/恢复/完成时，更新对应分区条目。
2. `id` 与 `00_local_task/tasks/{id}/` 文件夹名一致。
3. `status` 仅使用 `active` / `paused` / `done`。
4. `task_file` 列链接：`tasks/{id}/{id}.md`（相对 `00_local_task/`）。
