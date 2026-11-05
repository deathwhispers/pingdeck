import Foundation

/// 并发受限的 ping 调度器
///
/// 每个目标对应一个持续运行的 `/sbin/ping` 子进程，发包节奏由内核定时器控制，
/// 因此常驻监控几乎不消耗 CPU。同时运行的进程数受 `maxConcurrent` 限制；
/// 目标数量超过上限时按 `rotationInterval` 轮换，保证所有目标都能被覆盖。
public final class PingEngine {
    public struct Settings: Sendable {
        public var interval: TimeInterval
        public var timeout: TimeInterval
        public var maxConcurrent: Int
        public var rotationInterval: TimeInterval

        public init(interval: TimeInterval = 1.0,
                    timeout: TimeInterval = 2.0,
                    maxConcurrent: Int = 16,
                    rotationInterval: TimeInterval = 30) {
            self.interval = max(0.2, interval)
            self.timeout = max(0.5, timeout)
            self.maxConcurrent = max(1, maxConcurrent)
            self.rotationInterval = max(0, rotationInterval)
        }
    }

    private let queue = DispatchQueue(label: "com.batchping.engine")
    private var settings = Settings()
    private var targets: [UUID: PingTarget] = [:]
    private var processes: [UUID: PingProcess] = [:]
    private var startedAt: [UUID: Date] = [:]
    private var pending: [UUID] = []
    private var stats: [UUID: PingStats] = [:]
    private var lastFailure: [UUID: String] = [:]
    /// 记录被主动停止的进程实例，用于区分“主动停止”和“异常退出”
    private var intentionalStops: [UUID: PingProcess] = [:]
    private var timer: DispatchSourceTimer?
    private var running = false

    /// 统计更新回调（在引擎内部队列上触发）
    public var onStats: ((UUID, PingStats) -> Void)?
    /// 引擎级错误回调（例如无法启动 ping 进程）
    public var onError: ((String) -> Void)?

    public init() {}

    // MARK: - 对外接口

    public func start() {
        queue.async {
            guard !self.running else { return }
            self.running = true
            self.pending = self.enabledTargetIDs()
            self.startTimerLocked()
            self.pumpLocked()
        }
    }

    public func stop() {
        queue.async {
            self.running = false
            self.stopTimerLocked()
            self.stopAllLocked()
            self.pending = []
            let ids = Array(self.stats.keys)
            for id in ids {
                var value = self.stats[id] ?? PingStats()
                if value.status == .running || value.status == .pending {
                    value.status = .idle
                }
                self.stats[id] = value
                self.emitLocked(id)
            }
        }
    }

    /// 立即对所有目标重新发起探测（保留历史统计）
    public func refresh() {
        queue.async {
            guard self.running else { return }
            self.stopAllLocked()
            self.pending = self.enabledTargetIDs()
            self.pumpLocked()
        }
    }

    /// 清空所有统计结果
    public func clearStats() {
        queue.async {
            let ids = Array(self.stats.keys)
            for id in ids {
                self.stats[id] = PingStats()
                self.emitLocked(id)
            }
        }
    }

    public func setTargets(_ newTargets: [PingTarget]) {
        queue.async {
            self.applyTargetsLocked(newTargets)
        }
    }

    public func updateSettings(_ newSettings: Settings) {
        queue.async {
            let needsRestart = newSettings.interval != self.settings.interval || newSettings.timeout != self.settings.timeout
            self.settings = newSettings
            guard self.running, needsRestart else { return }
            self.stopAllLocked()
            self.pending = self.enabledTargetIDs()
            self.pumpLocked()
        }
    }

    public func snapshot() -> [UUID: PingStats] {
        queue.sync { stats }
    }

    // MARK: - 内部实现（全部在 queue 上串行执行）

    private func enabledTargetIDs() -> [UUID] {
        targets.values.filter { $0.enabled }.map { $0.id }
    }

    private func applyTargetsLocked(_ newTargets: [PingTarget]) {
        var newMap: [UUID: PingTarget] = [:]
        for target in newTargets { newMap[target.id] = target }
        targets = newMap

        // 被停用的目标：终止进程并标记为已停用（包括从未启动过的目标）
        for target in newTargets where !target.enabled {
            if processes[target.id] != nil {
                stopProcessLocked(id: target.id)
            }
            pending.removeAll { $0 == target.id }
            var value = stats[target.id] ?? PingStats()
            if value.status != .disabled {
                value.status = .disabled
                value.message = "已停用"
                stats[target.id] = value
                emitLocked(target.id)
            }
        }

        // 被删除的目标：终止进程并清理统计
        let removed = processes.keys.filter { newMap[$0] == nil }
        for id in removed {
            stopProcessLocked(id: id)
        }

        let staleStats = stats.keys.filter { newMap[$0] == nil }
        for id in staleStats {
            stats.removeValue(forKey: id)
            lastFailure.removeValue(forKey: id)
        }
        pending.removeAll { newMap[$0] == nil }

        guard running else { return }
        // 新启用或刚恢复启用的目标重新入队
        for target in newTargets where target.enabled && processes[target.id] == nil && !pending.contains(target.id) {
            pending.append(target.id)
        }
        pumpLocked()
    }

