import XCTest
import PingCore
@testable import PingDeck

final class TargetRowComparatorTests: XCTestCase {
    private func row(
        host: String,
        latency: Double? = nil,
        status: TargetStatus = .idle,
        enabled: Bool = true
    ) -> TargetRow {
        var stats = PingStats()
        stats.status = status
        if let latency {
            stats.recordSuccess(latency, at: Date(), seq: 0)
        }
        return TargetRow(
            id: UUID(),
            target: PingTarget(host: host, enabled: enabled),
            stats: stats
        )
    }

    /// 空值在升序和降序下都必须排在最后
    func testNilLatencyAlwaysSortsLast() {
        let low = row(host: "a", latency: 10)
        let high = row(host: "b", latency: 20)
        let missing = row(host: "c")

        let forward = TargetRowComparator(field: .last, order: .forward)
        XCTAssertEqual(forward.compare(missing, low), .orderedDescending)
        XCTAssertEqual(forward.compare(low, missing), .orderedAscending)
        XCTAssertEqual(forward.compare(low, high), .orderedAscending)

        let reverse = TargetRowComparator(field: .last, order: .reverse)
        XCTAssertEqual(reverse.compare(missing, low), .orderedDescending)
        XCTAssertEqual(reverse.compare(low, missing), .orderedAscending)
        XCTAssertEqual(reverse.compare(low, high), .orderedDescending)
    }

    func testStatusSortUsesSeverityRank() {
        let alive = row(host: "a", status: .alive)
        let error = row(host: "b", status: .error)
        let comparator = TargetRowComparator(field: .status, order: .forward)

        XCTAssertEqual(comparator.compare(alive, error), .orderedAscending)
    }

    func testTargetSortUsesLocalizedStandardComparison() {
        let two = row(host: "10.0.0.2")
        let ten = row(host: "10.0.0.10")
        let comparator = TargetRowComparator(field: .target, order: .forward)

        XCTAssertEqual(comparator.compare(two, ten), .orderedAscending)
    }

    func testColumnMetadata() {
        XCTAssertEqual(Set(TargetColumn.allCases.map(\.rawValue)).count, TargetColumn.allCases.count)
        XCTAssertTrue(TargetColumn.target.isRequired)
        XCTAssertFalse(TargetColumn.status.isRequired)
    }
}
