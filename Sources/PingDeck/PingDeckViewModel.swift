import Foundation
import SwiftUI
import PingCore

/// 表格中的一行
public typealias PingTableRow = TargetRow
public struct TargetRow: Identifiable, Sendable {
    public let id: UUID
    public let target: PingTarget
    public let stats: PingStats

    public init(id: UUID, target: PingTarget, stats: PingStats) {
        self.id = id
        self.target = target
        self.stats = stats
    }
}

/// 分组折叠分段
public struct TargetGroupSection: Identifiable, Sendable {
    public var id: String { groupName }
    public let groupName: String // 空字符串对应未分组/默认分组
    public let rows: [PingTableRow]
    public let aliveCount: Int
    public let problemCount: Int
    public let totalCount: Int
    public let isCollapsed: Bool

    public init(
        groupName: String,
        rows: [PingTableRow],
        aliveCount: Int,
        problemCount: Int,
        totalCount: Int,
        isCollapsed: Bool
    ) {
        self.groupName = groupName
        self.rows = rows
        self.aliveCount = aliveCount
        self.problemCount = problemCount
        self.totalCount = totalCount
        self.isCollapsed = isCollapsed
    }
}

/// 表格排序：字段 + 方向
struct SortSpec: Equatable {
    enum Field: String, CaseIterable {
        case target
        case status
        case last
        case average
        case minimum
        case maximum
        case loss
        case lastResponse
        case enabled
    }

    var field: Field
    var ascending: Bool

    static let `default` = SortSpec(field: .target, ascending: true)
}

/// 当前要呈现的弹窗
///
/// 只用一个 sheet 承载三种弹窗，避免多个 `.sheet` 修饰符挂在同一视图上互相抢占。
enum AppSheet: Identifiable {
    case editor(TargetEditorDraft)
    case settings
    case bulkImport

    var id: String {
        switch self {
        case .editor(let draft): return "editor-\(draft.id.uuidString)"
        case .settings: return "settings"
        case .bulkImport: return "bulkImport"
        }
    }
}

struct AppAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

/// 新增 / 编辑目标时使用的草稿
struct TargetEditorDraft: Identifiable {
    let id = UUID()
    var host: String
    var note: String
    var enabled: Bool
    var isNew: Bool
    var targetID: UUID?

    static func new() -> TargetEditorDraft {
        TargetEditorDraft(host: "", note: "", enabled: true, isNew: true, targetID: nil)
    }

    static func edit(_ target: PingTarget) -> TargetEditorDraft {
        TargetEditorDraft(host: target.host, note: target.note, enabled: target.enabled, isNew: false, targetID: target.id)
    }
}

/// 批量导入时的处理方式
enum ImportMode: String, CaseIterable, Identifiable {
    /// 保留现有目标，追加新目标
    case append
    /// 丢弃现有目标，用导入内容整体替换
    case replace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .append: return String(localized: L10n.importModeAppend)
        case .replace: return String(localized: L10n.importModeReplace)
        }
    }
}

final class PingDeckViewModel: ObservableObject {
    @Published private(set) var targets: [PingTarget] = []
    @Published private(set) var stats: [UUID: PingStats] = [:]
    @Published private(set) var isRunning = false
    @Published var selection: Set<UUID> = []
    /// 清空全部目标前的确认弹窗
    @Published var confirmingClearAllTargets = false
    @Published var sheet: AppSheet?
    @Published var alert: AppAlert?
    @Published var sort: SortSpec = .default
    @Published public var selectedColorFilter: TargetColorTag? = nil
    @Published public var isGroupedView: Bool = false
    @Published public var collapsedGroups: Set<String> = []
    @Published var settings: PingSettings = .default {
        didSet {
            guard settings != oldValue else { return }
            engine.updateSettings(Self.engineSettings(from: settings))
            scheduleSave()
        }
    }

    private let engine = PingEngine()
    private let store: ConfigStoring
    private let languageDefaults: UserDefaults
    private let relaunch: () -> Void
    private var pendingStats: [UUID: PingStats] = [:]
    private var flushTimer: Timer?
    private var saveTimer: Timer?
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    init(
        configuration: AppConfiguration? = nil,
        store: ConfigStoring = FileConfigStore(),
        languageDefaults: UserDefaults = .standard,
        relaunch: @escaping () -> Void = AppRelauncher.relaunch
    ) {
        self.store = store
        self.languageDefaults = languageDefaults
        self.relaunch = relaunch
        let configuration = configuration ?? store.load()
        targets = configuration.targets
        settings = configuration.settings
        engine.setTargets(targets)

        engine.onStats = { [weak self] id, value in
            DispatchQueue.main.async {
                self?.enqueue(id: id, stats: value)
            }
        }
        engine.onError = { [weak self] issue in
            DispatchQueue.main.async {
                self?.alert = AppAlert(
                    title: String(localized: L10n.alertErrorTitle),
                    message: issue.message
                )
            }
        }
        engine.updateSettings(Self.engineSettings(from: settings))
    }

