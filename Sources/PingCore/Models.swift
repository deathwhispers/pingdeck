import Foundation

/// 目标颜色标签
public enum TargetColorTag: String, Codable, CaseIterable, Hashable, Sendable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case gray
}

/// 一个 Ping 目标（IP 或域名）
public struct PingTarget: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var host: String
    public var note: String
    public var enabled: Bool
    public var group: String
    public var colorTag: TargetColorTag?

    public init(
        id: UUID = UUID(),
        host: String,
        note: String = "",
        enabled: Bool = true,
        group: String = "",
        colorTag: TargetColorTag? = nil
    ) {
        self.id = id
        self.host = host
        self.note = note
        self.enabled = enabled
        self.group = group
        self.colorTag = colorTag
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case host
        case note
        case enabled
        case group
        case colorTag
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        host = try container.decode(String.self, forKey: .host)
        note = (try? container.decodeIfPresent(String.self, forKey: .note)) ?? ""
        enabled = (try? container.decodeIfPresent(Bool.self, forKey: .enabled)) ?? true
        group = (try? container.decodeIfPresent(String.self, forKey: .group)) ?? ""
        colorTag = try? container.decodeIfPresent(TargetColorTag.self, forKey: .colorTag)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(host, forKey: .host)
        try container.encode(note, forKey: .note)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(group, forKey: .group)
        try container.encodeIfPresent(colorTag, forKey: .colorTag)
    }
}

/// 单个目标当前的连通状态
public enum TargetStatus: String, Codable, Sendable {
    case idle         // 未开始
    case pending      // 排队中（等待并发槽位）
    case running      // 探测中，等待首个响应
    case alive        // 正常
    case timeout      // 超时 / 丢包
    case unreachable  // 网络不可达
    case disabled     // 目标被停用
    case error        // 错误（目标无效等）

    /// 排序用的严重程度：越靠前越健康
    public var sortRank: Int {
        switch self {
        case .alive: return 0
        case .running, .pending, .idle: return 1
        case .timeout: return 2
        case .unreachable: return 3
        case .error: return 4
        case .disabled: return 5
        }
    }
}

/// 由应用生成的状态细节；来自 ping 的原始输出仍放在 `message`
public enum PingStatusDetail: Equatable, Sendable, Codable {
    case disabled
    case launchFailed(host: String, error: PingProcessError)
    case processExited(code: Int32)
}

/// 目标的统计结果
///
/// 收发包计数以 ping 输出的 `icmp_seq` 为准：seq 是每个目标内单调递增的包序号，
/// 因此 `sent = seqBase + seq + 1` 可以准确反映实际发出的包数，回包序号出现跳号
/// 即说明中间发生了丢包，不依赖 ping 是否输出超时行。
public struct PingStats: Codable, Sendable, Equatable {
    public var status: TargetStatus = .idle
    public var message: String = ""
    public var detail: PingStatusDetail?
    public var sent: Int = 0
    public var received: Int = 0
    public var lastLatency: Double?
    public var minLatency: Double?
    public var maxLatency: Double?
    public var latencySum: Double = 0
    public var lastResponseAt: Date?
    /// 进程重启前的已发送包数，用于衔接新的 icmp_seq 序列
    public var seqBase: Int = 0

    public init() {}

    public var averageLatency: Double? {
        received > 0 ? latencySum / Double(received) : nil
    }

    public var lossRate: Double {
        sent > 0 ? Double(sent - received) / Double(sent) : 0
    }

    /// 开始一段新的探测会话（ping 进程重启时调用）
    public mutating func beginSession(sentBefore: Int) {
        seqBase = sentBefore
    }

    public mutating func recordSuccess(_ latency: Double, at date: Date, seq: Int?) {
        received += 1
        countSent(seq: seq)
        latencySum += latency
        lastLatency = latency
        if let current = minLatency {
            minLatency = Swift.min(current, latency)
        } else {
            minLatency = latency
        }
        if let current = maxLatency {
            maxLatency = Swift.max(current, latency)
        } else {
            maxLatency = latency
        }
        lastResponseAt = date
        status = .alive
        message = ""
        detail = nil
    }

    public mutating func recordTimeout(seq: Int?) {
        countSent(seq: seq)
        status = .timeout
        detail = nil
    }

    public mutating func recordUnreachable(_ text: String, seq: Int?) {
        countSent(seq: seq)
        status = .unreachable
        message = text
        detail = nil
    }

    public mutating func recordFailure(_ text: String) {
        status = .error
        message = text
        detail = nil
    }

    private mutating func countSent(seq: Int?) {
        if let seq {
            sent = Swift.max(sent, seqBase + seq + 1)
        } else {
            sent += 1
        }
    }
}

/// 界面外观
public enum AppearanceMode: String, Codable, CaseIterable, Hashable, Sendable {
    /// 跟随系统外观
    case system
    /// 始终浅色
    case light
    /// 始终深色
    case dark
}

/// 应用语言
public enum AppLanguage: String, Codable, CaseIterable, Hashable, Sendable {
    /// 跟随系统
    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"
    case japanese = "ja"

