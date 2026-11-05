import XCTest
@testable import PingCore

final class EngineSmokeTests: XCTestCase {
    func testRealPingAgainstLoopbackDeadHostAndInvalidHost() throws {
        let engine = PingEngine()
        engine.updateSettings(PingEngine.Settings(interval: 0.5, timeout: 2, maxConcurrent: 4, rotationInterval: 30))

        let loopback = PingTarget(host: "127.0.0.1")
        let dead = PingTarget(host: "192.0.2.1")
        let invalid = PingTarget(host: "nope.invalid")

        let lock = NSLock()
        var latest: [UUID: PingStats] = [:]
        engine.onStats = { id, stats in
            lock.lock()
            latest[id] = stats
            lock.unlock()
        }
        engine.setTargets([loopback, dead, invalid])
        engine.start()

        Thread.sleep(forTimeInterval: 4.0)
        engine.stop()
        Thread.sleep(forTimeInterval: 1.0)

        lock.lock()
        let snapshot = latest
        lock.unlock()

        let loop = try XCTUnwrap(snapshot[loopback.id])
        print("loopback:", loop.status, "sent=\(loop.sent) recv=\(loop.received) last=\(String(describing: loop.lastLatency))")
        XCTAssertEqual(loop.status, .alive)
        XCTAssertGreaterThan(loop.received, 0)
        XCTAssertNotNil(loop.lastLatency)

        let deadStats = try XCTUnwrap(snapshot[dead.id])
        print("dead:", deadStats.status, "sent=\(deadStats.sent) recv=\(deadStats.received) loss=\(deadStats.lossRate)")
        XCTAssertGreaterThan(deadStats.sent, 0)
        XCTAssertEqual(deadStats.received, 0)
        XCTAssertEqual(deadStats.lossRate, 1.0, accuracy: 0.0001)

        let invalidStats = try XCTUnwrap(snapshot[invalid.id])
        print("invalid:", invalidStats.status, "message=\(invalidStats.message)")
        XCTAssertEqual(invalidStats.status, .error)
        XCTAssertFalse(invalidStats.message.isEmpty)
    }
}
