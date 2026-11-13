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
        XCTAssertTrue(result.rejected.contains { $0.reason == .duplicate })
        XCTAssertTrue(result.rejected.contains { $0.reason == .invalidTarget(.protocolPrefix) })
        XCTAssertTrue(result.rejected.contains { $0.reason == .invalidRange(.cidrNotNetworkAddress) })
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

    func testParsesWithDefaultGroupAndColorTag() {
        let result = BulkImportParser.parse(
            """
            8.8.8.8 Google DNS
            1.1.1.1
            """,
            defaultGroup: "DNS Servers",
            defaultColorTag: .blue
        )

        XCTAssertEqual(result.entries.count, 2)
        XCTAssertEqual(result.entries[0], BulkImportParser.Entry(host: "8.8.8.8", note: "Google DNS", group: "DNS Servers", colorTag: .blue))
        XCTAssertEqual(result.entries[1], BulkImportParser.Entry(host: "1.1.1.1", note: "", group: "DNS Servers", colorTag: .blue))
        XCTAssertTrue(result.rejected.isEmpty)
    }

    func testParsesCsvFormatWithGroupAndColorTag() {
        let result = BulkImportParser.parse(
            """
            1.1.1.1,Cloudflare DNS,Prod,red
            8.8.8.8,Google DNS,Public,orange
            9.9.9.9,Quad9,,
            208.67.222.222,OpenDNS
            """,
            defaultGroup: "DefaultGroup",
            defaultColorTag: .gray
        )

        XCTAssertEqual(result.entries.count, 4)
        XCTAssertEqual(result.entries[0], BulkImportParser.Entry(host: "1.1.1.1", note: "Cloudflare DNS", group: "Prod", colorTag: .red))
        XCTAssertEqual(result.entries[1], BulkImportParser.Entry(host: "8.8.8.8", note: "Google DNS", group: "Public", colorTag: .orange))
        XCTAssertEqual(result.entries[2], BulkImportParser.Entry(host: "9.9.9.9", note: "Quad9", group: "DefaultGroup", colorTag: .gray))
        XCTAssertEqual(result.entries[3], BulkImportParser.Entry(host: "208.67.222.222", note: "OpenDNS", group: "DefaultGroup", colorTag: .gray))
        XCTAssertTrue(result.rejected.isEmpty)
    }

    func testParseSingleTargetWithGroupAndColorTag() {
        let result = BulkImportParser.parse(
            host: "1.1.1.1",
            note: "Cloudflare",
            group: "Anycast",
            colorTag: .green
        )

        XCTAssertEqual(result.entries.count, 1)
        XCTAssertEqual(result.entries[0], BulkImportParser.Entry(host: "1.1.1.1", note: "Cloudflare", group: "Anycast", colorTag: .green))
        XCTAssertTrue(result.rejected.isEmpty)
    }
}