    /// 写入 AppleLanguages 的语言代码；跟随系统时返回 nil
    public var localeIdentifier: String? {
        self == .system ? nil : rawValue
    }
}

/// 主窗口关闭时的处理行为
public enum WindowCloseBehavior: String, Codable, CaseIterable, Sendable {
    case ask              // 首次未决定，关闭时弹窗询问
    case keepRunning      // 保持后台常驻继续探测
    case terminate        // 直接退出应用
}

/// 菜单栏与后台生命周期偏好
public struct MenuBarSettings: Codable, Equatable, Sendable {
    public var showTextLabel: Bool
    public var closeBehavior: WindowCloseBehavior

    public init(
        showTextLabel: Bool = true,
        closeBehavior: WindowCloseBehavior = .ask
    ) {
        self.showTextLabel = showTextLabel
        self.closeBehavior = closeBehavior
    }
}

/// 刘海灵动岛偏好设置
public struct NotchIslandSettings: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var showMetrics: Bool
    public var showRecentProblems: Bool
    public var showQuickControls: Bool

    public init(
        enabled: Bool = true,
        showMetrics: Bool = true,
        showRecentProblems: Bool = true,
        showQuickControls: Bool = true
    ) {
        self.enabled = enabled
        self.showMetrics = showMetrics
        self.showRecentProblems = showRecentProblems
        self.showQuickControls = showQuickControls
    }

    private enum CodingKeys: String, CodingKey {
        case enabled
        case showMetrics
        case showRecentProblems
        case showQuickControls
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = (try? container.decodeIfPresent(Bool.self, forKey: .enabled)) ?? true
        showMetrics = (try? container.decodeIfPresent(Bool.self, forKey: .showMetrics)) ?? true
        showRecentProblems = (try? container.decodeIfPresent(Bool.self, forKey: .showRecentProblems)) ?? true
        showQuickControls = (try? container.decodeIfPresent(Bool.self, forKey: .showQuickControls)) ?? true
    }
}

/// 运行参数
public struct PingSettings: Codable, Sendable, Equatable {
    /// 最大并发数上限
    public static let maxConcurrentLimit = 512

    /// 发包间隔（秒），macOS 下非 root 建议 >= 0.2
    public var interval: Double
    /// 单包等待超时（秒）
    public var timeout: Double
    /// 同时运行的 ping 进程上限
    public var maxConcurrent: Int
    /// 目标数超过并发上限时的轮换周期（秒），0 表示不轮换
    public var rotationInterval: Double
    /// 界面外观
    public var appearance: AppearanceMode
    /// 应用语言
    public var language: AppLanguage
    /// 菜单栏与后台常驻偏好
    public var menuBar: MenuBarSettings
    /// 灵动岛偏好
    public var notchIsland: NotchIslandSettings

    public init(interval: Double = 1.0,
                timeout: Double = 2.0,
                maxConcurrent: Int = 16,
                rotationInterval: Double = 30,
                appearance: AppearanceMode = .system,
                language: AppLanguage = .system,
                menuBar: MenuBarSettings = MenuBarSettings(),
                notchIsland: NotchIslandSettings = NotchIslandSettings()) {
        self.interval = interval
        self.timeout = timeout
        self.maxConcurrent = max(1, maxConcurrent)
        self.rotationInterval = max(0, rotationInterval)
        self.appearance = appearance
        self.language = language
        self.menuBar = menuBar
        self.notchIsland = notchIsland
    }

    private enum CodingKeys: String, CodingKey {
        case interval
        case timeout
        case maxConcurrent
        case rotationInterval
        case appearance
        case language
        case menuBar
        case notchIsland
    }

    /// 手写解码：旧版本配置没有 appearance / language / menuBar / notchIsland 字段（或值未知）时回落到默认值。
    /// 不能让整个配置解码失败，否则用户保存的目标会全部丢失。
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        interval = try container.decode(Double.self, forKey: .interval)
        timeout = try container.decode(Double.self, forKey: .timeout)
        maxConcurrent = try container.decode(Int.self, forKey: .maxConcurrent)
        rotationInterval = try container.decode(Double.self, forKey: .rotationInterval)
        appearance = (try? container.decodeIfPresent(AppearanceMode.self, forKey: .appearance)) ?? .system
        language = (try? container.decodeIfPresent(AppLanguage.self, forKey: .language)) ?? .system
        menuBar = (try? container.decodeIfPresent(MenuBarSettings.self, forKey: .menuBar)) ?? MenuBarSettings()
        notchIsland = (try? container.decodeIfPresent(NotchIslandSettings.self, forKey: .notchIsland)) ?? NotchIslandSettings()
    }

    public static let `default` = PingSettings()
}

/// 持久化到磁盘的完整配置
public struct AppConfiguration: Codable, Sendable {
    public var targets: [PingTarget]
    public var settings: PingSettings

    public init(targets: [PingTarget] = [], settings: PingSettings = .default) {
        self.targets = targets
        self.settings = settings
    }
}
