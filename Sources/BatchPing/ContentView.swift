import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PingCore

struct ContentView: View {
    @EnvironmentObject private var model: BatchPingViewModel

    var body: some View {
        VStack(spacing: 0) {
            if let alert = model.alert {
                AlertBanner(alert: alert) { model.alert = nil }
                Divider()
            }
            toolbarBar
            Divider()
            TargetsTableView()
            Divider()
            footerBar
        }
        .sheet(item: $model.editorDraft) { draft in
            TargetEditorSheet(draft: draft) { host, note, enabled in
                model.editorDraft = nil
                if draft.isNew {
                    model.addTarget(host: host, note: note, enabled: enabled)
                } else if let id = draft.targetID {
                    model.updateTarget(id: id, host: host, note: note, enabled: enabled)
                }
            }
        }
        .sheet(isPresented: $model.showingSettings) {
            SettingsSheet()
                .environmentObject(model)
        }
    }

    // MARK: - 工具栏

    private var toolbarBar: some View {
        HStack(spacing: 8) {
            Button {
                model.editorDraft = .new()
            } label: {
                Label("添加", systemImage: "plus")
            }
            .help("添加一个 IP 或域名")

            Button {
                editSelected()
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            .disabled(model.selection.count != 1)
            .help("编辑选中的目标")

            Button {
                removeSelected()
            } label: {
                Label("删除", systemImage: "minus")
            }
            .disabled(model.selection.isEmpty)
            .help("删除选中的目标")

            Divider().frame(height: 18)

            Button {
                model.toggleRun()
            } label: {
                Label(model.isRunning ? "停止" : "开始", systemImage: model.isRunning ? "stop.fill" : "play.fill")
            }
            .help(model.isRunning ? "停止全部探测" : "开始批量探测")

            Button {
                model.refresh()
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .help("立即重新发起一轮探测")

            Button {
                model.clearResults()
            } label: {
                Label("清空结果", systemImage: "trash")
            }
            .help("清空统计数据")

            Spacer()

            Menu {
                ForEach(SortMode.allCases) { mode in
                    Button {
                        model.sortMode = mode
                    } label: {
                        if model.sortMode == mode {
                            Label(mode.title, systemImage: "checkmark")
                        } else {
                            Text(mode.title)
                        }
                    }
                }
            } label: {
                Label("排序", systemImage: "arrow.up.arrow.down")
            }
            .help("选择表格排序方式")

            Button {
                exportCSV()
            } label: {
                Label("导出 CSV", systemImage: "square.and.arrow.up")
            }
            .disabled(model.rows.isEmpty)

            Button {
                model.showingSettings = true
            } label: {
                Label("设置", systemImage: "gearshape")
            }
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
            Text(statusSummary)
                .foregroundStyle(.secondary)
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var statusSummary: String {
        let base = "间隔 \(String(format: "%.1f", model.settings.interval))s · 超时 \(String(format: "%.1f", model.settings.timeout))s · 并发上限 \(model.settings.maxConcurrent)"
        return model.isRunning ? "运行中 · " + base : "已停止 · " + base
    }

    // MARK: - 动作

    private func editSelected() {
        guard let id = model.selection.first,
              let target = model.targets.first(where: { $0.id == id }) else { return }
        model.editorDraft = .edit(target)
    }

    private func removeSelected() {
        guard !model.selection.isEmpty else { return }
        model.removeTargets(ids: model.selection)
    }

    private func exportCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        panel.nameFieldStringValue = "batchping-\(Self.fileTimestamp()).csv"
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let csv = CsvExporter.csv(for: model.csvEntries)
            do {
                try csv.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                DispatchQueue.main.async {
                    model.alert = AppAlert(title: "导出失败", message: error.localizedDescription)
                }
            }
        }
    }

    private static func fileTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
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
