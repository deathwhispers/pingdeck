#!/usr/bin/env bash
# 首次推送到 GitHub：个人账号 / pingman / 公开仓库
#
#   bash scripts/publish.sh
#
# 前提：已安装 gh 并完成 `gh auth login`
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> 检查 GitHub 登录状态"
gh auth status

echo "==> 初始化仓库"
git init -b main
git add -A
echo "--- 待提交文件（确认 .build/ 与 dist/ 未被暂存）---"
git status --short

echo "==> 提交"
git commit -F - <<'MSG'
feat: BatchPing 首个版本

macOS 批量 Ping 工具（SwiftUI），用于网络调试与运维监控。

- PingCore：ping 输出解析、并发受限的调度引擎、配置持久化、CSV 导出
- 界面：目标增删改、开始/停止/刷新/清空、排序、深色模式、导出 CSV
- 打包：xcodebuild + 脚本组装 .app/.dmg，GitHub Actions 自动构建与可选公证

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
MSG

echo "==> 创建公开仓库并推送"
gh repo create pingman --public --source=. --remote=origin --push

echo "==> 结果"
git log --oneline -3
git remote -v
git ls-remote --heads origin
echo "仓库地址：https://github.com/$(gh api user --jq .login)/pingman"
