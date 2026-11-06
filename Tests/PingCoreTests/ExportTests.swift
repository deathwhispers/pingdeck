import XCTest
@testable import PingCore

/// 导出用的统一表格模型：所有格式共享同一批列定义与列值
final class ExportTableTests: XCTestCase {
    private func makeStats() -> PingStats {
        var stats = PingStats()
        stats.recordSuccess(12.5, at: Date(timeIntervalSince1970: 1_700_000_000), seq: 0)
        return stats
    }

    /// 列标题必须与既有 CSV 表头完全一致，避免各格式之间出现列偏差
    func testColumnsMatchCSVHeader() {
        let table = ExportTable(entries: [])

        XCTAssertEqual(table.columns.map(\.title), CsvExporter.header)
    }

    /// 列值带类型：延迟是数字、状态是文本、最后响应时间是日期
    func testRowCarriesTypedValues() {
        let entry = ExportEntry(target: PingTarget(host: "8.8.8.8", note: "网关"), stats: makeStats())

        let row = ExportTable(entries: [entry]).rows[0]

        XCTAssertEqual(row[0], .text("8.8.8.8"))
        XCTAssertEqual(row[1], .text("网关"))
        XCTAssertEqual(row[2], .status(.alive))
        XCTAssertEqual(row[3], .number(12.5))
        XCTAssertEqual(row[4], .number(12.5))
        XCTAssertEqual(row[5], .number(12.5))
        XCTAssertEqual(row[6], .number(12.5))
        XCTAssertEqual(row[7], .number(0))
        XCTAssertEqual(row[8], .date(Date(timeIntervalSince1970: 1_700_000_000)))
    }

    /// 缺失的延迟与响应时间表示为空数值，不是 0
    func testMissingValuesAreEmptyNotZero() {
        let entry = ExportEntry(target: PingTarget(host: "8.8.8.8"), stats: PingStats())

        let row = ExportTable(entries: [entry]).rows[0]

        XCTAssertEqual(row[3], .number(nil))
        XCTAssertEqual(row[8], .date(nil))
        XCTAssertEqual(row[7], .number(0))
    }

    /// 丢包率以百分比数值保存（5% 存 5 而不是 0.05），与表头「丢包率(%)」一致
    func testLossRateIsStoredAsPercentValue() {
        var stats = PingStats()
        stats.recordSuccess(1, at: Date(), seq: 0)
        stats.recordTimeout(seq: 1)
        let entry = ExportEntry(target: PingTarget(host: "8.8.8.8"), stats: stats)

        let row = ExportTable(entries: [entry]).rows[0]

        XCTAssertEqual(row[7], .number(50))
    }
}

/// CSV 是既有格式，改造后输出必须逐字节不变
final class CsvExporterCompatibilityTests: XCTestCase {
    private func expectedDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    func testCSVOutputIsUnchanged() {
        var stats = PingStats()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        stats.recordSuccess(12.5, at: date, seq: 0)
        let entry = ExportEntry(target: PingTarget(host: "8.8.8.8", note: "网关"), stats: stats)

        let csv = CsvExporter.csv(for: [entry])

        let expected = "\u{FEFF}目标,备注,状态,最新延迟(ms),平均延迟(ms),最小延迟(ms),最大延迟(ms),丢包率(%),最后响应时间\r\n"
            + "8.8.8.8,网关,正常,12.500,12.500,12.500,12.500,0.00,\(expectedDateString(date))\r\n"
        XCTAssertEqual(csv, expected)
    }

    func testCSVEscapingIsUnchanged() {
        let entry = ExportEntry(target: PingTarget(host: "a,b", note: "带\"引号"), stats: PingStats())

        let csv = CsvExporter.csv(for: [entry])

        XCTAssertTrue(csv.contains("\"a,b\""))
        XCTAssertTrue(csv.contains("\"带\"\"引号\""))
    }
}

