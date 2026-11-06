import XCTest
@testable import PingCore

/// 验证引擎的并发上限与轮换调度
final class EngineSchedulingTests: XCTestCase {
    private func waitUntil(_ condition: () -> Bool, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return condition()
    }

    /// 超过并发上限时，只有槽位数内的目标会被真正探测
    func testConcurrencyLimitKeepsExtraTargetsIdle() {
        let engine = PingEngine()
        engine.updateSettings(PingEngine.Settings(interval: 0.3, timeout: 1, maxConcurrent: 1, rotationInterval: 0))

        let targets = (1...3).map { PingTarget(host: "127.0.0.1", note: "目标\($0)") }
        let lock = NSLock()
        var sent: [UUID: Int] = [:]
        engine.onStats = { id, stats in
            lock.lock()
            sent[id] = max(sent[id] ?? 0, stats.sent)
            lock.unlock()
        }
        engine.setTargets(targets)
        engine.start()

        Thread.sleep(forTimeInterval: 2.0)
        engine.stop()

        lock.lock()
        let activeCount = sent.values.filter { $0 > 0 }.count
        lock.unlock()

        XCTAssertEqual(activeCount, 1, "并发上限为 1 时应只有一个目标在发包")
    }

    /// 目标数超过上限时，轮换保证每个目标都能轮到探测
    func testRotationLetsEveryTargetProbe() {
        let engine = PingEngine()
        engine.updateSettings(PingEngine.Settings(interval: 0.3, timeout: 1, maxConcurrent: 1, rotationInterval: 1))

        let targets = (1...2).map { PingTarget(host: "127.0.0.1", note: "目标\($0)") }
        let lock = NSLock()
        var sent: [UUID: Int] = [:]
        engine.onStats = { id, stats in
            lock.lock()
            sent[id] = max(sent[id] ?? 0, stats.sent)
            lock.unlock()
        }
        engine.setTargets(targets)
        engine.start()

        let covered = waitUntil({
            lock.lock()
            defer { lock.unlock() }
            return sent.values.filter { $0 > 0 }.count == targets.count
        }, timeout: 8.0)
        engine.stop()

        XCTAssertTrue(covered, "轮换后所有目标都应该被探测到")
    }

    /// 停用某个目标应当立即终止该行的探测
    func testDisablingTargetStopsProbing() {
        let engine = PingEngine()
        engine.updateSettings(PingEngine.Settings(interval: 0.3, timeout: 1, maxConcurrent: 2, rotationInterval: 0))

        let target = PingTarget(host: "127.0.0.1")
        let lock = NSLock()
        var latest: [UUID: PingStats] = [:]
        engine.onStats = { id, stats in
            lock.lock()
            latest[id] = stats
            lock.unlock()
        }
        engine.setTargets([target])
        engine.start()

        let started = waitUntil({
            lock.lock()
            defer { lock.unlock() }
            return (latest[target.id]?.sent ?? 0) > 1
        }, timeout: 5.0)
        XCTAssertTrue(started, "应当先收到环回地址的回包")

        var disabled = target
        disabled.enabled = false
        engine.setTargets([disabled])

        let stopped = waitUntil({
            lock.lock()
            defer { lock.unlock() }
            return latest[target.id]?.status == .disabled
        }, timeout: 3.0)
        XCTAssertTrue(stopped, "停用后状态应变为已停用")

        lock.lock()
        let sentWhenDisabled = latest[target.id]?.sent ?? 0
        lock.unlock()

        Thread.sleep(forTimeInterval: 1.5)

        lock.lock()
        let sentAfter = latest[target.id]?.sent ?? 0
        lock.unlock()

        engine.stop()
        XCTAssertEqual(sentAfter, sentWhenDisabled, "停用后不应再有新的探测")
    }

    /// 重新启用后应当恢复探测
    func testReEnablingTargetResumesProbing() {
        let engine = PingEngine()
        engine.updateSettings(PingEngine.Settings(interval: 0.3, timeout: 1, maxConcurrent: 2, rotationInterval: 0))

        var target = PingTarget(host: "127.0.0.1")
        target.enabled = false
        let lock = NSLock()
        var latest: [UUID: PingStats] = [:]
        engine.onStats = { id, stats in
            lock.lock()
            latest[id] = stats
            lock.unlock()
        }
        engine.setTargets([target])
        engine.start()

        Thread.sleep(forTimeInterval: 0.5)
        lock.lock()
        XCTAssertEqual(latest[target.id]?.status, .disabled)
        lock.unlock()

        target.enabled = true
        engine.setTargets([target])

        let resumed = waitUntil({
            lock.lock()
            defer { lock.unlock() }
            return (latest[target.id]?.sent ?? 0) > 0
        }, timeout: 5.0)
        engine.stop()

        XCTAssertTrue(resumed, "重新启用后应恢复探测")
    }
    func testStopKeepsLastResult() {
        let engine = PingEngine()
        engine.updateSettings(PingEngine.Settings(interval: 0.3, timeout: 1, maxConcurrent: 2, rotationInterval: 0))

        let target = PingTarget(host: "127.0.0.1")
        let lock = NSLock()
        var latest: [UUID: PingStats] = [:]
        engine.onStats = { id, stats in
            lock.lock()
            latest[id] = stats
            lock.unlock()
        }
        engine.setTargets([target])
        engine.start()

        let running = waitUntil({
            lock.lock()
            defer { lock.unlock() }
            return latest[target.id]?.status == .alive
        }, timeout: 5.0)
        XCTAssertTrue(running, "应当收到环回地址的回包")

        engine.stop()
        Thread.sleep(forTimeInterval: 0.5)

        lock.lock()
        let finalStatus = latest[target.id]?.status
        lock.unlock()
        XCTAssertEqual(finalStatus, .alive, "停止后保留最后一次测量结果")
    }
}

/// 轮换应当一次返回所有到期目标
extension EngineSchedulingTests {
    func testExpiredTargetsReturnsAllExpired() {
        let now = Date()
        let ids = (0..<5).map { _ in UUID() }
        let startedAt: [UUID: Date] = [
            ids[0]: now.addingTimeInterval(-10),
            ids[1]: now.addingTimeInterval(-6),
            ids[2]: now.addingTimeInterval(-1),
            ids[3]: now.addingTimeInterval(-30),
            ids[4]: now.addingTimeInterval(-2),
        ]

        let expired = PingEngine.expiredTargets(startedAt: startedAt, now: now, interval: 5)

        XCTAssertEqual(Set(expired), Set([ids[0], ids[1], ids[3]]))
    }
}
