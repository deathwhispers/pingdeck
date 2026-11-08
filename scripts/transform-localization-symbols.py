#!/usr/bin/env python3
"""把 xcstringstool 生成的 LocalizedStringResource extension 转成 L10n 命名空间。

SwiftPM 会为 .xcstrings 生成符号文件，但在 `swift test` 重新编译可执行
target 时不会包含该文件，导致生产代码引用生成符号时测试构建失败。
这里显式生成并纳入源码，保证 build 与 test 使用同一份符号。
"""

import pathlib
import sys

source_path = pathlib.Path(sys.argv[1])
output_path = pathlib.Path(sys.argv[2])

lines = source_path.read_text(encoding="utf-8").splitlines()
start = next(
    index for index, line in enumerate(lines)
    if "extension LocalizedStringResource {" in line
)
end = max(index for index, line in enumerate(lines) if line.strip() == "}")

body = "\n".join(lines[start + 1:end]).replace(
    "resourceBundleDescription", "l10nBundleDescription"
).replace(
    "bundle: l10nBundleDescription)",
    "locale: locale, bundle: l10nBundleDescription)"
)

output = f"""// Auto-generated from Sources/PingDeck/Resources/Localizable.xcstrings.
// Run scripts/generate-localization-symbols.sh after changing the catalog.
// Do not edit manually.

import Foundation

private nonisolated let l10nBundle = Foundation.Bundle.module
private nonisolated let l10nBundleDescription = LocalizedStringResource.BundleDescription.atURL(l10nBundle.bundleURL)

enum L10n {{
    /// 运行时语言；切换语言时由 ViewModel 更新
    nonisolated(unsafe) static var locale: Locale = .current
{body}
}}
"""

output_path.parent.mkdir(parents=True, exist_ok=True)
output_path.write_text(output, encoding="utf-8")
