import SwiftUI
import PingCore

struct TargetEditorSheet: View {
    @EnvironmentObject private var model: PingDeckViewModel
    @State private var host: String
    @State private var note: String
    @State private var enabled: Bool
    @State private var group: String
    @State private var colorTag: TargetColorTag?
    @State private var validationError: String?

    private let draft: TargetEditorDraft
    private let onSave: (String, String, Bool, String, TargetColorTag?) -> Void

    init(draft: TargetEditorDraft, onSave: @escaping (String, String, Bool, String, TargetColorTag?) -> Void) {
        self.draft = draft
        self.onSave = onSave
        _host = State(initialValue: draft.host)
        _note = State(initialValue: draft.note)
        _enabled = State(initialValue: draft.enabled)
        _group = State(initialValue: draft.group)
        _colorTag = State(initialValue: draft.colorTag)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(draft.isNew ? L10n.editorTitleAdd : L10n.editorTitleEdit)
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text(draft.isNew ? L10n.editorHostLabelRange : L10n.editorHostLabelSingle)
                    .font(.subheadline)
                TextField(
                    draft.isNew
                        ? String(localized: L10n.editorHostPlaceholderRange)
                        : String(localized: L10n.editorHostPlaceholderSingle),
                    text: $host
                )
                .textFieldStyle(.roundedBorder)
                if let validationError {
                    Text(validationError)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if let preview, preview.entries.count > 1 {
                    Text(L10n.editorPreviewCount(preview.entries.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.editorNote)
                    .font(.subheadline)
                TextField(String(localized: L10n.editorNotePlaceholder), text: $note)
                    .textFieldStyle(.roundedBorder)
            }

            // 分组选择与输入
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.targetEditorGroup)
                    .font(.subheadline)
                HStack(spacing: 8) {
                    TextField(String(localized: L10n.targetEditorGroupPlaceholder), text: $group)
                        .textFieldStyle(.roundedBorder)

                    if !model.availableGroups.isEmpty {
                        Menu {
                            ForEach(model.availableGroups, id: \.self) { g in
                                Button(g.isEmpty ? String(localized: L10n.groupDefaultName) : g) {
                                    group = g
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.down.circle")
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        .help(String(localized: L10n.targetEditorGroup))
                    }
                }
            }

            // 颜色标签调色板选择器
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.targetEditorColorTag)
                    .font(.subheadline)
                HStack(spacing: 10) {
                    Button {
                        colorTag = nil
                    } label: {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1)
                                .frame(width: 20, height: 20)
                            if colorTag == nil {
                                Circle()
                                    .fill(Color.primary.opacity(0.6))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .help(String(localized: L10n.targetEditorNoColorTag))

                    ForEach(TargetColorTag.allCases, id: \.self) { tag in
                        Button {
                            colorTag = tag
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(tag.color)
                                    .frame(width: 20, height: 20)
                                if colorTag == tag {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 14, height: 14)
                                    Circle()
                                        .stroke(Color.primary.opacity(0.8), lineWidth: 1.5)
                                        .frame(width: 24, height: 24)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .help(tag.localizedName)
                    }
                }
                .padding(.vertical, 2)
            }

            Toggle(String(localized: L10n.editorEnabled), isOn: $enabled)

            HStack {
                Spacer()
                Button(String(localized: L10n.commonCancel)) { model.closeSheet() }
                Button(String(localized: L10n.commonSave)) { save() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    private var trimmedHost: String {
        host.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedGroup: String {
        group.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 添加模式下实时预览网段展开结果
    private var preview: BulkImportParser.Result? {
        guard draft.isNew, !trimmedHost.isEmpty else { return nil }
        return BulkImportParser.parse(
            host: trimmedHost,
            note: trimmedNote,
            group: trimmedGroup,
            colorTag: colorTag,
            existing: Set(model.targets.map { $0.host.lowercased() })
        )
    }

    private func save() {
        if trimmedHost.isEmpty {
            validationError = TargetValidationIssue.empty.message
            return
        }

        if draft.isNew {
            let result = BulkImportParser.parse(
                host: trimmedHost,
                note: trimmedNote,
                group: trimmedGroup,
                colorTag: colorTag,
                existing: Set(model.targets.map { $0.host.lowercased() })
            )
            guard !result.entries.isEmpty else {
                validationError = result.rejected.first?.reason.message
                    ?? String(localized: L10n.alertAddFailedDefaultMessage)
                return
            }
            validationError = nil
            onSave(trimmedHost, trimmedNote, enabled, trimmedGroup, colorTag)
            return
        }

        // 编辑模式只允许单个目标，避免「一个目标变成多个」的歧义
        let result = BulkImportParser.parse(host: trimmedHost, note: "", existing: [])
        guard result.entries.count == 1, result.entries[0].host == trimmedHost else {
            validationError = String(localized: L10n.editorRangeNotAllowed)
            return
        }
        validationError = nil
        onSave(trimmedHost, trimmedNote, enabled, trimmedGroup, colorTag)
    }
}
