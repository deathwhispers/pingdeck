# 参与 PingDeck 开发

感谢参与！本文说明本项目的分支、提交与发布规则。AI 协作工具请同时参考 [CLAUDE.md](CLAUDE.md)。

## 分支规则

`main` 分支受保护，**不允许直接提交**，所有改动都必须通过 Pull Request 合并。

按改动类型从最新的 `main` 建分支：

| 类型 | 分支命名 | 示例 |
| --- | --- | --- |
| bug 修复 | `fix/<slug>` | `fix/start-no-response` |
| 新功能 | `feat/<slug>` | `feat/export-formats` |
| 性能优化 | `perf/<slug>` | `perf/ui-refresh-throttle` |
| 文档 | `docs/<slug>` | `docs/commit-rules` |
| 构建 / 杂项 | `chore/<slug>` | `chore/bump-version` |
| 重构 | `refactor/<slug>` | `refactor/engine-scheduling` |

分支上可以有多个 commit（允许 WIP）；等修复或功能全部完成后再创建 PR。

## 工作流

```bash
# 1. 从最新 main 建分支
git checkout main
git pull --ff-only
git checkout -b feat/my-feature

# 2. 开发并按需提交（可以多次提交）
git add -A
git commit -m "feat: 描述这次改动"

# 3. 本地验证
swift build
swift test

# 4. 推送并创建 PR
git push -u origin feat/my-feature
gh pr create --fill --base main

# 5. CI 通过后 squash 合并（约定，不在 GitHub 设置里强制）
gh pr merge --squash --delete-branch
```

## 提交信息

使用 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/) 格式：

```
<type>: <简要描述>

<可选的正文：为什么这样改、有什么影响>
```

常用 type：`feat`、`fix`、`perf`、`docs`、`chore`、`refactor`、`test`、`ci`。

PR 标题同样使用该格式。合并时采用 **squash merge**，因此 PR 标题会成为 `main` 上的提交信息。

## PR 检查清单

- [ ] 一个 PR 只做一件事，没有夹带无关改动
- [ ] PR 标题符合 Conventional Commits
- [ ] `swift build` 通过
- [ ] `swift test` 全部通过
- [ ] CI 的 `Build & Package` 检查通过
- [ ] 面向用户的变更已更新 `CHANGELOG.md`

`main` 上的每个提交都必须是完整、可独立构建、测试通过的变更，可以作为一个版本记录。

## 发布流程

1. 在独立 PR 中更新 `VERSION`、`CHANGELOG.md` 与 README 版本徽章，按常规流程合并；
2. 从 `main` 手动触发 Actions → **Build** → **Run workflow**，填写版本号（如 `0.0.3`）；
3. 流水线跑完后，Releases 页面会出现对应 tag，附带 `PingDeck-<版本>.dmg`。

## 本地开发

构建、测试与打包命令见 [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)。
