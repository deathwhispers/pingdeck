import Foundation

/// 导出的统一出口：按格式产出文件数据与默认文件名
public enum ExportFile {
    /// 默认文件名：pingdeck-<时间戳>.<扩展名>
    public static func filename(format: ExportFormat, date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "pingdeck-\(formatter.string(from: date)).\(format.fileExtension)"
    }

    /// 按格式产出文件内容（xlsx 为二进制，其余为 UTF-8 文本）
    public static func data(format: ExportFormat, entries: [ExportEntry], date: Date = Date()) -> Data {
        switch format {
        case .csv:
            return Data(CsvExporter.csv(for: entries).utf8)
        case .json:
            return Data(JsonExporter.json(for: entries, exportedAt: date).utf8)
        case .txt:
            return Data(TextExporter.text(for: entries).utf8)
        case .markdown:
            return Data(MarkdownExporter.markdown(for: entries, exportedAt: date).utf8)
        case .xlsx:
            return XlsxExporter.xlsx(for: entries)
        }
    }
}
