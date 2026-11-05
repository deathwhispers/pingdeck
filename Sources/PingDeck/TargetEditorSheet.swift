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
                Text("目标（IP 或域名）")
                    .font(.subheadline)
                TextField("例如 8.8.8.8 或 gateway.lan", text: $host)
                    .textFieldStyle(.roundedBorder)
                if let validationError {
                    Text(validationError)
                        .font(.caption)
                        .foregroundStyle(.red)
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

    private func save() {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if let error = TargetValidator.validate(trimmedHost) {
            validationError = error
            return
        }
        onSave(trimmedHost, note.trimmingCharacters(in: .whitespacesAndNewlines), enabled)
    }
}
