import SwiftUI
import PingCore

struct TargetEditorSheet: View {
    @EnvironmentObject private var model: PingDeckViewModel
    @State private var host: String
    @State private var note: String
    @State private var enabled: Bool
    @State private var validationError: String?

    private let draft: TargetEditorDraft
    private let onSave: (String, String, Bool) -> Void

    init(draft: TargetEditorDraft, onSave: @escaping (String, String, Bool) -> Void) {
        self.draft = draft
        self.onSave = onSave
        _host = State(initialValue: draft.host)
        _note = State(initialValue: draft.note)
        _enabled = State(initialValue: draft.enabled)
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

    /// 添加模式下实时预览网段展开结果
    private var preview: BulkImportParser.Result? {
        guard draft.isNew, !trimmedHost.isEmpty else { return nil }
        return BulkImportParser.parse(
            host: trimmedHost,
            note: trimmedNote,
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
                existing: Set(model.targets.map { $0.host.lowercased() })
            )
            guard !result.entries.isEmpty else {
                validationError = result.rejected.first?.reason.message
                    ?? String(localized: L10n.alertAddFailedDefaultMessage)
                return
            }
            validationError = nil
            onSave(trimmedHost, trimmedNote, enabled)
            return
        }

        // 编辑模式只允许单个目标，避免「一个目标变成多个」的歧义
        let result = BulkImportParser.parse(host: trimmedHost, note: "", existing: [])
        guard result.entries.count == 1, result.entries[0].host == trimmedHost else {
            validationError = String(localized: L10n.editorRangeNotAllowed)
            return
        }
        validationError = nil
        onSave(trimmedHost, trimmedNote, enabled)
    }
}
