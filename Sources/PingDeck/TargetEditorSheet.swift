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
            Text(draft.isNew ? "添加 Ping 目标" : "编辑 Ping 目标")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text(draft.isNew ? "目标（IP、域名或网段）" : "目标（IP 或域名）")
                    .font(.subheadline)
                TextField(
                    draft.isNew
                        ? "例如 8.8.8.8、gateway.lan 或 10.0.0.0/24"
                        : "例如 8.8.8.8 或 gateway.lan",
                    text: $host
                )
                .textFieldStyle(.roundedBorder)
                if let validationError {
                    Text(validationError)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if let preview, preview.entries.count > 1 {
                    Text("将添加 \(preview.entries.count) 个目标")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("备注")
                    .font(.subheadline)
                TextField("可选，例如「核心交换机」", text: $note)
                    .textFieldStyle(.roundedBorder)
            }

            Toggle("启用该目标", isOn: $enabled)

            HStack {
                Spacer()
                Button("取消") { model.closeSheet() }
                Button("保存") { save() }
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
            validationError = "目标不能为空"
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
            validationError = "编辑模式只支持单个 IP 或域名；添加网段请使用「添加」或「批量导入」"
            return
        }
        validationError = nil
        onSave(trimmedHost, trimmedNote, enabled)
    }
}
