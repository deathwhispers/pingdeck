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
    /// 状态：由导出标签决定显示名，机器可读格式使用枚举原值
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
        /// 状态：文本格式使用本地化名称，机器可读格式使用英文枚举值
        case status
        /// 毫秒，保留三位小数
        case milliseconds
        /// 百分点，保留两位小数
        case percent
        /// 时间，格式为 yyyy-MM-dd HH:mm:ss
        case dateTime
    }

    /// 表头标题
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

/// 导出文案：由 UI 层按当前语言提供
public struct ExportLabels {
    public var columnTitles: [String]
    public var statusName: (TargetStatus) -> String
    public var summary: (ExportSummary) -> String
    public var markdownTitle: String
    public var exportedAtLabel: String

    public init(
        columnTitles: [String],
        statusName: @escaping (TargetStatus) -> String,
        summary: @escaping (ExportSummary) -> String,
        markdownTitle: String,
        exportedAtLabel: String
    ) {
        self.columnTitles = columnTitles
        self.statusName = statusName
        self.summary = summary
        self.markdownTitle = markdownTitle
        self.exportedAtLabel = exportedAtLabel
    }
}

/// 所有导出格式共用的表格模型
///
/// CSV / TXT / Markdown / JSON / XLSX 都从这张表派生，避免各格式之间出现列偏差。
public struct ExportTable: Sendable {
    private static let definitions: [(key: String, format: ExportColumn.Format)] = [
        ("host", .text),
        ("note", .text),
        ("status", .status),
        ("lastLatencyMs", .milliseconds),
        ("averageLatencyMs", .milliseconds),
        ("minLatencyMs", .milliseconds),
        ("maxLatencyMs", .milliseconds),
        ("lossRatePercent", .percent),
        ("lastResponseAt", .dateTime),
    ]

    public let columns: [ExportColumn]
    public let rows: [[ExportValue]]

    public init(entries: [ExportEntry], labels: ExportLabels) {
        precondition(
            labels.columnTitles.count == Self.definitions.count,
            "ExportLabels.columnTitles 数量必须为 \(Self.definitions.count)"
        )
        columns = zip(Self.definitions, labels.columnTitles).map { definition, title in
            ExportColumn(title: title, key: definition.key, format: definition.format)
        }
        rows = Self.makeRows(entries)
    }

    /// JSON 只使用 key 与格式，不需要展示标题
    init(entries: [ExportEntry]) {
        columns = Self.definitions.map { definition in
            ExportColumn(title: definition.key, key: definition.key, format: definition.format)
        }
        rows = Self.makeRows(entries)
    }

    private static func makeRows(_ entries: [ExportEntry]) -> [[ExportValue]] {
        entries.map { entry in
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
    public func displayValues(at column: Int, labels: ExportLabels) -> [String] {
        rows.map { row in
            ExportValueFormatter.display(row[column], format: columns[column].format, labels: labels)
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

    public static func display(
        _ value: ExportValue,
        format: ExportColumn.Format,
        labels: ExportLabels
    ) -> String {
        switch format {
        case .text:
            if case .text(let text) = value { return text }
            return ""
        case .status:
            if case .status(let status) = value { return labels.statusName(status) }
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
