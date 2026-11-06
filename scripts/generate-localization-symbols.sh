#!/usr/bin/env bash
# 从 String Catalog 生成类型安全的 L10n 符号。
#
# 修改 Sources/PingDeck/Resources/Localizable.xcstrings 后重新运行本脚本。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CATALOG="$ROOT/Sources/PingDeck/Resources/Localizable.xcstrings"
OUTPUT="$ROOT/Sources/PingDeck/Generated/L10n.swift"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

xcrun xcstringstool generate-symbols "$CATALOG" --output-directory "$TMP" --language swift
python3 "$ROOT/scripts/transform-localization-symbols.py" \
  "$TMP/GeneratedStringSymbols_Localizable.swift" \
  "$OUTPUT"

echo "已生成 $OUTPUT"