    convenience init(configStore: ConfigStoring) {
        self.init(configuration: nil, store: configStore)
    }

    deinit {
        flushTimer?.invalidate()
        saveTimer?.invalidate()
    }

    // MARK: - 派生数据

    var rows: [TargetRow] {
        let list = targets.map { TargetRow(id: $0.id, target: $0, stats: stats[$0.id] ?? PingStats()) }
        return list.sorted(by: compareRows)
    }

    public var filteredRows: [PingTableRow] {
        guard let filter = selectedColorFilter else {
            return rows
        }
        return rows.filter { $0.target.colorTag == filter }
    }

    public var availableGroups: [String] {
        let groups = targets.map(\.group).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return Array(Set(groups)).sorted()
    }

    public var colorTagCounts: [TargetColorTag: Int] {
        var counts: [TargetColorTag: Int] = [:]
        for target in targets {
            if let tag = target.colorTag {
                counts[tag, default: 0] += 1
            }
        }
        return counts
    }

    public var groupedSections: [TargetGroupSection] {
        var groupedRows: [String: [PingTableRow]] = [:]
        for row in filteredRows {
            groupedRows[row.target.group, default: []].append(row)
        }

        if groupedRows.isEmpty {
            return []
        }

        let namedKeys = groupedRows.keys.filter { !$0.isEmpty }.sorted()
        var resultKeys = namedKeys
        if groupedRows.keys.contains("") {
            resultKeys.append("")
        }

        return resultKeys.map { name in
            let groupRows = groupedRows[name] ?? []
            let alive = groupRows.filter { $0.stats.status == .alive }.count
            let problem = groupRows.filter {
                $0.stats.status == .timeout || $0.stats.status == .unreachable || $0.stats.status == .error
            }.count
            let total = groupRows.count
            let isCollapsed = collapsedGroups.contains(name)
            return TargetGroupSection(
                groupName: name,
                rows: groupRows,
                aliveCount: alive,
                problemCount: problem,
                totalCount: total,
                isCollapsed: isCollapsed
            )
        }
    }

    public func toggleGroupCollapse(_ groupName: String) {
        if collapsedGroups.contains(groupName) {
            collapsedGroups.remove(groupName)
        } else {
            collapsedGroups.insert(groupName)
        }
    }

    public func collapseAllGroups() {
        collapsedGroups.formUnion(targets.map(\.group))
    }

    public func expandAllGroups() {
        collapsedGroups.removeAll()
    }

    /// 按当前排序规则比较两行
    private func compareRows(_ left: TargetRow, _ right: TargetRow) -> Bool {
        let ordering: ComparisonResult
        switch sort.field {
        case .target:
            ordering = left.target.host.localizedStandardCompare(right.target.host)
        case .status:
            ordering = ordered(left.stats.status.sortRank, right.stats.status.sortRank)
        case .last:
            ordering = ordered(left.stats.lastLatency, right.stats.lastLatency)
        case .average:
            ordering = ordered(left.stats.averageLatency, right.stats.averageLatency)
        case .minimum:
            ordering = ordered(left.stats.minLatency, right.stats.minLatency)
        case .maximum:
            ordering = ordered(left.stats.maxLatency, right.stats.maxLatency)
        case .loss:
            ordering = ordered(left.stats.lossRate, right.stats.lossRate)
        case .lastResponse:
            ordering = ordered(left.stats.lastResponseAt, right.stats.lastResponseAt)
        case .enabled:
            ordering = ordered(left.target.enabled ? 1 : 0, right.target.enabled ? 1 : 0)
        }

        if ordering == .orderedSame {
            return left.target.host.localizedStandardCompare(right.target.host) == .orderedAscending
        }
        return sort.ascending ? ordering == .orderedAscending : ordering == .orderedDescending
    }

    /// 空值一律排在后面，不随升降序翻转
    private func ordered<T: Comparable>(_ left: T?, _ right: T?) -> ComparisonResult {
        switch (left, right) {
        case (nil, nil): return .orderedSame
        case (nil, _): return .orderedDescending
        case (_, nil): return .orderedAscending
        case let (left?, right?):
            if left == right { return .orderedSame }
            return left < right ? .orderedAscending : .orderedDescending
        }
    }

    var aliveCount: Int {
        rows.filter { $0.stats.status == .alive }.count
    }

    /// 启用的目标数量
    var enabledTargetCount: Int {
        targets.filter { $0.enabled }.count
    }

    /// 超出并发上限、需要排队的目标数量
    var queuedTargetCount: Int {
        max(0, enabledTargetCount - settings.maxConcurrent)
    }

