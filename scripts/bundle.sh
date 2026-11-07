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

# 复制 SwiftPM 生成的本地化资源包
BIN_DIR="$(cd "$(dirname "$BIN")" && pwd -P)"
RESOURCE_BUNDLE_NAME="PingDeck_PingDeck.bundle"
RESOURCE_BUNDLE="$(find "$BIN_DIR" -maxdepth 1 -name "$RESOURCE_BUNDLE_NAME" -print -quit)"
if [[ -z "$RESOURCE_BUNDLE" ]]; then
  echo "未找到本地化资源包 $RESOURCE_BUNDLE_NAME（目录：$BIN_DIR）" >&2
  exit 1
fi
cp -R "$RESOURCE_BUNDLE" "$APP/Contents/Resources/"

# 生成浅色/深色图标：从 docs/images 的源图裁出透明圆角，再打包成两个 .icns
ICON_BUILD="$ROOT/.build/AppIcon"
ICON_LIGHT_SRC="$ROOT/docs/images/light_icon.png"
ICON_DARK_SRC="$ROOT/docs/images/dark_icon.png"
rm -rf "$ICON_BUILD"

if command -v swift >/dev/null 2>&1 \
   && command -v iconutil >/dev/null 2>&1 \
   && [[ -f "$ICON_LIGHT_SRC" && -f "$ICON_DARK_SRC" ]] \
   && swift "$ROOT/scripts/prepare-icon.swift" "$ICON_LIGHT_SRC" "$ICON_DARK_SRC" "$ICON_BUILD" >/dev/null 2>&1; then
  ICONSET="$ICON_BUILD/AppIcon.iconset"
  variants=(
    "icon_16x16.png 16"
    "icon_16x16@2x.png 32"
    "icon_32x32.png 32"
    "icon_32x32@2x.png 64"
    "icon_128x128.png 128"
    "icon_128x128@2x.png 256"
    "icon_256x256.png 256"
    "icon_256x256@2x.png 512"
    "icon_512x512.png 512"
  )

  # 默认 Finder 图标：浅色，最大 512px（1024 由系统缩放，避免 icns 过大）
  rm -rf "$ICONSET"
  mkdir -p "$ICONSET"
  for spec in "${variants[@]}"; do
    name="${spec%% *}"
    px="${spec##* }"
    out="$ICONSET/$name"
    sips -z "$px" "$px" "$ICON_BUILD/icon-light-1024.png" --out "$out" >/dev/null
    if command -v pngcrush >/dev/null 2>&1; then
      pngcrush -q -ow "$out" >/dev/null 2>&1 || true
    fi
  done
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

  # 运行时图标：256px 足够 Dock 与 App Switcher 使用
  for appearance in Light Dark; do
    lower="$(echo "$appearance" | tr '[:upper:]' '[:lower:]')"
    out="$APP/Contents/Resources/AppIcon-$appearance.png"
    sips -z 256 256 "$ICON_BUILD/icon-$lower-1024.png" --out "$out" >/dev/null
    if command -v pngcrush >/dev/null 2>&1; then
      pngcrush -q -ow "$out" >/dev/null 2>&1 || true
    fi
  done

  rm -rf "$ICON_BUILD"
  echo "已生成应用图标（浅色 / 深色）"
else
  rm -rf "$ICON_BUILD"
  echo "图标生成失败，使用系统默认图标"
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
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>en</string>
        <string>zh-Hans</string>
        <string>ja</string>
    </array>
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
  # 公证要求 Hardened Runtime + 时间戳；先签嵌套资源包再签 App
  codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" \
    "$APP/Contents/Resources/$RESOURCE_BUNDLE_NAME"
  codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$APP"
  echo "已使用证书签名：$DEVELOPER_ID_APPLICATION"
else
  # 本地开发用 ad-hoc 签名，避免 Gatekeeper 判定为损坏
  codesign --force --sign - "$APP/Contents/Resources/$RESOURCE_BUNDLE_NAME" >/dev/null 2>&1 || true
  codesign --force --sign - "$APP" >/dev/null 2>&1 || true
  echo "已使用 ad-hoc 签名（正式分发请设置 DEVELOPER_ID_APPLICATION）"
fi

echo "已生成应用包：$APP"
echo "运行：open \"$APP\""
