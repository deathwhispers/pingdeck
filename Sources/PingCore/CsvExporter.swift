import Foundation

/// CSV 导出
public enum CsvExporter {
    public struct Entry {
        public let target: PingTarget
        public let stats: PingStats

        public init(target: PingTarget, stats: PingStats) {
            self.target = target
            self.stats = stats
        }
    }

    public static let header = [
        "目标", "备注", "状态", "最新延迟(ms)", "平均延迟(ms)",
        "最小延迟(ms)", "最大延迟(ms)", "丢包率(%)", "最后响应时间",
    ]

    public static func csv(for entries: [Entry]) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var lines: [String] = [header.map(escape).joined(separator: ",")]

        for entry in entries {
            let stats = entry.stats
            let fields = [
                entry.target.host,
                entry.target.note,
                stats.status.displayName,
                format(stats.lastLatency),
                format(stats.averageLatency),
                format(stats.minLatency),
                format(stats.maxLatency),
                String(format: "%.2f", stats.lossRate * 100),
                stats.lastResponseAt.map { formatter.string(from: $0) } ?? "",
            ]
            lines.append(fields.map(escape).joined(separator: ","))
        }

        // 带 BOM，保证 Excel 正确识别 UTF-8 中文
        return "\u{FEFF}" + lines.joined(separator: "\r\n") + "\r\n"
    }

    private static func format(_ value: Double?) -> String {
        guard let value else { return "" }
        return String(format: "%.3f", value)
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
}
