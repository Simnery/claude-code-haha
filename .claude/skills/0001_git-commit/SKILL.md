---
name: 0001_git-commit
description: cc-haha 项目 Git 提交规范。双远程（Gitee origin + GitHub upstream），Conventional Commits 格式，分支管理，推送流程。当用户要求提交代码、创建 commit、推送时调用。
allowed-tools: Bash Read Edit
---

**格式规则**：Skill 是模板，禁止硬编码项目特定值。用 `{平台}` `{远程URL}` 等占位符。

---

# Git 提交规范

## 远程仓库

> 配置文件: `.claude/config/config.example.json`（模板）→ 复制为 `config.local.json` 填入实际值

- **origin** (主推送): `https://gitee.com/Simnery/claude-code-haha` — 自己的 Gitee 镜像
- **github** (副推送): `https://github.com/Simnery/claude-code-haha.git` — 自己的 GitHub 仓库，同步推送
- **upstream** (拉取): `https://github.com/NanmiCoder/cc-haha.git` — GitHub 原仓库，只拉取同步
- **默认分支**: `main`

### 双推送机制（一次 push 同步到 Gitee + GitHub）

配置 origin 双 push URL：
```bash
# 查看当前配置
git remote -v

# 添加 GitHub 为第二 push URL（只需执行一次）
git remote set-url --add --push origin https://github.com/Simnery/claude-code-haha.git

# 此后 git push origin main 会自动同时推送到 Gitee 和 GitHub
```

> 配置文件 `.claude/config/config.local.json` 中需填 GitHub token（`github_token` 字段）。

### 推送单个平台

```bash
# 只推 Gitee
git push gitee main

# 只推 GitHub
git push github main
```

### 拉取上游（同步 GitHub 原仓库最新代码）

```bash
git fetch upstream
git merge upstream/main
# 或 rebase 方式：
git pull --rebase upstream main
```

首次推送需要认证。凭据管理器（`credential.helper = manager`）缓存后无需重复输入。若认证失败，参考 `.claude/config/config.local.json` 中的 token 直接推送。

### 推送 403 故障排查

- Gitee Token 需勾选 `projects` / `仓库` 权限
- GitHub 细粒度 Token (`github_pat_` 开头) 需: Repository access 选中目标仓库 + Permissions → Contents → Read and write
- GitHub Classic Token (`ghp_` 开头) 需勾选 `repo` 范围
- 检查 `.claude/config/config.local.json` 中 username 是否为**登录账号名**（非邮箱、非昵称）

## Commit Message 格式（Conventional Commits）

```
<type>: <简短描述>
```

常用 type：`feat` / `fix` / `docs` / `refactor` / `chore` / `test` / `release`

例：
- `fix: preserve Windows drive-root project identity`
- `feat: streamline workspace references from the file tree`
- `docs: 简化贡献指南，补充桌面端手工测试要求`

**扩展 trailers**（按需，参考 AGENTS.md）：
- `Constraint:` 外部约束
- `Rejected:` 考虑过但未采用的替代方案
- `Confidence:` low / medium / high
- `Scope-risk:` narrow / moderate / broad
- `Tested:` / `Not-tested:` 验证证据

## 提交流程

**核心规则：禁止自主 commit。只有用户明确说「提交」「commit」「推送」时才执行。**

0. **触发检查**：用户消息中必须含「提交」「commit」「推送」「push」等关键词，否则不执行 commit
1. `git status` 确认变更文件，列出给用户确认
2. `git add <指定文件>`（不 add 以下内容）：
   - `.env` 等敏感文件
   - `node_modules/`、`desktop/node_modules/`、`adapters/node_modules/`
   - `artifacts/`、`.omx/`、`desktop/src-tauri/target/`
   - 大文件（>10MB）
3. `git commit` — 仅用户确认后执行
4. **不自动 push**（需用户再次确认）

## 拉取上游 & 冲突处理

### 常规拉取（推荐先 fetch 查看差异，不直接 merge）

```bash
git fetch upstream
git log HEAD..upstream/main --oneline    # 先看有哪些新提交
git diff HEAD upstream/main --stat       # 看文件变更量
```

### 拉取前安全检查（必须执行）

在 merge 之前，**必须扫描上游是否动了我们的定制目录**：

```bash
# 检查上游是否新增/修改了我们的定制区域
git diff HEAD upstream/main --stat -- .claude/ 00_local_task/ sample/
```

| 上游改动范围 | 风险 | 处理 |
|-------------|------|------|
| 未动任何定制目录 | 安全 | 直接 merge |
| 动了 `.claude/`、`00_local_task/`、`sample/` | **需审查** | 逐文件检查是否有路径重名 |

### 重名冲突处理

如果上游新增了和本地定制**同路径**的文件：

