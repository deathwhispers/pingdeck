import XCTest
@testable import PingCore

final class PingParserTests: XCTestCase {
    func testParsesReplyLine() {
        let event = PingLineParser.parse("64 bytes from 8.8.8.8: icmp_seq=0 ttl=118 time=13.163 ms")
        XCTAssertEqual(event, .reply(seq: 0, latencyMs: 13.163))
    }

    func testParsesIPv6ReplyLine() {
        let event = PingLineParser.parse("64 bytes from 2001:4860:4860::8888: icmp_seq=2 hlim=52 time=8.001 ms")
        XCTAssertEqual(event, .reply(seq: 2, latencyMs: 8.001))
    }

    func testParsesTimeoutLine() {
        let event = PingLineParser.parse("Request timeout for icmp_seq 3")
        XCTAssertEqual(event, .timeout(seq: 3))
    }

    func testParsesUnresolvableHost() {
        let event = PingLineParser.parse("ping: cannot resolve host: nope.invalid: Unknown host")
        guard case .failure(let message) = event else {
            return XCTFail("期望 failure，实际为 \(event)")
        }
        XCTAssertTrue(message.contains("cannot resolve"))
    }

    func testParsesUnreachable() {
        let event = PingLineParser.parse("ping: sendto: No route to host")
        guard case .unreachable = event else {
            return XCTFail("期望 unreachable，实际为 \(event)")
        }
    }

    func testIgnoresStatisticsFooter() {
        let event = PingLineParser.parse("--- 8.8.8.8 ping statistics ---")
        XCTAssertEqual(event, .info("--- 8.8.8.8 ping statistics ---"))
    }
}

final class StatsTests: XCTestCase {
    func testAverageAndLossRate() {
        var stats = PingStats()
        stats.recordSuccess(10, at: Date(), seq: 0)
        stats.recordSuccess(20, at: Date(), seq: 1)
        stats.recordTimeout(seq: 2)

        XCTAssertEqual(stats.sent, 3)
        XCTAssertEqual(stats.received, 2)
        XCTAssertEqual(stats.averageLatency ?? 0, 15, accuracy: 0.0001)
        XCTAssertEqual(stats.minLatency ?? 0, 10, accuracy: 0.0001)
        XCTAssertEqual(stats.maxLatency ?? 0, 20, accuracy: 0.0001)
        XCTAssertEqual(stats.lossRate, 1.0 / 3.0, accuracy: 0.0001)
        XCTAssertEqual(stats.status, .timeout)
    }

    /// 序号跳号说明中间的包丢失，即使 ping 没有输出超时行也要计入丢包
    func testSequenceGapCountsAsLoss() {
        var stats = PingStats()
        stats.recordSuccess(10, at: Date(), seq: 0)
        stats.recordSuccess(12, at: Date(), seq: 3)

        XCTAssertEqual(stats.sent, 4)
        XCTAssertEqual(stats.received, 2)
        XCTAssertEqual(stats.lossRate, 0.5, accuracy: 0.0001)
    }

    /// 进程重启后 icmp_seq 重新计数，需要用基准值衔接
    func testSessionBaseContinuesCounting() {
        var stats = PingStats()
        stats.recordSuccess(10, at: Date(), seq: 0)
        stats.recordSuccess(10, at: Date(), seq: 1)

        stats.beginSession(sentBefore: stats.sent)
        stats.recordSuccess(11, at: Date(), seq: 0)

        XCTAssertEqual(stats.sent, 3)
        XCTAssertEqual(stats.received, 3)
        XCTAssertEqual(stats.lossRate, 0, accuracy: 0.0001)
    }
}

final class CsvExporterTests: XCTestCase {
    func testCSVContainsHeaderAndRow() {
        var stats = PingStats()
        stats.recordSuccess(12.5, at: Date(), seq: 0)

        let target = PingTarget(host: "8.8.8.8", note: "网关")
        let csv = CsvExporter.csv(for: [CsvExporter.Entry(target: target, stats: stats)])

        XCTAssertTrue(csv.hasPrefix("\u{FEFF}"))
        XCTAssertTrue(csv.contains("目标,备注,状态"))
        XCTAssertTrue(csv.contains("8.8.8.8"))
        XCTAssertTrue(csv.contains("12.500"))
    }

    func testCSVEscapesCommas() {
        let target = PingTarget(host: "a,b", note: "带,逗号")
        let csv = CsvExporter.csv(for: [CsvExporter.Entry(target: target, stats: PingStats())])
        XCTAssertTrue(csv.contains("\"a,b\""))
    }
}
