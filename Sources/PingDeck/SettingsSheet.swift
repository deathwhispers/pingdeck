import SwiftUI
import PingCore

struct SettingsSheet: View {
    @EnvironmentObject private var model: PingDeckViewModel
    @State private var selectedLanguage: AppLanguage
    @State private var showingLanguageRestartPrompt = false

    init(initialLanguage: AppLanguage) {
        _selectedLanguage = State(initialValue: initialLanguage)
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
                Picker(String(localized: L10n.settingsLanguage), selection: $selectedLanguage) {
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

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.settingsMenuBarSection)
                    .font(.headline)

                Toggle(isOn: $model.settings.menuBar.showTextLabel) {
                    Text(L10n.settingsMenuBarShowText)
                }

                Picker(L10n.settingsCloseBehavior, selection: $model.settings.menuBar.closeBehavior) {
                    Text(L10n.settingsCloseBehaviorKeepRunning).tag(WindowCloseBehavior.keepRunning)
                    Text(L10n.settingsCloseBehaviorTerminate).tag(WindowCloseBehavior.terminate)
                    Text(L10n.settingsCloseBehaviorAsk).tag(WindowCloseBehavior.ask)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.settingsNotchIslandSection)
                    .font(.headline)

                Toggle(isOn: $model.settings.notchIsland.enabled) {
                    Text(L10n.settingsNotchIslandEnable)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $model.settings.notchIsland.showEars) {
                        Text(L10n.settingsNotchIslandShowEars)
                    }

                    Toggle(isOn: $model.settings.notchIsland.showMetrics) {
                        Text(L10n.settingsNotchIslandShowMetrics)
                    }

                    Toggle(isOn: $model.settings.notchIsland.showRecentProblems) {
                        Text(L10n.settingsNotchIslandShowRecentProblems)
                    }

                    Toggle(isOn: $model.settings.notchIsland.showQuickControls) {
                        Text(L10n.settingsNotchIslandShowQuickControls)
                    }
                }
                .padding(.leading, 16)
                .disabled(!model.settings.notchIsland.enabled)
            }

            HStack {
                Spacer()
                Button(String(localized: L10n.commonDone)) {
                    guard selectedLanguage != model.settings.language else {
                        model.saveNow()
                        model.closeSheet()
                        return
                    }
                    showingLanguageRestartPrompt = true
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
        .alert(
            Text(L10n.languageRestartPromptTitle.string(for: selectedLanguage)),
            isPresented: $showingLanguageRestartPrompt
        ) {
            Button(L10n.languageRestartPromptNow.string(for: selectedLanguage)) {
                model.applyLanguage(selectedLanguage, relaunch: true)
                model.closeSheet()
            }
            Button(
                L10n.languageRestartPromptLater.string(for: selectedLanguage),
                role: .cancel
            ) {
                if model.applyLanguage(selectedLanguage, relaunch: false) {
                    model.alert = AppAlert(
                        title: L10n.alertLanguagePendingTitle.string(for: selectedLanguage),
                        message: L10n.alertLanguagePendingMessage.string(for: selectedLanguage)
                    )
                }
                model.closeSheet()
            }
        } message: {
            Text(L10n.languageRestartPromptMessage.string(for: selectedLanguage))
        }
    }
}
