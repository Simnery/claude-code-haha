---
name: use-project-config
description: 不要依赖缓存，每次适配当前项目现状，以 .claude/config/ 中的实际值为准
type: feedback
---

优先读取项目配置文件，而不是依赖会话记忆。

**Why:** 用户明确指出后续操作应参考当前项目的 `.claude/config/config.local.json` 等配置文件，避免用错 URL、凭据或其他项目特定值。

**How to apply:**
- 涉及远程 URL、凭据、项目路径时，先读 `.claude/config/config.local.json` 确认实际值
- 不要跨会话假设项目配置状态
- 每次做 git remote 操作前验证 `git remote -v`
