# PingDeck 协作规则

本文件是本项目的分支与提交规则，所有改动（包括 AI 协作）都必须遵守。

## 分支

- `main` 受保护，禁止直接 commit / push，所有改动必须通过 Pull Request 合并。
- 按改动类型建立分支：
  - `fix/<slug>`：bug 修复
  - `feat/<slug>`：新功能
  - `perf/<slug>`：性能优化
  - `docs/<slug>`、`chore/<slug>`、`refactor/<slug>`：文档、构建/杂项、重构
- 分支上可以有多个 commit（允许 WIP）；修复或功能全部完成后，再创建 PR。

## 提交信息

- 使用 Conventional Commits：`feat:`、`fix:`、`perf:`、`docs:`、`chore:`、`refactor:`、`test:`、`ci:`。
- PR 标题同样使用该格式；合并到 main 时采用 **squash merge**，PR 标题即 main 上的提交信息。
- 合并后的每个 main 提交必须是一个完整、可独立构建、测试通过的变更，可作为版本记录。

## Pull Request

- 一个 PR 只做一件事；描述写清「改了什么、为什么、如何验证」。
- 合并前必须：
  - `swift build` 通过
  - `swift test` 全部通过
  - CI 的 `Build & Package` 检查通过
- 合并方式：**squash merge**（约定优于配置，GitHub 未强制）。
- 不要 force push 已有 PR 分支之外的分支；PR 分支需要更新时优先 rebase 到最新 `main`。

## 发布

1. 在独立 PR 中更新 `VERSION`、`CHANGELOG.md` 与 README 版本徽章；
2. squash 合并到 `main`；
3. 从 `main` 手动触发 Actions → **Build** → **Run workflow**，填写版本号；
4. tag 打在 main 的发布提交上，Release 附带 `PingDeck-<版本>.dmg`。

## 禁止

- 直接向 `main` 提交或 force push `main`
- 在 `main` 上保留未完成 / WIP 提交
- 在同一个 PR 中夹带与本 PR 无关的改动
