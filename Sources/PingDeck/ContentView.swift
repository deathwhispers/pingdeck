import SwiftUI
import AppKit
import UniformTypeIdentifiers
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
            Divider()
            footerBar
        }
        .sheet(item: $model.sheet) { sheet in
            switch sheet {
            case .editor(let draft):
                TargetEditorSheet(draft: draft) { host, note, enabled, group, colorTag in
                    if draft.isNew {
                        let result = model.addTargets(
                            host: host,
                            note: note,
                            enabled: enabled,
                            group: group,
                            colorTag: colorTag
                        )
                        model.closeSheet()
                        if result.entries.count > 1 {
                            model.alert = AppAlert(
                                title: String(localized: L10n.alertTargetsAddedTitle(result.entries.count)),
                                message: String(localized: L10n.alertTargetsAddedMessage)
                            )
                        } else if result.entries.isEmpty {
                            model.alert = AppAlert(
                                title: String(localized: L10n.alertAddFailedTitle),
                                message: result.rejected.first?.reason.message
                                    ?? String(localized: L10n.alertAddFailedDefaultMessage)
                            )
                        }
                    } else if let id = draft.targetID {
                        model.closeSheet()
                        model.updateTarget(
                            id: id,
                            host: host,
                            note: note,
                            enabled: enabled,
                            group: group,
                            colorTag: colorTag
                        )
                    }
                }
                .environmentObject(model)
            case .settings:
                SettingsSheet(initialLanguage: model.settings.language)
                    .environmentObject(model)
            case .bulkImport:
                BulkImportSheet()
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
                model.openNewTargetSheet()
            } label: {
                Label(String(localized: L10n.toolbarAdd), systemImage: "plus")
            }
            .help(String(localized: L10n.toolbarAddHelp))

            Button {
                model.openEditTargetSheet()
            } label: {
                Image(systemName: "pencil")
            }
            .disabled(model.selection.count != 1)
            .help(String(localized: L10n.toolbarEditHelp))

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
                model.toggleRun()
            } label: {
                Label(
                    model.isRunning
                        ? String(localized: L10n.toolbarStop)
                        : String(localized: L10n.toolbarStart),
                    systemImage: model.isRunning ? "stop.fill" : "play.fill"
                )
                    .foregroundStyle(model.isRunning ? Color.red : Color.green)
            }
            .help(
                model.isRunning
                    ? String(localized: L10n.toolbarStopHelp)
                    : String(localized: L10n.toolbarStartHelp)
            )

            Button {
                model.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help(String(localized: L10n.toolbarRefreshHelp))

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

            Button {
                model.openBulkImportSheet()
            } label: {
                Label(String(localized: L10n.toolbarImport), systemImage: "text.badge.plus")
            }
            .help(String(localized: L10n.toolbarImportHelp))

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

            Menu {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Menu {
                        Button(String(localized: L10n.toolbarExportAll(model.rows.count))) {
                            export(entries: model.allEntries, format: format)
                        }
                        .disabled(model.rows.isEmpty)
                        Button(String(localized: L10n.toolbarExportSelected(model.selection.count))) {
                            export(entries: model.selectedEntries, format: format)
                        }
                        .disabled(model.selection.isEmpty)
                    } label: {
                        Text(format.displayName)
                    }
                }
            } label: {
                Label(String(localized: L10n.toolbarExport), systemImage: "square.and.arrow.up")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
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

    private var exportLabels: ExportLabels {
        ExportLabels(
            columnTitles: [
                String(localized: L10n.exportColumnTarget),
                String(localized: L10n.exportColumnNote),
                String(localized: L10n.groupColumnTitle),
                String(localized: L10n.colorTagColumnTitle),
                String(localized: L10n.exportColumnStatus),
                String(localized: L10n.exportColumnLastLatency),
                String(localized: L10n.exportColumnAverageLatency),
                String(localized: L10n.exportColumnMinLatency),
                String(localized: L10n.exportColumnMaxLatency),
                String(localized: L10n.exportColumnLossRate),
                String(localized: L10n.exportColumnLastResponse),
            ],
            statusName: { $0.displayName },
            summary: {
                String(localized: L10n.exportSummary($0.targets, $0.alive, $0.problems, $0.totalSent))
            },
            markdownTitle: String(localized: L10n.exportMarkdownTitle),
            exportedAtLabel: String(localized: L10n.exportMarkdownExportedAt)
        )
    }

    private func export(entries: [ExportEntry], format: ExportFormat) {
        guard !entries.isEmpty else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [Self.contentType(for: format)]
        panel.nameFieldStringValue = ExportFile.filename(format: format)
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let data = ExportFile.data(format: format, entries: entries, labels: exportLabels)
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                DispatchQueue.main.async {
                    model.alert = AppAlert(
                        title: String(localized: L10n.alertExportFailedTitle),
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    /// 各格式对应的文件类型；markdown 与 xlsx 没有系统内建类型，按扩展名动态解析
    private static func contentType(for format: ExportFormat) -> UTType {
        switch format {
        case .csv: return .commaSeparatedText
        case .json: return .json
        case .txt: return .plainText
        case .markdown: return UTType(filenameExtension: "md") ?? .plainText
        case .xlsx: return UTType(filenameExtension: "xlsx") ?? .data
        }
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
