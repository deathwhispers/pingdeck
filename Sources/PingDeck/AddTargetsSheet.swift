import SwiftUI
import PingCore

/// 添加目标弹窗：支持单行、多行、网段、带备注/分组/颜色标签录入，
/// 可选择追加到现有列表或整体替换，并立即开始探测
struct AddTargetsSheet: View {
    @EnvironmentObject private var model: PingDeckViewModel
    @State private var text: String = ""
    @State private var mode: ImportMode = .replace
    @State private var autoPrefillText = ""
    @State private var defaultGroup = ""
    @State private var defaultColorTag: TargetColorTag?
    @State private var interval = PingSettings.default.interval
    @State private var timeout = PingSettings.default.timeout
    @State private var packetSize = PingSettings.default.packetSize
    @State private var didPrefillProbeSettings = false

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

            modeSection

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

            Divider()

            probeSettingsSection

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
            autoPrefillText = model.targets.isEmpty ? "" : model.exportTargetsAsEditableText()
            if text.isEmpty {
                text = autoPrefillText
            }
            if !didPrefillProbeSettings {
                interval = PingSettings.clampInterval(model.settings.interval)
                timeout = PingSettings.clampTimeout(model.settings.timeout)
                packetSize = PingSettings.clampPacketSize(model.settings.packetSize)
                didPrefillProbeSettings = true
            }
        }
        .onChange(of: mode) { _, newMode in
            applyModeChange(to: newMode)
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Text(L10n.importMode)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $mode) {
                    ForEach(ImportMode.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                Spacer()
            }
            Text(modeDescription)
                .font(.caption)
                .foregroundStyle(mode == .replace && !model.targets.isEmpty ? Color.orange : Color.secondary)
        }
    }

    private var modeDescription: String {
        switch mode {
        case .append:
            return String(localized: L10n.importModeAppendDescription(model.targets.count))
        case .replace:
            if model.targets.isEmpty {
                return String(localized: L10n.importModeReplaceDescriptionEmpty)
            }
            return String(localized: L10n.importModeReplaceDescriptionWithCount(model.targets.count))
        }
    }

    /// 切换导入方式时同步编辑区回显：追加从空白开始，替换恢复现有目标列表；
    /// 用户手动修改过的内容保持不变
    private func applyModeChange(to newMode: ImportMode) {
        guard text.isEmpty || text == autoPrefillText else { return }
        text = newMode == .append ? "" : autoPrefillText
    }

    private var confirmTitle: String {
        guard !preview.entries.isEmpty else { return String(localized: L10n.commonSave) }
        switch mode {
        case .append:
            return String(localized: L10n.importConfirmAppend(preview.entries.count))
        case .replace:
            return String(localized: L10n.importConfirmReplace(preview.entries.count))
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
                    .frame(height: 60)
                }
            }
        }
    }

    private var probeSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.probeSection)
                    .font(.headline)
                Spacer()
                Button(String(localized: L10n.probeResetDefaults)) {
                    resetProbeSettings()
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            HStack(alignment: .bottom, spacing: 20) {
                probeSlider(
                    title: L10n.probeInterval,
                    valueText: L10n.unitSecondsDecimal(Float(interval)),
                    value: $interval,
                    range: PingSettings.intervalRange
                )
                probeSlider(
                    title: L10n.probeTimeout,
                    valueText: L10n.unitSecondsDecimal(Float(timeout)),
                    value: $timeout,
                    range: PingSettings.timeoutRange
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.probePacketSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("", value: $packetSize, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                }
            }

            Text(L10n.probeHint)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func probeSlider(
        title: LocalizedStringResource,
        valueText: LocalizedStringResource,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(valueText)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 0.5)
        }
    }

    private func resetProbeSettings() {
        interval = PingSettings.default.interval
        timeout = PingSettings.default.timeout
        packetSize = PingSettings.default.packetSize
    }

    private func importAndStart() {
        model.applyProbeSettings(interval: interval, timeout: timeout, packetSize: packetSize)
        let result = model.importTargetsAndStart(
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