| 场景 | 本地文件 | 上游文件 | 处理 |
|------|---------|---------|------|
| `.claude/skills/` 下有同名 skill | 我们的 SKILL.md | 上游的 SKILL.md | **保留我们版本**，将上游版本重命名为 `SKILL.upstream.md` 备份参考 |
| `.claude/memory/` 下有同名模板 | 我们的模板 | 上游的模板 | **保留我们版本**，上游版备份为 `_template.upstream.md` |
| `.claude/config/` 下有同名配置 | 我们的 config | 上游的 config | **保留我们版本**，上游版备份为 `config.upstream.json` |
| `00_local_task/` 有同名文件 | 我们的 guide | 上游的文件 | **保留我们版本** |
| `sample/` 有同名文件 | 我们的 .gitkeep | 上游的文件 | **保留我们版本** |
| 上游新增 `.claude/CLAUDE.md` | — | 上游的 CLAUDE.md | 备份为 `CLAUDE.upstream.md`，避免覆盖根目录 AGENTS.md |

**通用原则**：
- 我们的定制文件 → **永远保留**
- 上游同名文件 → 重命名为 `*.upstream.*` 备份，方便查看差异
- 上游在定制目录下新增的非同名文件 → 保留，与我们的文件共存
- 合并完成后 `git status` 确认无文件丢失

确认安全后合并：

```bash
git merge upstream/main
# 或 rebase：
git pull --rebase upstream main
```

### 已知冲突点 & 处理策略

| 冲突文件 | 原因 | 处理方式 |
|----------|------|---------|
| `.gitignore` | 上游用 `.claude/` 整目录 ignore；我们改为精细规则 | **保留我们的版本**，追加上游新增行 |
| `desktop/package-lock.json` | 上游 gitignore 屏蔽 | 遵循上游决策，不追踪 |

### 冲突解决流程

1. `git stash` 暂存本地未提交改动
2. 执行**拉取前安全检查**（见上方）
3. `git merge upstream/main`
4. 出现冲突时：
   - `.gitignore`：保留我们的精细规则 + `sample/` 规则 + `00_local_task/` 规则，追加上游新增行
   - 定制目录同名文件：保留我们版本，上游版重命名为 `*.upstream.*`
   - 其他文件：与上游保持一致
5. `git add` + `git commit`
6. `git stash pop`
7. `git push origin main`

## 远程修复（remote 丢失或错配时）

当前目标配置：
- origin → `https://gitee.com/Simnery/claude-code-haha`（含双 push URL）
- github → `https://github.com/Simnery/claude-code-haha.git`
- upstream → `https://github.com/NanmiCoder/cc-haha.git`

```bash
# 修正 origin
git remote set-url origin https://gitee.com/Simnery/claude-code-haha

# 添加 GitHub 为第二 push URL
git remote set-url --add --push origin https://github.com/Simnery/claude-code-haha.git

# 添加独立 github remote
git remote add github https://github.com/Simnery/claude-code-haha.git

# 添加上游
git remote add upstream https://github.com/NanmiCoder/cc-haha.git
```

验证配置：
```bash
git remote -v
# 应看到:
# origin  https://gitee.com/Simnery/claude-code-haha (fetch)
# origin  https://gitee.com/Simnery/claude-code-haha (push)
# origin  https://github.com/Simnery/claude-code-haha.git (push)
# github  https://github.com/Simnery/claude-code-haha.git (fetch)
# github  https://github.com/Simnery/claude-code-haha.git (push)
# upstream https://github.com/NanmiCoder/cc-haha.git (fetch)
# upstream https://github.com/NanmiCoder/cc-haha.git (push)
```

## Amend 合并提交

**触发条件**：用户明确说「合并」「amend」「追加到上次提交」时执行。

**流程**：
1. 确认未推送或用户知晓需 force push
2. `git add <文件>`
3. `git commit --amend`（复用原 message；如用户要求改 message 则调整）
4. `git push origin main --force-with-lease`
5. 若 `--force-with-lease` 被 GitHub 拒（stale info），对 GitHub remote 单独用 `--force`：
   ```bash
   git push github main --force
   ```
   Gitee 通常接受 `--force-with-lease`，GitHub 在跨 remote 场景可能需 `--force`。amend 后务必确认两侧都推送成功。

## GitHub Actions 镜像（自动备份）

`.github/workflows/mirror.yml` 可在 GitHub 侧自动镜像到 Gitee：

```yaml
name: Mirror to Gitee
on:
  push:
    branches: [main]
jobs:
  mirror:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Push to Gitee
        run: |
          git remote add gitee https://${{ secrets.GITEE_USERNAME }}:${{ secrets.GITEE_PASSWORD }}@gitee.com/Simnery/claude-code-haha.git
          git push gitee main:main --force
```

需要在 GitHub 仓库 Settings → Secrets 中配置 `GITEE_USERNAME` 和 `GITEE_PASSWORD`（Gitee token）。

## 禁止事项

- **禁止自主 commit**：用户没明确说「提交」「commit」时，只改代码不提交
- 不 skip hooks（--no-verify）
- 不 force push 到 main（**例外**：amend 合并提交时可用 `--force-with-lease`）
- 不提交 `.env`、credentials、API key
- 不提交构建产物（artifacts/、.omx/、target/、node_modules/）