    var problemCount: Int {
        rows.filter { $0.stats.status == .timeout || $0.stats.status == .unreachable || $0.stats.status == .error }.count
    }

    /// 所有在线目标的平均延迟（毫秒），无在线目标时为 nil
    var averageAliveLatency: Double? {
        let aliveRows = rows.filter { $0.stats.status == .alive }
        let validRtts = aliveRows.compactMap { $0.stats.averageLatency ?? $0.stats.lastLatency }
        guard !validRtts.isEmpty else { return nil }
        return validRtts.reduce(0, +) / Double(validRtts.count)
    }

    /// 状态异常（超时、不可达、错误）的前 5 个目标
    var recentProblemRows: [PingTableRow] {
        rows.filter { row in
            row.stats.status == .timeout || row.stats.status == .unreachable || row.stats.status == .error
        }
        .sorted { $0.stats.status.sortRank < $1.stats.status.sortRank }
        .prefix(5)
        .map { $0 }
    }

    /// 菜单栏标题显示文本（例如 "在线 42  离线 3"）
    var menuBarTitle: String {
        String(localized: L10n.menuBarSummary(aliveCount, problemCount))
    }

    var totalSent: Int {
        rows.reduce(0) { $0 + $1.stats.sent }
    }

    func formattedTime(_ date: Date?) -> String {
        guard let date else { return "-" }
        return timeFormatter.string(from: date)
    }

    // MARK: - 目标管理

    /// 添加单个目标或网段；网段会展开为多个目标并返回解析结果
    @discardableResult
    public func addTargets(
        host: String,
        note: String,
        enabled: Bool,
        group: String = "",
        colorTag: TargetColorTag? = nil
    ) -> BulkImportParser.Result {
        let result = BulkImportParser.parse(
            host: host,
            note: note,
            group: group,
            colorTag: colorTag,
            existing: Set(targets.map { $0.host.lowercased() })
        )
        guard !result.entries.isEmpty else { return result }

        var updated = targets
        for entry in result.entries {
            updated.append(PingTarget(
                host: entry.host,
                note: entry.note,
                enabled: enabled,
                group: entry.group,
                colorTag: entry.colorTag
            ))
        }
        applyTargets(updated)
        return result
    }

    public func addTarget(
        host: String,
        note: String = "",
        enabled: Bool = true,
        group: String = "",
        colorTag: TargetColorTag? = nil
    ) {
        addTargets(host: host, note: note, enabled: enabled, group: group, colorTag: colorTag)
    }

    public func updateTarget(
        id: UUID,
        host: String,
        note: String,
        enabled: Bool,
        group: String = "",
        colorTag: TargetColorTag? = nil
    ) {
        var updated = targets
        guard let index = updated.firstIndex(where: { $0.id == id }) else { return }
        updated[index].host = host
        updated[index].note = note
        updated[index].enabled = enabled
        updated[index].group = group
        updated[index].colorTag = colorTag
        applyTargets(updated)
    }

    public func updateTarget(_ target: PingTarget) {
        var updated = targets
        guard let index = updated.firstIndex(where: { $0.id == target.id }) else { return }
        updated[index] = target
        applyTargets(updated)
    }

    func removeTargets(ids: Set<UUID>) {
        let updated = targets.filter { !ids.contains($0.id) }
        selection.formIntersection(Set(updated.map { $0.id }))
        applyTargets(updated)
    }

    /// 清空全部目标（与「清空结果」不同：这里连目标本身也删掉）
    func clearAllTargets() {
        clearSelection()
        applyTargets([])
        stats = [:]
    }

    func setEnabled(id: UUID, enabled: Bool) {
        var updated = targets
        guard let index = updated.firstIndex(where: { $0.id == id }) else { return }
        updated[index].enabled = enabled
        applyTargets(updated)
    }

    private func applyTargets(_ updated: [PingTarget]) {
        targets = updated
        engine.setTargets(updated)
        scheduleSave()
    }

    // MARK: - 选中状态

    /// 选中由 List 的原生语义维护（点击 / ⌘ 点击 / ⇧ 点击），这里只提供全选与清空
    func selectAll() {
        selection = Set(targets.map { $0.id })
    }

    func clearSelection() {
        selection.removeAll()
    }

    /// 导出全部目标（不受选中影响）
    var allEntries: [ExportEntry] {
        rows.map { ExportEntry(target: $0.target, stats: $0.stats) }
    }

    /// 只导出选中的目标
    var selectedEntries: [ExportEntry] {
        rows.filter { selection.contains($0.id) }
            .map { ExportEntry(target: $0.target, stats: $0.stats) }
    }

    // MARK: - 弹窗

    func openNewTargetSheet() {
        sheet = .editor(.new())
    }

    func openEditTargetSheet() {
        guard let id = selection.first,
              let target = targets.first(where: { $0.id == id }) else { return }
        sheet = .editor(.edit(target))
    }

