import XCTest
@testable import PingCore

final class StatusDetailTests: XCTestCase {
    func testStatusDetailRoundTrips() throws {
        var stats = PingStats()
        stats.detail = .launchFailed(
            host: "example.com",
            error: .executableNotFound(path: "/sbin/ping")
        )

        let data = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(PingStats.self, from: data)

        XCTAssertEqual(decoded.detail, stats.detail)
    }

    func testDisabledTargetCarriesTypedDetail() {
        let engine = PingEngine()
        let id = UUID()
        engine.setTargets([PingTarget(id: id, host: "example.com", enabled: false)])

        XCTAssertEqual(engine.snapshot()[id]?.detail, .disabled)
    }
}
