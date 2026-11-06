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
            TargetsTableView(columnCustomization: $columnCustomization)
            Divider()
            footerBar
        }
        .sheet(item: $model.sheet) { sheet in
            switch sheet {
            case .editor(let draft):
                TargetEditorSheet(draft: draft) { host, note, enabled in
                    if draft.isNew {
                        let result = model.addTargets(host: host, note: note, enabled: enabled)
                        model.closeSheet()
                        if result.entries.count > 1 {
                            model.alert = AppAlert(
                                title: "已添加 \(result.entries.count) 个目标",
                                message: "网段已展开并加入列表。"
                            )
                        } else if result.entries.isEmpty {
                            model.alert = AppAlert(
                                title: "添加失败",
                                message: result.rejected.first?.reason ?? "目标格式不正确"
                            )
                        }
                    } else if let id = draft.targetID {
                        model.closeSheet()
                        model.updateTarget(id: id, host: host, note: note, enabled: enabled)
                    }
                }
                .environmentObject(model)
            case .settings:
                SettingsSheet()
                    .environmentObject(model)
            case .bulkImport:
                BulkImportSheet()
                    .environmentObject(model)
            }
        }
        .confirmationDialog(
            "确定要删除全部 \(model.targets.count) 个目标吗？此操作不可撤销。",
            isPresented: $model.confirmingClearAllTargets,
            titleVisibility: .visible
        ) {
            Button("全部删除", role: .destructive) { model.clearAllTargets() }
            Button("取消", role: .cancel) { }
        }
    }

    private var toolbarBar: some View {
        HStack(spacing: 8) {
            Button {
                model.openNewTargetSheet()
            } label: {
                Label("添加", systemImage: "plus")
            }
            .help("添加一个 IP 或域名")

            Button {
                model.openEditTargetSheet()
            } label: {
                Image(systemName: "pencil")
            }
            .disabled(model.selection.count != 1)
            .help("编辑选中的目标")

            Button {
                removeSelected()
            } label: {
                Label(model.selection.count > 1 ? "删除 \(model.selection.count)" : "删除", systemImage: "minus")
            }
            .disabled(model.selection.isEmpty)
            .keyboardShortcut(.delete, modifiers: [])
            .help("删除选中的目标（⌘ 点击加选、⇧ 点击选区间、Delete 删除）")

            Divider().frame(height: 18)

            Button {
                model.toggleRun()
            } label: {
                Label(model.isRunning ? "停止" : "开始", systemImage: model.isRunning ? "stop.fill" : "play.fill")
                    .foregroundStyle(model.isRunning ? Color.red : Color.green)
            }
            .help(model.isRunning ? "停止全部探测" : "开始批量探测")

            Button {
                model.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("立即重新发起一轮探测")

            Menu {
                Button("清空结果（保留目标）") {
                    model.clearResults()
                }
                Button("清空全部目标…", role: .destructive) {
                    model.confirmingClearAllTargets = true
                }
                .disabled(model.targets.isEmpty)
            } label: {
                Label("清空", systemImage: "trash")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("清空统计结果，或删除全部目标")

            Spacer()

            Button {
                model.openBulkImportSheet()
            } label: {
                Label("批量导入", systemImage: "text.badge.plus")
            }
            .help("从多行文本批量添加目标")

            Menu {
                ForEach(TargetColumn.allCases.filter { !$0.isRequired }) { column in
                    Toggle(column.title, isOn: columnBinding(column))
                }
                Divider()
                Button("显示全部列") {
                    for column in TargetColumn.allCases {
                        columnCustomization[visibility: column.rawValue] = .visible
                    }
                }
            } label: {
                Label("列", systemImage: "rectangle.split.3x1")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("显示或隐藏表格列")

            Menu {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Menu {
                        Button("导出全部 \(model.rows.count) 项") {
                            export(entries: model.allEntries, format: format)
                        }
                        .disabled(model.rows.isEmpty)
                        Button("导出选中 \(model.selection.count) 项") {
                            export(entries: model.selectedEntries, format: format)
                        }
                        .disabled(model.selection.isEmpty)
                    } label: {
                        Text(format.displayName)
                    }
                }
            } label: {
                Label("导出", systemImage: "square.and.arrow.up")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("导出结果：支持 CSV / JSON / TXT / Markdown / Excel，可选择导出全部或仅选中项")

            Button {
                model.openSettingsSheet()
            } label: {
                Image(systemName: "gearshape")
            }
            .help("设置")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - 底部状态栏

    private var footerBar: some View {
        HStack(spacing: 16) {
            Text("目标 \(model.targets.count)")
            Text("正常 \(model.aliveCount)")
            Text("异常 \(model.problemCount)")
            Text("累计发包 \(model.totalSent)")
            Spacer()
            if !model.selection.isEmpty {
                Text("已选 \(model.selection.count) 项")
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
        var base = "间隔 \(String(format: "%.1f", model.settings.interval))s · 超时 \(String(format: "%.1f", model.settings.timeout))s · 并发 \(model.settings.maxConcurrent)"
        if model.isRunning, model.queuedTargetCount > 0 {
            base += " · 排队 \(model.queuedTargetCount)"
        }
        return model.isRunning ? "运行中 · " + base : "已停止 · " + base
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

    private func export(entries: [ExportEntry], format: ExportFormat) {
        guard !entries.isEmpty else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [Self.contentType(for: format)]
        panel.nameFieldStringValue = ExportFile.filename(format: format)
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let data = ExportFile.data(format: format, entries: entries)
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                DispatchQueue.main.async {
                    model.alert = AppAlert(title: "导出失败", message: error.localizedDescription)
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
            .help("关闭提示")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