/// JSON 导出：面向脚本消费，字段名与状态值用英文
final class JsonExporterTests: XCTestCase {
    private func makeEntries() -> [ExportEntry] {
        var stats = PingStats()
        stats.recordSuccess(12.5, at: Date(timeIntervalSince1970: 1_700_000_000), seq: 0)
        return [ExportEntry(target: PingTarget(host: "8.8.8.8", note: "网关"), stats: stats)]
    }

    func testJSONContainsSummaryAndTargets() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        let json = JsonExporter.json(for: makeEntries(), exportedAt: date)

        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let summary = try XCTUnwrap(root["summary"] as? [String: Any])
        XCTAssertEqual(summary["targets"] as? Int, 1)
        XCTAssertEqual(summary["alive"] as? Int, 1)
        XCTAssertEqual(summary["problems"] as? Int, 0)
        XCTAssertEqual(summary["totalSent"] as? Int, 1)

        let targets = try XCTUnwrap(root["targets"] as? [[String: Any]])
        let target = try XCTUnwrap(targets.first)
        XCTAssertEqual(target["host"] as? String, "8.8.8.8")
        XCTAssertEqual(target["note"] as? String, "网关")
        XCTAssertEqual(target["status"] as? String, "alive")
        XCTAssertEqual(target["lastLatencyMs"] as? Double, 12.5)
        XCTAssertEqual(target["lossRatePercent"] as? Double, 0)
        XCTAssertNotNil(target["lastResponseAt"] as? String)
    }

    /// 缺失的数值写成 null，不能省略字段
    func testJSONWritesNullForMissingValues() throws {
        let entry = ExportEntry(target: PingTarget(host: "8.8.8.8"), stats: PingStats())

        let json = JsonExporter.json(for: [entry], exportedAt: Date(timeIntervalSince1970: 0))

        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let targets = try XCTUnwrap(root["targets"] as? [[String: Any]])
        let target = try XCTUnwrap(targets.first)
        XCTAssertTrue(target["lastLatencyMs"] is NSNull)
        XCTAssertTrue(target["lastResponseAt"] is NSNull)
    }
}

/// Markdown 导出：标题 + 汇总 + 表格
final class MarkdownExporterTests: XCTestCase {
    func testMarkdownContainsTableHeaderSeparatorAndRows() {
        var stats = PingStats()
        stats.recordSuccess(12.5, at: Date(timeIntervalSince1970: 1_700_000_000), seq: 0)
        let entry = ExportEntry(target: PingTarget(host: "8.8.8.8", note: "网关"), stats: stats)

        let markdown = MarkdownExporter.markdown(for: [entry], exportedAt: Date(timeIntervalSince1970: 1_700_000_000))

        XCTAssertTrue(markdown.contains("| 目标 | 备注 | 状态 | 最新延迟(ms) |"))
        XCTAssertTrue(markdown.contains("| --- | --- | --- | --- |"))
        XCTAssertTrue(markdown.contains("| 8.8.8.8 | 网关 | 正常 | 12.500 |"))
        XCTAssertTrue(markdown.contains("目标 1"))
        XCTAssertTrue(markdown.contains("正常 1"))
    }
}

/// TXT 导出：对齐的纯文本表格
final class TextExporterTests: XCTestCase {
    func testTextContainsHeaderAndRow() {
        var stats = PingStats()
        stats.recordSuccess(12.5, at: Date(timeIntervalSince1970: 1_700_000_000), seq: 0)
        let entry = ExportEntry(target: PingTarget(host: "8.8.8.8", note: "网关"), stats: stats)

        let text = TextExporter.text(for: [entry])

        XCTAssertTrue(text.contains("目标"))
        XCTAssertTrue(text.contains("8.8.8.8"))
        XCTAssertTrue(text.contains("网关"))
        XCTAssertTrue(text.contains("正常"))
        XCTAssertTrue(text.contains("12.500"))
    }

