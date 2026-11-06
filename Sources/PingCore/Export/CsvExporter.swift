import Foundation

/// CSV 导出
///
/// 输出保持历史格式不变（BOM、CRLF、精度），下游脚本无需调整。
public enum CsvExporter {
    public typealias Entry = ExportEntry

    public static let header = ExportTable.columns.map(\.title)

    public static func csv(for entries: [Entry]) -> String {
        let table = ExportTable(entries: entries)

        var lines: [String] = [header.map(escape).joined(separator: ",")]

        for (index, row) in table.rows.enumerated() {
            let fields = row.enumerated().map { offset, value in
                ExportValueFormatter.display(value, format: table.columns[offset].format)
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
