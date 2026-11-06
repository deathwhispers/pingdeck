import Foundation

/// 导出条目：一个目标及其统计结果
public struct ExportEntry: Sendable {
    public let target: PingTarget
    public let stats: PingStats

    public init(target: PingTarget, stats: PingStats) {
        self.target = target
        self.stats = stats
    }
}

/// 表格单元格的值
///
/// 保留类型是为了让 xlsx 能写出真正的数字单元格，而不是把数字当字符串存。
public enum ExportValue: Equatable, Sendable {
    /// 文本
    case text(String)
    /// 状态：显示时用中文名，机器可读格式用枚举原值
    case status(TargetStatus)
    /// 数值（延迟毫秒、丢包率百分点）；nil 表示该值缺失
    case number(Double?)
    /// 时间；nil 表示尚未收到过响应
    case date(Date?)
}

/// 导出列的定义
public struct ExportColumn: Sendable {
    /// 列的取值类型，决定各格式如何渲染这个值
    public enum Format: Sendable {
        /// 文本，原样输出
        case text
        /// 状态：文本格式显示中文名，机器可读格式显示英文枚举值
        case status
        /// 毫秒，保留三位小数
        case milliseconds
        /// 百分点，保留两位小数
        case percent
        /// 时间，格式为 yyyy-MM-dd HH:mm:ss
        case dateTime
    }

    /// 表头标题（中文，用于表格展示）
    public let title: String
    /// 机器可读的字段名（英文，用于 JSON）
    public let key: String
    public let format: Format

    public init(title: String, key: String, format: Format) {
        self.title = title
        self.key = key
        self.format = format
    }
}

/// 所有导出格式共用的表格模型
///
/// CSV / TXT / Markdown / JSON / XLSX 都从这张表派生，避免各格式之间出现列偏差。
public struct ExportTable: Sendable {
    /// 列定义，所有格式共用
    public static let columns: [ExportColumn] = [
        ExportColumn(title: "目标", key: "host", format: .text),
        ExportColumn(title: "备注", key: "note", format: .text),
        ExportColumn(title: "状态", key: "status", format: .status),
        ExportColumn(title: "最新延迟(ms)", key: "lastLatencyMs", format: .milliseconds),
        ExportColumn(title: "平均延迟(ms)", key: "averageLatencyMs", format: .milliseconds),
        ExportColumn(title: "最小延迟(ms)", key: "minLatencyMs", format: .milliseconds),
        ExportColumn(title: "最大延迟(ms)", key: "maxLatencyMs", format: .milliseconds),
        ExportColumn(title: "丢包率(%)", key: "lossRatePercent", format: .percent),
        ExportColumn(title: "最后响应时间", key: "lastResponseAt", format: .dateTime),
    ]

    public let columns: [ExportColumn]
    public let rows: [[ExportValue]]

    public init(entries: [ExportEntry]) {
        columns = Self.columns
        rows = entries.map { entry in
            let stats = entry.stats
            return [
                .text(entry.target.host),
                .text(entry.target.note),
                .status(stats.status),
                .number(stats.lastLatency),
                .number(stats.averageLatency),
                .number(stats.minLatency),
                .number(stats.maxLatency),
                .number(stats.lossRate * 100),
                .date(stats.lastResponseAt),
            ]
        }
    }

    /// 某一列在全部行上的显示文本
    public func displayValues(at column: Int) -> [String] {
        rows.map { row in
            ExportValueFormatter.display(row[column], format: columns[column].format)
        }
    }
}

/// 导出汇总：只出现在 JSON 与 Markdown 中
public struct ExportSummary: Sendable {
    public let targets: Int
    public let alive: Int
    public let problems: Int
    public let totalSent: Int

    public init(entries: [ExportEntry]) {
        targets = entries.count
        alive = entries.filter { $0.stats.status == .alive }.count
        problems = entries.filter {
            [.timeout, .unreachable, .error].contains($0.stats.status)
        }.count
        totalSent = entries.reduce(0) { $0 + $1.stats.sent }
    }

    /// 「目标 12 · 正常 9 · 异常 3 · 累计发包 480」形式的摘要
    public var description: String {
        "目标 \(targets) · 正常 \(alive) · 异常 \(problems) · 累计发包 \(totalSent)"
    }
}

/// 把单元格值转成各格式共用的显示文本
public enum ExportValueFormatter {
    /// 时间格式，与历史 CSV 输出一致
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    public static func display(_ value: ExportValue, format: ExportColumn.Format) -> String {
        switch format {
        case .text:
            if case .text(let text) = value { return text }
            return ""
        case .status:
            if case .status(let status) = value { return status.displayName }
            return ""
        case .milliseconds:
            if case .number(let number?) = value { return String(format: "%.3f", number) }
            return ""
        case .percent:
            if case .number(let number?) = value { return String(format: "%.2f", number) }
            return ""
        case .dateTime:
            if case .date(let date?) = value { return dateFormatter.string(from: date) }
            return ""
        }
    }
}
