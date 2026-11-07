import Foundation

/// CSV 导出
///
/// 输出保持历史格式不变（BOM、CRLF、精度），下游脚本无需调整。
public enum CsvExporter {
    public typealias Entry = ExportEntry

    public static func csv(for entries: [Entry], labels: ExportLabels) -> String {
        let table = ExportTable(entries: entries, labels: labels)

        var lines: [String] = [table.columns.map(\.title).map(escape).joined(separator: ",")]

        for row in table.rows {
            let fields = row.enumerated().map { offset, value in
                ExportValueFormatter.display(value, format: table.columns[offset].format, labels: labels)
            }
            lines.append(fields.map(escape).joined(separator: ","))
        }

        // 带 BOM，保证 Excel 正确识别 UTF-8 中文
        return "\u{FEFF}" + lines.joined(separator: "\r\n") + "\r\n"
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
}
