import Foundation

/// Markdown 导出：标题 + 汇总 + 表格
public enum MarkdownExporter {
    public static func markdown(for entries: [ExportEntry], exportedAt: Date = Date()) -> String {
        let table = ExportTable(entries: entries)
        let summary = ExportSummary(entries: entries)

        var lines: [String] = []
        lines.append("# PingDeck 导出结果")
        lines.append("")
        lines.append("- 导出时间：\(ExportValueFormatter.dateFormatter.string(from: exportedAt))")
        lines.append("- \(summary.description)")
        lines.append("")
        lines.append("| " + table.columns.map(\.title).joined(separator: " | ") + " |")
        lines.append("| " + table.columns.map { _ in "---" }.joined(separator: " | ") + " |")
        for row in table.rows {
            let cells = row.enumerated().map { offset, value in
                escape(ExportValueFormatter.display(value, format: table.columns[offset].format))
            }
            lines.append("| " + cells.joined(separator: " | ") + " |")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// 表格里的竖线需要转义，否则会破坏 Markdown 表格结构
    private static func escape(_ cell: String) -> String {
        cell.replacingOccurrences(of: "|", with: "\\|")
    }
}
