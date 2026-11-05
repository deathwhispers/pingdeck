import SwiftUI
import PingCore

/// 批量导入：每行一个目标，支持「目标」或「目标 备注」
struct BulkImportSheet: View {
    @EnvironmentObject private var model: BatchPingViewModel
    @State private var text = ""

    private var preview: BulkImportParser.Result {
        model.previewBulkImport(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("批量导入目标")
                .font(.headline)

            Text("每行一个目标，可写成「目标」或「目标 备注」。以 # 开头的行会被忽略；重复或格式非法的行会被跳过并列出原因。")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .frame(height: 190)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.4))
                )

            summary

            HStack {
                Spacer()
                Button("取消") { model.closeSheet() }
                Button("导入 \(preview.entries.count) 个目标") { importNow() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(preview.entries.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 540)
    }

    @ViewBuilder
    private var summary: some View {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text("示例：\n8.8.8.8  Google DNS\n1.1.1.1  Cloudflare\n# 下面这行是注释\n192.168.1.1  网关")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("可导入 \(preview.entries.count) 个，跳过 \(preview.rejected.count) 个")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !preview.rejected.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(preview.rejected, id: \.line) { item in
                                Text("第 \(item.line) 行「\(item.text)」：\(item.reason)")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 70)
                }
            }
        }
    }

    private func importNow() {
        let result = model.importTargets(text)
        model.closeSheet()
        var message = "已导入 \(result.entries.count) 个目标。"
        if !result.rejected.isEmpty {
            message += "跳过 \(result.rejected.count) 个（重复或格式非法）。"
        }
        model.alert = AppAlert(title: "批量导入完成", message: message)
    }
}