    func openSettingsSheet() {
        sheet = .settings
    }

    @discardableResult
    func applyLanguage(_ language: AppLanguage, relaunch shouldRelaunch: Bool) -> Bool {
        guard settings.language != language else { return true }
        let previous = settings.language
        settings.language = language
        guard saveNow() else {
            settings.language = previous
            return false
        }
        LanguagePreference.apply(language, defaults: languageDefaults)
        if shouldRelaunch {
            relaunch()
        }
        return true
    }

    func openBulkImportSheet() {
        sheet = .bulkImport
    }

    func closeSheet() {
        sheet = nil
    }

    // MARK: - 批量导入

    /// 预览批量导入结果，不改动目标列表
    func previewBulkImport(
        _ text: String,
        mode: ImportMode = .append,
        defaultGroup: String = "",
        defaultColorTag: TargetColorTag? = nil
    ) -> BulkImportParser.Result {
        // 替换模式不与现有目标去重，因为现有目标本来就会被丢弃
        let existing = mode == .append ? Set(targets.map { $0.host.lowercased() }) : []
        return BulkImportParser.parse(
            text,
            existing: existing,
            defaultGroup: defaultGroup,
            defaultColorTag: defaultColorTag
        )
    }

    /// 执行批量导入，返回可导入条目与被跳过的行
    @discardableResult
    func importTargets(
        _ text: String,
        mode: ImportMode = .append,
        defaultGroup: String = "",
        defaultColorTag: TargetColorTag? = nil
    ) -> BulkImportParser.Result {
        let result = previewBulkImport(
            text,
            mode: mode,
            defaultGroup: defaultGroup,
            defaultColorTag: defaultColorTag
        )
        guard !result.entries.isEmpty else { return result }
        var updated = mode == .append ? targets : []
        for entry in result.entries {
            updated.append(PingTarget(
                host: entry.host,
                note: entry.note,
                enabled: true,
                group: entry.group,
                colorTag: entry.colorTag
            ))
        }
        clearSelection()
        applyTargets(updated)
        return result
    }

    // MARK: - 运行控制

    func start() {
        adjustConcurrencyForStart()
        engine.start()
        isRunning = true
    }

    /// 启动时把并发数提升到启用目标数，避免大量目标排队等待轮换。
    /// 只升不降；超过上限的部分继续按轮换周期探测。
    func adjustConcurrencyForStart() {
        let enabled = enabledTargetCount
        let desired = min(enabled, PingSettings.maxConcurrentLimit)
        guard desired > settings.maxConcurrent else { return }

        let previous = settings.maxConcurrent
        settings.maxConcurrent = desired

        let message: String
        if enabled > desired {
            message = String(
                localized: L10n.alertConcurrencyAtLimit(
                    enabled,
                    previous,
                    desired,
                    PingSettings.maxConcurrentLimit
                )
            )
        } else {
            message = String(
                localized: L10n.alertConcurrencyBelowLimit(enabled, previous, desired)
            )
        }
        alert = AppAlert(title: String(localized: L10n.alertConcurrencyTitle), message: message)
    }

    func stop() {
        engine.stop()
        isRunning = false
    }

    func toggleRun() {
        isRunning ? stop() : start()
    }

    func refresh() {
        guard isRunning else {
            start()
            return
        }
        engine.refresh()
    }

    func clearResults() {
        engine.clearStats()
        stats = [:]
    }

    /// 供测试或内部更新目标的统计结果
    func setStats(for id: UUID, _ newStats: PingStats) {
        stats[id] = newStats
    }

    // MARK: - 统计刷新

    private func enqueue(id: UUID, stats value: PingStats) {
        pendingStats[id] = value
        scheduleFlush()
    }

    private func scheduleFlush() {
        guard flushTimer == nil else { return }
        flushTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            self?.flushStats()
        }
    }

    private func flushStats() {
        flushTimer = nil
        guard !pendingStats.isEmpty else { return }
        for (id, value) in pendingStats {
            stats[id] = value
        }
        pendingStats.removeAll()
    }

    // MARK: - 配置保存

    private func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.saveNow()
        }
    }

    @discardableResult
    func saveNow() -> Bool {
        saveTimer?.invalidate()
        saveTimer = nil
        do {
            try store.save(AppConfiguration(targets: targets, settings: settings))
            return true
        } catch {
            alert = AppAlert(
                title: String(localized: L10n.alertSaveFailedTitle),
                message: error.localizedDescription
            )
            return false
        }
    }

    private static func engineSettings(from settings: PingSettings) -> PingEngine.Settings {
        PingEngine.Settings(
            interval: settings.interval,
            timeout: settings.timeout,
            maxConcurrent: settings.maxConcurrent,
            rotationInterval: settings.rotationInterval
        )
    }
}
