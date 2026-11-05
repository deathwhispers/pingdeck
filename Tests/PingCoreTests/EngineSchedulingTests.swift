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

    /// 停止后保留最后一次测量结果，但不再停留在「探测中」
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
