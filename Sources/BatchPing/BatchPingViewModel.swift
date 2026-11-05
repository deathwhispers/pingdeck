import Foundation
import SwiftUI
import PingCore

/// 表格中的一行
struct TargetRow: Identifiable {
    let id: UUID
    let target: PingTarget
    let stats: PingStats
}

/// 表格排序：字段 + 方向
struct SortSpec: Equatable {
    enum Field: String, CaseIterable {
        case target
        case last
        case average
        case minimum
        case maximum
        case loss
        case lastResponse

        var title: String {
            switch self {
            case .target: return "目标"
            case .last: return "最新延迟"
            case .average: return "平均延迟"
            case .minimum: return "最小延迟"
            case .maximum: return "最大延迟"
            case .loss: return "丢包率"
            case .lastResponse: return "最后响应时间"
            }
        }

        /// 首次点击该列时的默认方向：目标升序，其余降序（最差的排前面）
        var defaultAscending: Bool {
            self == .target
        }
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

final class BatchPingViewModel: ObservableObject {
    @Published private(set) var targets: [PingTarget] = []
    @Published private(set) var stats: [UUID: PingStats] = [:]
    @Published private(set) var isRunning = false
    @Published var selection: Set<UUID> = []
    @Published var sheet: AppSheet?
    @Published var alert: AppAlert?
    @Published var sort: SortSpec = .default
    @Published var settings: PingSettings = .default {
        didSet {
            guard settings != oldValue else { return }
            engine.updateSettings(Self.engineSettings(from: settings))
            scheduleSave()
        }
    }

    private let engine = PingEngine()
    private var pendingStats: [UUID: PingStats] = [:]
    private var flushTimer: Timer?
    private var saveTimer: Timer?
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    init() {
        let configuration = ConfigStore.load()
        targets = configuration.targets
        settings = configuration.settings

        engine.onStats = { [weak self] id, value in
            DispatchQueue.main.async {
                self?.enqueue(id: id, stats: value)
            }
        }
        engine.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.alert = AppAlert(title: "错误", message: message)
            }
        }
        engine.updateSettings(Self.engineSettings(from: settings))
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

    /// 点击表头：同一列再次点击则反向，否则切换到该列（默认方向见 SortSpec.Field）
    func toggleSort(_ field: SortSpec.Field) {
        if sort.field == field {
            sort.ascending.toggle()
        } else {
            sort = SortSpec(field: field, ascending: field.defaultAscending)
        }
    }

    private func compareRows(_ left: TargetRow, _ right: TargetRow) -> Bool {
        let ordering: ComparisonResult
        switch sort.field {
        case .target:
            ordering = left.target.host.localizedStandardCompare(right.target.host)
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

    var csvEntries: [CsvExporter.Entry] {
        rows.map { CsvExporter.Entry(target: $0.target, stats: $0.stats) }
    }

    var aliveCount: Int {
        rows.filter { $0.stats.status == .alive }.count
    }

    var problemCount: Int {
        rows.filter { $0.stats.status == .timeout || $0.stats.status == .unreachable || $0.stats.status == .error }.count
    }

    var totalSent: Int {
        rows.reduce(0) { $0 + $1.stats.sent }
    }

    func formattedTime(_ date: Date?) -> String {
        guard let date else { return "-" }
        return timeFormatter.string(from: date)
    }

    // MARK: - 目标管理

    func addTarget(host: String, note: String, enabled: Bool) {
        var updated = targets
        updated.append(PingTarget(host: host, note: note, enabled: enabled))
        applyTargets(updated)
    }

    func updateTarget(id: UUID, host: String, note: String, enabled: Bool) {
        var updated = targets
        guard let index = updated.firstIndex(where: { $0.id == id }) else { return }
        updated[index].host = host
        updated[index].note = note
        updated[index].enabled = enabled
        applyTargets(updated)
    }

    func removeTargets(ids: Set<UUID>) {
        let updated = targets.filter { !ids.contains($0.id) }
        selection.formIntersection(Set(updated.map { $0.id }))
        applyTargets(updated)
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

    func openBulkImportSheet() {
        sheet = .bulkImport
    }

    func closeSheet() {
        sheet = nil
    }

    // MARK: - 批量导入

    /// 预览批量导入结果，不改动目标列表
    func previewBulkImport(_ text: String) -> BulkImportParser.Result {
        BulkImportParser.parse(text, existing: Set(targets.map { $0.host.lowercased() }))
    }

    /// 执行批量导入，返回可导入条目与被跳过的行
    @discardableResult
    func importTargets(_ text: String) -> BulkImportParser.Result {
        let result = previewBulkImport(text)
        guard !result.entries.isEmpty else { return result }
        var updated = targets
        for entry in result.entries {
            updated.append(PingTarget(host: entry.host, note: entry.note, enabled: true))
        }
        applyTargets(updated)
        return result
    }

    // MARK: - 运行控制

    func start() {
        engine.start()
        isRunning = true
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

    func saveNow() {
        saveTimer?.invalidate()
        saveTimer = nil
        do {
            try ConfigStore.save(AppConfiguration(targets: targets, settings: settings))
        } catch {
            alert = AppAlert(title: "保存配置失败", message: error.localizedDescription)
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
