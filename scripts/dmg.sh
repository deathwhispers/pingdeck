#!/usr/bin/env bash
# 基于已生成的 .app 制作 DMG
#
# 环境变量：
#   APP_PATH   输入 .app 路径，默认 dist/PingDeck.app
#   DMG_PATH   输出 DMG 路径，默认 dist/PingDeck-<版本号>.dmg
#   VERSION    版本号，默认读取仓库根目录的 VERSION 文件
#   DEVELOPER_ID_APPLICATION  设置后用该证书签名 DMG
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-$(tr -d '[:space:]' < "$ROOT/VERSION" 2>/dev/null || echo 0.0.0)}"
APP="${APP_PATH:-$ROOT/dist/PingDeck.app}"
DMG="${DMG_PATH:-$ROOT/dist/PingDeck-$VERSION.dmg}"
STAGE="$ROOT/dist/dmg-stage"

if [[ ! -d "$APP" ]]; then
  echo "未找到应用包：$APP，请先执行 make app" >&2
  exit 1
fi

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create -volname "PingDeck" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  codesign --force --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$DMG"
  echo "已使用证书签名：$DEVELOPER_ID_APPLICATION"
fi

echo "已生成镜像：$DMG"
