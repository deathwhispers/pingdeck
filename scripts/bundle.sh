#!/usr/bin/env bash
# 将构建产物组装成可双击运行的 .app
#
# 环境变量：
#   BIN_PATH              可执行文件路径，默认 .build/release/PingDeck
#   APP_PATH              输出的 .app 路径，默认 dist/PingDeck.app
#   VERSION               应用版本号，默认读取仓库根目录的 VERSION 文件
#   DEVELOPER_ID_APPLICATION  设置后用该证书签名（CI 公证流程使用），否则 ad-hoc 签名
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${BIN_PATH:-$ROOT/.build/release/PingDeck}"
APP="${APP_PATH:-$ROOT/dist/PingDeck.app}"
VERSION="${VERSION:-$(tr -d '[:space:]' < "$ROOT/VERSION" 2>/dev/null || echo 0.0.0)}"

if [[ ! -x "$BIN" ]]; then
  echo "未找到构建产物：$BIN" >&2
  echo "请先执行 swift build -c release，或设置 BIN_PATH 指向 xcodebuild 的产物" >&2
  exit 1
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/PingDeck"

# 生成图标（脚本化渲染，仓库里不放二进制资源）
if command -v swift >/dev/null 2>&1 && command -v iconutil >/dev/null 2>&1; then
  ICONSET="$ROOT/.build/AppIcon.iconset"
  if swift "$ROOT/scripts/make-icon.swift" "$ICONSET" >/dev/null 2>&1 \
     && iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"; then
    rm -rf "$ICONSET"
    echo "已生成应用图标"
  else
    echo "图标生成失败，使用系统默认图标"
    rm -f "$APP/Contents/Resources/AppIcon.icns"
  fi
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>PingDeck</string>
    <key>CFBundleDisplayName</key>
    <string>PingDeck</string>
    <key>CFBundleIdentifier</key>
    <string>com.pingdeck.app</string>
    <key>CFBundleExecutable</key>
    <string>PingDeck</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.4</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  # 公证要求 Hardened Runtime + 时间戳
  codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$APP"
  echo "已使用证书签名：$DEVELOPER_ID_APPLICATION"
else
  # 本地开发用 ad-hoc 签名，避免 Gatekeeper 判定为损坏
  codesign --force --sign - "$APP" >/dev/null 2>&1 || true
  echo "已使用 ad-hoc 签名（正式分发请设置 DEVELOPER_ID_APPLICATION）"
fi

echo "已生成应用包：$APP"
echo "运行：open \"$APP\""