    private func pumpLocked() {
        guard running else { return }
        let limit = settings.maxConcurrent

        // 目标数超过并发上限：把最早启动的目标轮换下来，让排队目标获得探测机会
        if !pending.isEmpty, processes.count >= limit, settings.rotationInterval > 0 {
            if let oldest = startedAt.min(by: { $0.value < $1.value }),
               Date().timeIntervalSince(oldest.value) >= settings.rotationInterval {
                stopProcessLocked(id: oldest.key)
                pending.removeAll { $0 == oldest.key }
                pending.append(oldest.key)
            }
        }

        while processes.count < limit, !pending.isEmpty {
            let id = pending.removeFirst()
            guard let target = targets[id], target.enabled else { continue }
            startProcessLocked(for: target)
        }
    }

    private func startProcessLocked(for target: PingTarget) {
        let process = PingProcess(
            host: target.host,
            configuration: .init(interval: settings.interval, timeout: settings.timeout)
        )
        process.onEvent = { [weak self] event in
            self?.queue.async { self?.handleEventLocked(event, id: target.id) }
        }
        process.onExit = { [weak self, weak process] code in
            guard let self, let process else { return }
            self.queue.async { self.handleExitLocked(id: target.id, code: code, process: process) }
        }

        do {
            try process.start()
            processes[target.id] = process
            startedAt[target.id] = Date()
            var value = stats[target.id] ?? PingStats()
            value.beginSession(sentBefore: value.sent)
            value.status = .running
            value.message = ""
            stats[target.id] = value
            emitLocked(target.id)
        } catch {
            var value = stats[target.id] ?? PingStats()
            value.status = .error
            value.message = error.localizedDescription
            stats[target.id] = value
            emitLocked(target.id)
            onError?("无法启动对 \(target.host) 的探测：\(error.localizedDescription)")
        }
    }

    private func handleEventLocked(_ event: PingEvent, id: UUID) {
        var value = stats[id] ?? PingStats()
        switch event {
        case .reply(let seq, let latency):
            value.recordSuccess(latency, at: Date(), seq: seq)
        case .timeout(let seq):
            value.recordTimeout(seq: seq)
        case .unreachable(let text):
            value.recordUnreachable(text, seq: nil)
        case .failure(let text):
            value.recordFailure(text)
            lastFailure[id] = text
            stopProcessLocked(id: id)
        case .info:
            return
        }
        stats[id] = value
        emitLocked(id)
    }

    private func handleExitLocked(id: UUID, code: Int32, process: PingProcess) {
        // 目标可能已经被轮换并重新启动，此时这个退出回调属于旧进程，不能影响新进程
        if processes[id] === process {
            processes.removeValue(forKey: id)
            startedAt.removeValue(forKey: id)
        }
        let wasIntentional = intentionalStops.removeValue(forKey: id) === process
        let failure = lastFailure.removeValue(forKey: id)

        if let failure {
            var value = stats[id] ?? PingStats()
            value.status = .error
            value.message = failure
            stats[id] = value
            emitLocked(id)
            pumpLocked()
            return
        }

        if wasIntentional {
            pumpLocked()
            return
        }

        if code != 0 {
            var value = stats[id] ?? PingStats()
            value.status = .error
            value.message = "ping 进程异常退出（代码 \(code)）"
            stats[id] = value
            emitLocked(id)
        }
        pumpLocked()
    }

    private func stopProcessLocked(id: UUID) {
        guard let process = processes[id] else { return }
        intentionalStops[id] = process
        process.stop()
        processes.removeValue(forKey: id)
        startedAt.removeValue(forKey: id)
    }

    private func stopAllLocked() {
        let ids = Array(processes.keys)
        for id in ids {
            intentionalStops[id] = processes[id]
            processes[id]?.stop()
        }
        processes.removeAll()
        startedAt.removeAll()
    }

    private func emitLocked(_ id: UUID) {
        onStats?(id, stats[id] ?? PingStats())
    }

    private func startTimerLocked() {
        stopTimerLocked()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 1, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            self?.tickLocked()
        }
        timer.resume()
        self.timer = timer
    }

    /// 每秒一次的维护动作：判定静默超时、补充进程槽位
    private func tickLocked() {
        applyStaleTimeoutLocked()
        pumpLocked()
    }

    /// 超过「单包超时」时间没有收到回包的目标标记为超时
    private func applyStaleTimeoutLocked() {
        let now = Date()
        let ids = Array(processes.keys)
        for id in ids {
            guard var value = stats[id] else { continue }
            guard let reference = value.lastResponseAt ?? startedAt[id] else { continue }
            guard now.timeIntervalSince(reference) > settings.timeout else { continue }
            guard value.status == .alive || value.status == .running else { continue }
            value.status = .timeout
            stats[id] = value
            emitLocked(id)
        }
    }

    private func stopTimerLocked() {
        timer?.cancel()
        timer = nil
    }
}
