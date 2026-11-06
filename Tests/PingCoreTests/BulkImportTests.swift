import XCTest
@testable import PingCore

final class BulkImportTests: XCTestCase {
    func testParsesHostAndNote() {
        let result = BulkImportParser.parse("""
        8.8.8.8  Google DNS
        1.1.1.1
        # 这一行是注释
        192.168.1.1 网关 备注里有空格
        """)

        XCTAssertEqual(result.entries.count, 3)
        XCTAssertEqual(result.entries[0], BulkImportParser.Entry(host: "8.8.8.8", note: "Google DNS"))
        XCTAssertEqual(result.entries[1], BulkImportParser.Entry(host: "1.1.1.1", note: ""))
        XCTAssertEqual(result.entries[2], BulkImportParser.Entry(host: "192.168.1.1", note: "网关 备注里有空格"))
        XCTAssertTrue(result.rejected.isEmpty)
    }

    func testSkipsInvalidAndDuplicatedLines() {
        let result = BulkImportParser.parse(
            """
            8.8.8.8
            8.8.8.8
            9.9.9.9
            http://example.com
            1.2.3.4/24
            """,
            existing: ["9.9.9.9"]
        )

        XCTAssertEqual(result.entries.count, 1)
        XCTAssertEqual(result.entries[0].host, "8.8.8.8")
        XCTAssertEqual(result.rejected.count, 4)
        XCTAssertTrue(result.rejected.contains { $0.reason.contains("重复") })
        XCTAssertTrue(result.rejected.contains { $0.reason.contains("协议") })
        XCTAssertTrue(result.rejected.contains { $0.reason.contains("网络地址") })
    }

    func testLineNumbersAreReported() {
        let result = BulkImportParser.parse("""
        8.8.8.8

        http://bad
        """)
        XCTAssertEqual(result.rejected.count, 1)
        XCTAssertEqual(result.rejected[0].line, 3)
    }

    func testEmptyInput() {
        let result = BulkImportParser.parse("   \n\n# 只有注释\n")
        XCTAssertTrue(result.entries.isEmpty)
        XCTAssertTrue(result.rejected.isEmpty)
    }

    /// Windows 风格的 CRLF 换行不能污染目标名
    func testHandlesCarriageReturnLineEndings() {
        let result = BulkImportParser.parse("8.8.8.8  Google DNS\r\n1.1.1.1\r\n")
        XCTAssertEqual(result.entries.count, 2)
        XCTAssertEqual(result.entries[0].host, "8.8.8.8")
        XCTAssertEqual(result.entries[0].note, "Google DNS")
        XCTAssertEqual(result.entries[1].host, "1.1.1.1")
        XCTAssertTrue(result.rejected.isEmpty)
    }

    /// 制表符也可以作为目标与备注的分隔符
    func testTabSeparatesHostAndNote() {
        let result = BulkImportParser.parse("8.8.8.8\tGoogle DNS")
        XCTAssertEqual(result.entries.first?.host, "8.8.8.8")
        XCTAssertEqual(result.entries.first?.note, "Google DNS")
    }
}
