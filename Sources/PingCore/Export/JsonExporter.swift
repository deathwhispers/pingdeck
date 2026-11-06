import Foundation

/// JSON 导出
///
/// 面向脚本消费：字段名与状态值都用英文，缺失的值写成 null 而不是省略。
public enum JsonExporter {
    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    public static func json(for entries: [ExportEntry], exportedAt: Date = Date()) -> String {
        let table = ExportTable(entries: entries)
        let summary = ExportSummary(entries: entries)

        let root: [String: Any] = [
            "exportedAt": iso8601.string(from: exportedAt),
            "summary": [
                "targets": summary.targets,
                "alive": summary.alive,
                "problems": summary.problems,
                "totalSent": summary.totalSent,
            ],
            "targets": table.rows.map { row in
                var object: [String: Any] = [:]
                for (index, value) in row.enumerated() {
                    let column = table.columns[index]
                    object[column.key] = jsonValue(value, format: column.format)
                }
                return object
            },
        ]

        guard let data = try? JSONSerialization.data(
            withJSONObject: root,
            options: [.prettyPrinted, .sortedKeys]
        ) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    private static func jsonValue(_ value: ExportValue, format: ExportColumn.Format) -> Any {
        switch value {
        case .text(let text):
            return text
        case .status(let status):
            return status.rawValue
        case .number(let number):
            return number ?? NSNull()
        case .date(let date):
            return date.map { iso8601.string(from: $0) } ?? NSNull()
        }
    }
}
