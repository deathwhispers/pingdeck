import SwiftUI
import PingCore

/// 添加目标弹窗：支持单行、多行、网段、带备注/分组/颜色标签全量录入并立即重新开跑
struct AddTargetsSheet: View {
    @EnvironmentObject private var model: PingDeckViewModel
    @State private var text: String = ""
    @State private var defaultGroup = ""
    @State private var defaultColorTag: TargetColorTag?

    private var trimmedDefaultGroup: String {
        defaultGroup.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var preview: BulkImportParser.Result {
        model.previewBulkImport(
            text,
            mode: .replace,
            defaultGroup: trimmedDefaultGroup,
            defaultColorTag: defaultColorTag
        )
    }

    init() {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L10n.toolbarAdd)
                    .font(.headline)
                Spacer()
                if !text.isEmpty {
                    Button(String(localized: L10n.toolbarClear)) {
                        text = ""
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }

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
                .frame(height: 190)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.4))
                )

            summary

            HStack {
                Spacer()
                Button(String(localized: L10n.commonCancel)) { model.closeSheet() }
                Button(confirmTitle) {
                    importAndStart()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(preview.entries.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 560)
        .onAppear {
            if text.isEmpty && !model.targets.isEmpty {
                text = model.exportTargetsAsEditableText()
            }
        }
    }

    private var confirmTitle: String {
        preview.entries.isEmpty
            ? String(localized: L10n.commonSave)
            : "\(String(localized: L10n.commonSave)) (\(preview.entries.count))"
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
                    .frame(height: 60)
                }
            }
        }
    }

    private func importAndStart() {
        let result = model.replaceAllTargetsAndStart(
            text,
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
