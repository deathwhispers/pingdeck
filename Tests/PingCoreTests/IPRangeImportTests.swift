import XCTest
@testable import PingCore

/// 批量导入中的网段展开
final class IPRangeImportTests: XCTestCase {
    private func hosts(_ result: BulkImportParser.Result) -> [String] {
        result.entries.map(\.host)
    }

    // MARK: - CIDR

    /// CIDR 展开包含网络地址与广播地址
    func testCIDRExpandsAllAddresses() {
        let result = BulkImportParser.parse("10.0.0.0/30")

        XCTAssertEqual(hosts(result), ["10.0.0.0", "10.0.0.1", "10.0.0.2", "10.0.0.3"])
        XCTAssertTrue(result.rejected.isEmpty)
    }

    /// /32 只展开一个地址
    func testCIDRSlash32ExpandsOneAddress() {
        let result = BulkImportParser.parse("192.168.1.10/32")

        XCTAssertEqual(hosts(result), ["192.168.1.10"])
    }

    /// 非规范 CIDR（主机位不为 0）必须拒绝，并提示填写网络地址
    func testNonCanonicalCIDRIsRejected() {
        let result = BulkImportParser.parse("10.0.0.5/24")

        XCTAssertTrue(result.entries.isEmpty)
        XCTAssertEqual(result.rejected.count, 1)
        XCTAssertTrue(result.rejected[0].reason.contains("网络地址"))
    }

    func testInvalidPrefixIsRejected() {
        let result = BulkImportParser.parse("10.0.0.0/33")

        XCTAssertTrue(result.entries.isEmpty)
        XCTAssertTrue(result.rejected[0].reason.contains("网段"))
    }

    /// /21 会展开 2048 个地址，超过单段上限
    func testCIDRTooLargeIsRejected() {
        let result = BulkImportParser.parse("10.0.0.0/21")

        XCTAssertTrue(result.entries.isEmpty)
        XCTAssertTrue(result.rejected[0].reason.contains("1024"))
    }

    /// /22 正好 1024 个地址，应当接受
    func testCIDRAtLimitIsAccepted() {
        let result = BulkImportParser.parse("10.0.0.0/22")

        XCTAssertEqual(result.entries.count, 1024)
        XCTAssertTrue(result.rejected.isEmpty)
    }

    // MARK: - 范围

    func testFullRangeExpands() {
        let result = BulkImportParser.parse("10.0.0.1-10.0.0.10")

        XCTAssertEqual(result.entries.count, 10)
        XCTAssertEqual(result.entries.first?.host, "10.0.0.1")
        XCTAssertEqual(result.entries.last?.host, "10.0.0.10")
    }

    func testShorthandRangeExpands() {
        let result = BulkImportParser.parse("10.0.0.1-10")

        XCTAssertEqual(result.entries.count, 10)
        XCTAssertEqual(result.entries.first?.host, "10.0.0.1")
        XCTAssertEqual(result.entries.last?.host, "10.0.0.10")
    }

    func testRangeWithStartAfterEndIsRejected() {
        let result = BulkImportParser.parse("10.0.0.10-10.0.0.1")

        XCTAssertTrue(result.entries.isEmpty)
        XCTAssertTrue(result.rejected[0].reason.contains("结束地址"))
    }

    func testRangeTooLargeIsRejected() {
        let result = BulkImportParser.parse("10.0.0.0-10.0.4.0")

        XCTAssertTrue(result.entries.isEmpty)
        XCTAssertTrue(result.rejected[0].reason.contains("1024"))
    }

    /// 主机名里的连字符不能被误判为范围
    func testHostnameWithHyphenIsNotARange() {
        let result = BulkImportParser.parse("my-server-01")

        XCTAssertEqual(hosts(result), ["my-server-01"])
        XCTAssertTrue(result.rejected.isEmpty)
    }

    /// 看起来像范围但格式不完整时，给出明确错误
    func testMalformedRangeIsRejected() {
        let result = BulkImportParser.parse("10.0.0.1-")

        XCTAssertTrue(result.entries.isEmpty)
        XCTAssertTrue(result.rejected[0].reason.contains("网段"))
    }

    // MARK: - 备注与去重

    func testExpandedTargetsInheritNote() {
        let result = BulkImportParser.parse("10.0.0.1-3 机房 A")

        XCTAssertEqual(result.entries.count, 3)
        XCTAssertTrue(result.entries.allSatisfy { $0.note == "机房 A" })
    }

    /// 与已有目标重复的地址会被跳过，其余地址正常导入
    func testRangeSkipsExistingTargets() {
        let result = BulkImportParser.parse("10.0.0.1-3", existing: ["10.0.0.1"])

        XCTAssertEqual(hosts(result), ["10.0.0.2", "10.0.0.3"])
    }

    /// 整段都与已有目标重复时，按重复拒绝该行
    func testFullyDuplicateRangeIsRejected() {
        let result = BulkImportParser.parse("10.0.0.1-2", existing: ["10.0.0.1", "10.0.0.2"])

        XCTAssertTrue(result.entries.isEmpty)
        XCTAssertEqual(result.rejected.count, 1)
        XCTAssertTrue(result.rejected[0].reason.contains("重复"))
    }

    /// 同一批输入里的重叠网段只保留一次
    func testOverlappingRangesAreDeduplicated() {
        let result = BulkImportParser.parse("10.0.0.1-3\n10.0.0.2-4")

        XCTAssertEqual(hosts(result), ["10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4"])
    }
}
