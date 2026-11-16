import SwiftUI
import AppKit
import PingCore

struct ContentView: View {
    @EnvironmentObject private var model: PingDeckViewModel
    @AppStorage(ColumnCustomizationStore.storageKey)
    private var columnCustomization = TableColumnCustomization<TargetRow>()

    var body: some View {
        VStack(spacing: 0) {
            if let alert = model.alert {
                AlertBanner(alert: alert) { model.alert = nil }
                Divider()
            }
            toolbarBar
            Divider()
            ColorFilterBar()
            Divider()
            if model.isGroupedView {
                GroupedTargetsTableView()
            } else {
                TargetsTableView(columnCustomization: $columnCustomization)
            }
            if model.detailRow != nil {
                Divider()
                TargetDetailPanel()
            }
            Divider()
            footerBar
        }
        .sheet(item: $model.sheet) { sheet in
            switch sheet {
            case .addTargets:
                AddTargetsSheet()
                    .environmentObject(model)
            case .settings:
                SettingsSheet(initialLanguage: model.settings.language)
                    .environmentObject(model)
            }
        }
        .confirmationDialog(
            String(localized: L10n.confirmClearAllTitle(model.targets.count)),
            isPresented: $model.confirmingClearAllTargets,
            titleVisibility: .visible
        ) {
            Button(String(localized: L10n.confirmClearAllConfirm), role: .destructive) { model.clearAllTargets() }
            Button(String(localized: L10n.commonCancel), role: .cancel) { }
        }
    }

    private var toolbarBar: some View {
        HStack(spacing: 8) {
            Button {
                model.openAddTargetsSheet()
            } label: {
                Label(String(localized: L10n.toolbarAdd), systemImage: "plus")
            }
            .help(String(localized: L10n.toolbarAddHelp))

            Button {
                removeSelected()
            } label: {
                Label(
                    model.selection.count > 1
                        ? String(localized: L10n.toolbarDeleteCount(model.selection.count))
                        : String(localized: L10n.toolbarDelete),
                    systemImage: "minus"
                )
            }
            .disabled(model.selection.isEmpty)
            .keyboardShortcut(.delete, modifiers: [])
            .help(String(localized: L10n.toolbarDeleteHelp))

            Divider().frame(height: 18)

            Button {
                model.start()
            } label: {
                Label(String(localized: L10n.toolbarStart), systemImage: "play.fill")
                    .foregroundStyle(Color.green)
            }
            .disabled(model.isRunning)
            .help(String(localized: L10n.toolbarStartHelp))

            Button {
                model.stop()
            } label: {
                Label(String(localized: L10n.toolbarStop), systemImage: "stop.fill")
                    .foregroundStyle(Color.red)
            }
            .disabled(!model.isRunning)
            .help(String(localized: L10n.toolbarStopHelp))

            Menu {
                Button(String(localized: L10n.toolbarClearResults)) {
                    model.clearResults()
                }
                Button(String(localized: L10n.toolbarClearAll), role: .destructive) {
                    model.confirmingClearAllTargets = true
                }
                .disabled(model.targets.isEmpty)
            } label: {
                Label(String(localized: L10n.toolbarClear), systemImage: "trash")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help(String(localized: L10n.toolbarClearHelp))

            Spacer()

            Menu {
                ForEach(TargetColumn.allCases.filter { !$0.isRequired }) { column in
                    Toggle(column.title, isOn: columnBinding(column))
                }
                Divider()
                Button(String(localized: L10n.toolbarColumnsShowAll)) {
                    for column in TargetColumn.allCases {
                        columnCustomization[visibility: column.rawValue] = .visible
                    }
                }
            } label: {
                Label(String(localized: L10n.toolbarColumns), systemImage: "rectangle.split.3x1")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help(String(localized: L10n.toolbarColumnsHelp))

            Button {
                ExportSavePanel.present(scope: .automatic, model: model)
            } label: {
                Label(String(localized: L10n.toolbarSave), systemImage: "square.and.arrow.down")
            }
            .disabled(model.rows.isEmpty)
            .help(String(localized: L10n.toolbarExportHelp))

            Button {
                model.openSettingsSheet()
            } label: {
                Image(systemName: "gearshape")
            }
            .help(String(localized: L10n.toolbarSettings))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - 底部状态栏

    private var footerBar: some View {
        HStack(spacing: 16) {
            Text(String(localized: L10n.statusBarTargets(model.targets.count)))
            Text(String(localized: L10n.statusBarAlive(model.aliveCount)))
            Text(String(localized: L10n.statusBarProblems(model.problemCount)))
            Text(String(localized: L10n.statusBarTotalSent(model.totalSent)))
            Spacer()
            if !model.selection.isEmpty {
                Text(String(localized: L10n.statusBarSelected(model.selection.count)))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Text(statusSummary)
                .foregroundStyle(.secondary)
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var statusSummary: String {
        var base = String(
            localized: L10n.statusBarSummary(
                Float(model.settings.interval),
                Float(model.settings.timeout),
                model.settings.maxConcurrent
            )
        )
        if model.isRunning, model.queuedTargetCount > 0 {
            base += String(localized: L10n.statusBarQueued(model.queuedTargetCount))
        }
        return model.isRunning
            ? String(localized: L10n.statusBarRunning(base))
            : String(localized: L10n.statusBarStopped(base))
    }

    // MARK: - 动作

    private func removeSelected() {
        guard !model.selection.isEmpty else { return }
        model.removeTargets(ids: model.selection)
    }

    private func columnBinding(_ column: TargetColumn) -> Binding<Bool> {
        Binding(
            get: { columnCustomization[visibility: column.rawValue] != .hidden },
            set: { isOn in
                columnCustomization[visibility: column.rawValue] = isOn ? .visible : .hidden
            }
        )
    }
}

/// 顶部错误提示条
struct AlertBanner: View {
    let alert: AppAlert
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.callout.weight(.semibold))
                Text(alert.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(String(localized: L10n.alertDismissHelp))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