    /// 列宽按显示宽度对齐，中文按两个字符计算
    func testColumnsAreAlignedByDisplayWidth() {
        let entry = ExportEntry(target: PingTarget(host: "1.1.1.1"), stats: PingStats())

        let text = TextExporter.text(for: [entry])

        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let header = try? XCTUnwrap(lines.first)
        let row = try? XCTUnwrap(lines.dropFirst().first)
        // 「目标」显示宽度 4，「1.1.1.1」宽度 7，列宽取 7：表头补 3 个空格，数据列占满 7
        XCTAssertEqual(header?.hasPrefix("目标   "), true)
        XCTAssertEqual(row?.hasPrefix("1.1.1.1"), true)
    }
}

/// XLSX 导出：自实现的最小 OOXML 包
final class XlsxExporterTests: XCTestCase {
    private func makeEntry() -> ExportEntry {
        var stats = PingStats()
        stats.recordSuccess(12.5, at: Date(timeIntervalSince1970: 1_700_000_000), seq: 0)
        return ExportEntry(target: PingTarget(host: "8.8.8.8", note: "网关"), stats: stats)
    }

    func testXLSXIsZipArchiveWithRequiredParts() throws {
        let data = XlsxExporter.xlsx(for: [makeEntry()])

        XCTAssertEqual(Array(data.prefix(2)), [0x50, 0x4B], "xlsx 必须是 zip 包")

        let parts = try MiniZip.contents(of: data)
        XCTAssertNotNil(parts["[Content_Types].xml"])
        XCTAssertNotNil(parts["_rels/.rels"])
        XCTAssertNotNil(parts["xl/workbook.xml"])
        XCTAssertNotNil(parts["xl/_rels/workbook.xml.rels"])
        XCTAssertNotNil(parts["xl/styles.xml"])
        XCTAssertNotNil(parts["xl/worksheets/sheet1.xml"])
    }

    /// 表头一行、数据一行，延迟写成数值单元格而不是字符串
    func testSheetContainsHeaderRowAndNumericCells() throws {
        let data = XlsxExporter.xlsx(for: [makeEntry()])

        let parts = try MiniZip.contents(of: data)
        let sheet = try XCTUnwrap(parts["xl/worksheets/sheet1.xml"])
        XCTAssertTrue(sheet.contains("<c r=\"A1\" s=\"1\" t=\"inlineStr\"><is><t>目标</t></is></c>"))
        XCTAssertTrue(sheet.contains("<c r=\"A2\" t=\"inlineStr\"><is><t>8.8.8.8</t></is></c>"))
        XCTAssertTrue(sheet.contains("<c r=\"D2\"><v>12.5</v></c>"))
        XCTAssertTrue(sheet.contains("<c r=\"C2\" t=\"inlineStr\"><is><t>正常</t></is></c>"))
    }

    /// 单元格内容里的 XML 特殊字符必须转义
    func testCellContentIsXMLEscaped() throws {
        let entry = ExportEntry(target: PingTarget(host: "a&b<c>", note: "\"引号\""), stats: PingStats())

        let data = XlsxExporter.xlsx(for: [entry])

        let parts = try MiniZip.contents(of: data)
        let sheet = try XCTUnwrap(parts["xl/worksheets/sheet1.xml"])
        XCTAssertTrue(sheet.contains("<t>a&amp;b&lt;c&gt;</t>"))
    }

    /// 空目标也要生成只有表头的工作表
    func testEmptyEntriesStillProduceHeader() throws {
        let data = XlsxExporter.xlsx(for: [])

        let parts = try MiniZip.contents(of: data)
        let sheet = try XCTUnwrap(parts["xl/worksheets/sheet1.xml"])
        XCTAssertTrue(sheet.contains("<t>丢包率(%)</t>"))
        XCTAssertFalse(sheet.contains("<row r=\"2\""))
    }
}

/// 测试用的最小 zip 读取器：只支持 stored（不压缩）模式
private struct MiniZip {
    static func contents(of data: Data) throws -> [String: String] {
        var parts: [String: String] = [:]
        var offset = 0
        while offset + 30 <= data.count {
            let signature = try readUInt32(data, at: offset)
            guard signature == 0x04034b50 else { break }
            let compressedSize = Int(try readUInt32(data, at: offset + 18))
            let nameLength = Int(try readUInt16(data, at: offset + 26))
            let extraLength = Int(try readUInt16(data, at: offset + 28))
            let nameStart = offset + 30
            let name = String(decoding: data.subdata(in: nameStart..<(nameStart + nameLength)), as: UTF8.self)
            let contentStart = nameStart + nameLength + extraLength
            let content = data.subdata(in: contentStart..<(contentStart + compressedSize))
            parts[name] = String(decoding: content, as: UTF8.self)
            offset = contentStart + compressedSize
        }
        return parts
    }

