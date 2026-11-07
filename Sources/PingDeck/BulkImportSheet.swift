import SwiftUI
import PingCore

/// 批量导入：每行一个目标，支持「目标」或「目标 备注」
struct BulkImportSheet: View {
    @EnvironmentObject private var model: PingDeckViewModel
    @State private var text = ""
    @State private var mode: ImportMode = .append

    private var preview: BulkImportParser.Result {
        model.previewBulkImport(text, mode: mode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.importTitle)
                .font(.headline)

            Picker(String(localized: L10n.importMode), selection: $mode) {
                ForEach(ImportMode.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text(modeHint)
                .font(.caption)
                .foregroundStyle(mode == .replace && !model.targets.isEmpty ? .red : .secondary)

            Text(L10n.importDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .frame(height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.4))
                )

            summary

            HStack {
                Spacer()
                Button(String(localized: L10n.commonCancel)) { model.closeSheet() }
                Button(confirmTitle) { importNow() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(preview.entries.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 540)
    }

    private var modeHint: String {
        switch mode {
        case .append:
            return String(localized: L10n.importModeAppendDescription(model.targets.count))
        case .replace:
            return model.targets.isEmpty
                ? String(localized: L10n.importModeReplaceDescriptionEmpty)
                : String(localized: L10n.importModeReplaceDescriptionWithCount(model.targets.count))
        }
    }

    private var confirmTitle: String {
        switch mode {
        case .append: return String(localized: L10n.importConfirmAppend(preview.entries.count))
        case .replace: return String(localized: L10n.importConfirmReplace(preview.entries.count))
        }
    }

    @ViewBuilder
    private var summary: some View {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(L10n.importExample)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.importSummary(preview.entries.count, preview.rejected.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !preview.rejected.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(preview.rejected, id: \.line) { item in
                                Text(String(localized: L10n.importRejectedLine(item.line, item.text, item.reason.message)))
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
        let result = model.importTargets(text, mode: mode)
        model.closeSheet()
        var message = String(localized: L10n.alertImportCompletedMessage(result.entries.count))
        if !result.rejected.isEmpty {
            message += String(localized: L10n.alertImportCompletedSkipped(result.rejected.count))
        }
        model.alert = AppAlert(
            title: String(localized: L10n.alertImportCompletedTitle),
            message: message
        )
    }
}
