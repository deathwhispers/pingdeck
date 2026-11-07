import SwiftUI
import PingCore

struct SettingsSheet: View {
    @EnvironmentObject private var model: PingDeckViewModel

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { model.settings.language },
            set: { model.setLanguage($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.settingsTitle)
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.settingsAppearance)
                Picker(String(localized: L10n.settingsAppearance), selection: $model.settings.appearance) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Text(L10n.settingsAppearanceHint)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.settingsLanguage)
                Picker(String(localized: L10n.settingsLanguage), selection: languageBinding) {
                    Text(L10n.languageSystem).tag(AppLanguage.system)
                    Text(verbatim: "简体中文").tag(AppLanguage.simplifiedChinese)
                    Text(verbatim: "English").tag(AppLanguage.english)
                    Text(verbatim: "日本語").tag(AppLanguage.japanese)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                Text(L10n.settingsLanguageHint)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(L10n.settingsInterval)
                    Spacer()
                    Text(L10n.unitSecondsDecimal(Float(model.settings.interval)))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $model.settings.interval, in: 0.5...10, step: 0.5)
                Text(L10n.settingsIntervalHint)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(L10n.settingsTimeout)
                    Spacer()
                    Text(L10n.unitSecondsDecimal(Float(model.settings.timeout)))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $model.settings.timeout, in: 1...10, step: 0.5)
                Text(L10n.settingsTimeoutHint)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Stepper(
                value: $model.settings.maxConcurrent,
                in: 1...PingSettings.maxConcurrentLimit
            ) {
                HStack {
                    Text(L10n.settingsMaxConcurrent)
                    Spacer()
                    Text("\(model.settings.maxConcurrent)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            Text(L10n.settingsMaxConcurrentHint(PingSettings.maxConcurrentLimit))
                .font(.caption)
                .foregroundStyle(.tertiary)

            Stepper(
                value: $model.settings.rotationInterval,
                in: 0...300,
                step: 15
            ) {
                HStack {
                    Text(L10n.settingsRotation)
                    Spacer()
                    Text(
                        model.settings.rotationInterval == 0
                            ? L10n.commonOff
                            : L10n.unitSecondsInteger(Int(model.settings.rotationInterval))
                    )
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            Text(L10n.settingsRotationHint)
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack {
                Spacer()
                Button(String(localized: L10n.commonDone)) {
                    model.saveNow()
                    model.closeSheet()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}
