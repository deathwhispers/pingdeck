import AppKit
import PingCore
import UniformTypeIdentifiers

/// 保存结果时的范围
enum ExportScope: Equatable {
    /// 有选中项时保存选中项，否则保存全部
    case automatic
    /// 强制保存全部
    case all
    /// 强制保存选中项
    case selection

    /// 把自动范围解析成确定范围，便于单独测试
    func resolved(hasSelection: Bool) -> ExportScope {
        switch self {
        case .automatic:
            return hasSelection ? .selection : .all
        case .all, .selection:
            return self
        }
    }

    func entries(in model: PingDeckViewModel) -> [ExportEntry] {
        switch resolved(hasSelection: !model.selection.isEmpty) {
        case .selection:
            return model.selectedEntries
        case .all, .automatic:
            return model.allEntries
        }
    }
}

/// 保存结果的统一入口：在系统保存面板里选择格式，按当前范围导出
enum ExportSavePanel {
    /// 记住上次选择的格式
    static let lastFormatDefaultsKey = "export.lastFormat"

    static func present(scope: ExportScope, model: PingDeckViewModel) {
        let entries = scope.entries(in: model)
        guard !entries.isEmpty else { return }

        let format = lastFormat() ?? .csv
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.allowedContentTypes = [contentType(for: format)]
        panel.nameFieldStringValue = ExportFile.filename(format: format)

        let scopeText = scopeDescription(for: scope, model: model)
        let accessory = ExportFormatAccessory(selected: format, scopeText: scopeText)
        accessory.onChange = { [weak panel] newFormat in
            guard let panel else { return }
            panel.allowedContentTypes = [contentType(for: newFormat)]
            panel.nameFieldStringValue = replacingExtension(
                of: panel.nameFieldStringValue,
                with: newFormat.fileExtension
            )
        }
        panel.accessoryView = accessory.view

        panel.begin { response in
            // 闭包强引用 accessory，保证面板存活期间它不会被释放
            guard response == .OK, let url = panel.url else { return }
            let chosen = accessory.selectedFormat
            UserDefaults.standard.set(chosen.rawValue, forKey: lastFormatDefaultsKey)

            let destination = url.pathExtension.lowercased() == chosen.fileExtension
                ? url
                : url.deletingPathExtension().appendingPathExtension(chosen.fileExtension)
            let data = ExportFile.data(format: chosen, entries: entries, labels: model.exportLabels)
            do {
                try data.write(to: destination, options: .atomic)
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

    /// 面板顶部提示当前保存范围
    private static func scopeDescription(for scope: ExportScope, model: PingDeckViewModel) -> String {
        switch scope.resolved(hasSelection: !model.selection.isEmpty) {
        case .selection:
            return String(localized: L10n.toolbarExportSelected(model.selection.count))
        case .all, .automatic:
            return String(localized: L10n.toolbarExportAll(model.rows.count))
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

    private static func lastFormat() -> ExportFormat? {
        guard let raw = UserDefaults.standard.string(forKey: lastFormatDefaultsKey) else { return nil }
        return ExportFormat(rawValue: raw)
    }

    /// 切换格式时保留用户已经输入的文件名主干，只替换扩展名
    private static func replacingExtension(of name: String, with fileExtension: String) -> String {
        let base = (name as NSString).deletingPathExtension
        return base.isEmpty ? "pingdeck.\(fileExtension)" : "\(base).\(fileExtension)"
    }
}

extension PingDeckViewModel {
    var exportLabels: ExportLabels {
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
}

/// 保存面板里的格式下拉框
private final class ExportFormatAccessory: NSObject {
    private let formats = ExportFormat.allCases
    private let popup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let scopeText: String
    var onChange: ((ExportFormat) -> Void)?

    init(selected: ExportFormat, scopeText: String) {
        self.scopeText = scopeText
        super.init()

        for format in formats {
            popup.addItem(withTitle: format.displayName)
        }
        if let index = formats.firstIndex(of: selected) {
            popup.selectItem(at: index)
        }
        popup.target = self
        popup.action = #selector(selectionChanged)
    }

    var selectedFormat: ExportFormat {
        let index = popup.indexOfSelectedItem
        guard formats.indices.contains(index) else { return .csv }
        return formats[index]
    }

    var view: NSView {
        let scopeLabel = NSTextField(labelWithString: scopeText)
        scopeLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        scopeLabel.textColor = .secondaryLabelColor

        let formatLabel = NSTextField(labelWithString: String(localized: L10n.exportFormat))
        let formatRow = NSStackView(views: [formatLabel, popup])
        formatRow.orientation = .horizontal
        formatRow.alignment = .centerY
        formatRow.spacing = 8

        let stack = NSStackView(views: [scopeLabel, formatRow])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        return stack
    }

    @objc private func selectionChanged() {
        onChange?(selectedFormat)
    }
}
