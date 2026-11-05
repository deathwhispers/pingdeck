import Foundation
import SwiftUI
import PingCore

/// 表格中的一行
struct TargetRow: Identifiable {
    let id: UUID
    let target: PingTarget
    let stats: PingStats
}

enum SortMode: String, CaseIterable, Identifiable {
    case original
    case host
    case latency
    case loss

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original: return "添加顺序"
        case .host: return "目标名称"
        case .latency: return "延迟从高到低"
        case .loss: return "丢包率从高到低"
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

enum TargetValidator {
    static func validate(_ host: String) -> String? {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "目标不能为空" }
        if trimmed.contains("://") { return "请不要填写协议前缀，例如 http://" }
        if trimmed.contains("/") { return "请只填写主机名或 IP，不要带路径" }
        if trimmed.contains(" ") { return "目标不能包含空格" }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_:[]%")
        if trimmed.rangeOfCharacter(from: allowed.inverted) != nil {
            return "目标包含非法字符"
        }
        return nil
    }
}

final class BatchPingViewModel: ObservableObject {
    @Published private(set) var targets: [PingTarget] = []
    @Published private(set) var stats: [UUID: PingStats] = [:]
    @Published private(set) var isRunning = false
    @Published var selection: Set<UUID> = []
    @Published var editorDraft: TargetEditorDraft?
    @Published var showingSettings = false
    @Published var alert: AppAlert?
    @Published var sortMode: SortMode = .original
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
        switch sortMode {
        case .original:
            return list
        case .host:
            return list.sorted { $0.target.host.localizedStandardCompare($1.target.host) == .orderedAscending }
        case .latency:
            return list.sorted { left, right in
                switch (left.stats.lastLatency, right.stats.lastLatency) {
                case let (a?, b?): return a == b ? left.target.host < right.target.host : a > b
                case (nil, _?): return false
                case (_?, nil): return true
                default: return left.target.host < right.target.host
                }
            }
        case .loss:
            return list.sorted { left, right in
                if left.stats.lossRate == right.stats.lossRate { return left.target.host < right.target.host }
                return left.stats.lossRate > right.stats.lossRate
            }
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