    private static func readUInt16(_ data: Data, at offset: Int) throws -> UInt16 {
        let bytes = data.subdata(in: offset..<(offset + 2))
        guard bytes.count == 2 else { throw CocoaError(.fileReadCorruptFile) }
        return UInt16(bytes[bytes.startIndex]) | (UInt16(bytes[bytes.startIndex + 1]) << 8)
    }

    private static func readUInt32(_ data: Data, at offset: Int) throws -> UInt32 {
        let bytes = data.subdata(in: offset..<(offset + 4))
        guard bytes.count == 4 else { throw CocoaError(.fileReadCorruptFile) }
        var value: UInt32 = 0
        for index in 0..<4 {
            value |= UInt32(bytes[bytes.startIndex + index]) << (8 * UInt32(index))
        }
        return value
    }
}

/// 导出格式枚举
final class ExportFormatTests: XCTestCase {
    func testAllFormatsAreAvailable() {
        XCTAssertEqual(ExportFormat.allCases.count, 5)
    }

    func testFileExtensions() {
        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(ExportFormat.json.fileExtension, "json")
        XCTAssertEqual(ExportFormat.txt.fileExtension, "txt")
        XCTAssertEqual(ExportFormat.markdown.fileExtension, "md")
        XCTAssertEqual(ExportFormat.xlsx.fileExtension, "xlsx")
    }
}

/// 统一出口：按格式产出数据与默认文件名
final class ExportFileTests: XCTestCase {
    private func makeEntries() -> [ExportEntry] {
        var stats = PingStats()
        stats.recordSuccess(12.5, at: Date(timeIntervalSince1970: 1_700_000_000), seq: 0)
        return [ExportEntry(target: PingTarget(host: "8.8.8.8", note: "网关"), stats: stats)]
    }

    func testFilenameUsesFormatExtensionAndTimestamp() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let name = ExportFile.filename(format: .markdown, date: date)

        // 文件名用本地时间，期望值也按本地时区计算，避免在 UTC 的 CI 上失败
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let timestamp = formatter.string(from: date)

        XCTAssertTrue(name.hasPrefix("pingdeck-"))
        XCTAssertTrue(name.hasSuffix(".md"))
        XCTAssertTrue(name.contains(timestamp))
    }

    /// 每个格式都要能产出非空数据
    func testDataIsProducedForEveryFormat() {
        let entries = makeEntries()
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        for format in ExportFormat.allCases {
            let data = ExportFile.data(format: format, entries: entries, date: date)
            XCTAssertFalse(data.isEmpty, "\(format.displayName) 导出结果不应为空")
        }
    }

    /// xlsx 是二进制包，文本格式是 UTF-8 文本
    func testDataFormatPerExportFormat() {
        let entries = makeEntries()
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertEqual(Array(ExportFile.data(format: .xlsx, entries: entries, date: date).prefix(2)), [0x50, 0x4B])
        XCTAssertTrue(String(decoding: ExportFile.data(format: .json, entries: entries, date: date), as: UTF8.self).contains("\"targets\""))
        XCTAssertTrue(String(decoding: ExportFile.data(format: .markdown, entries: entries, date: date), as: UTF8.self).hasPrefix("# PingDeck"))
        XCTAssertTrue(String(decoding: ExportFile.data(format: .txt, entries: entries, date: date), as: UTF8.self).contains("8.8.8.8"))
        XCTAssertTrue(String(decoding: ExportFile.data(format: .csv, entries: entries, date: date), as: UTF8.self).hasPrefix("\u{FEFF}"))
    }
}
