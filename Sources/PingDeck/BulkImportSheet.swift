import SwiftUI
import PingCore

/// 批量导入：每行一个目标，支持「目标」或「目标 备注」
struct BulkImportSheet: View {
    @EnvironmentObject private var model: PingDeckViewModel
    @State private var text = ""
    @State private var mode: ImportMode = .append
    @State private var defaultGroup = ""
    @State private var defaultColorTag: TargetColorTag?

    private var trimmedDefaultGroup: String {
        defaultGroup.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var preview: BulkImportParser.Result {
        model.previewBulkImport(
            text,
            mode: mode,
            defaultGroup: trimmedDefaultGroup,
            defaultColorTag: defaultColorTag
        )
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

            // 统一设置默认分组与默认颜色标签
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.bulkImportGroup)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        TextField(String(localized: L10n.targetEditorGroupPlaceholder), text: $defaultGroup)
                            .textFieldStyle(.roundedBorder)
                        if !model.availableGroups.isEmpty {
                            Menu {
                                Button(String(localized: L10n.groupDefaultName)) {
                                    defaultGroup = ""
                                }
                                Divider()
                                ForEach(model.availableGroups, id: \.self) { g in
                                    Button(g.isEmpty ? String(localized: L10n.groupDefaultName) : g) {
                                        defaultGroup = g
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.down.circle")
                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.bulkImportColorTag)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Button {
                            defaultColorTag = nil
                        } label: {
                            ZStack {
                                Circle()
                                    .strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1)
                                    .frame(width: 18, height: 18)
                                if defaultColorTag == nil {
                                    Circle()
                                        .fill(Color.primary.opacity(0.6))
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .help(String(localized: L10n.targetEditorNoColorTag))

                        ForEach(TargetColorTag.allCases, id: \.self) { tag in
                            Button {
                                defaultColorTag = tag
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(tag.color)
                                        .frame(width: 18, height: 18)
                                    if defaultColorTag == tag {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .frame(width: 12, height: 12)
                                        Circle()
                                            .stroke(Color.primary.opacity(0.8), lineWidth: 1.5)
                                            .frame(width: 22, height: 22)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .help(tag.localizedName)
                        }
                    }
                    .frame(height: 24)
                }
            }

            Text(L10n.importDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .frame(height: 170)
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
        let result = model.importTargets(
            text,
            mode: mode,
            defaultGroup: trimmedDefaultGroup,
            defaultColorTag: defaultColorTag
        )
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
