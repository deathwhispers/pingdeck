import Foundation

/// XLSX 导出
///
/// 生成的是一个标准的 OOXML 包（zip + XML），Excel / Numbers 都能直接打开。
/// 延迟与丢包率写成真正的数值单元格，方便在表格里继续排序、筛选、画图。
public enum XlsxExporter {
    public static func xlsx(for entries: [ExportEntry]) -> Data {
        let table = ExportTable(entries: entries)

        var archive = ZipArchive()
        archive.addFile(name: "[Content_Types].xml", data: data(contentTypesXML))
        archive.addFile(name: "_rels/.rels", data: data(rootRelationshipsXML))
        archive.addFile(name: "xl/workbook.xml", data: data(workbookXML))
        archive.addFile(name: "xl/_rels/workbook.xml.rels", data: data(workbookRelationshipsXML))
        archive.addFile(name: "xl/styles.xml", data: data(stylesXML))
        archive.addFile(name: "xl/worksheets/sheet1.xml", data: data(sheetXML(table)))
        return archive.build()
    }

    // MARK: - 表格

    private static func sheetXML(_ table: ExportTable) -> String {
        var rows: [String] = []

        let headerCells = table.columns.enumerated().map { index, column in
            cell(reference: "\(columnName(index))1", style: 1, text: column.title)
        }
        rows.append("<row r=\"1\">\(headerCells.joined())</row>")

        for (rowIndex, row) in table.rows.enumerated() {
            let rowNumber = rowIndex + 2
            let cells = row.enumerated().map { index, value in
                dataCell(reference: "\(columnName(index))\(rowNumber)", value: value)
            }
            rows.append("<row r=\"\(rowNumber)\">\(cells.joined())</row>")
        }

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>\(rows.joined())</sheetData></worksheet>

        """
    }

    /// 文本单元格（inlineStr，避免额外的 sharedStrings 部件）
    private static func cell(reference: String, style: Int?, text: String) -> String {
        let styleAttribute = style.map { " s=\"\($0)\"" } ?? ""
        return "<c r=\"\(reference)\"\(styleAttribute) t=\"inlineStr\"><is><t>\(escape(text))</t></is></c>"
    }

    /// 数据单元格：数值写成数字，缺失的值留空
    private static func dataCell(reference: String, value: ExportValue) -> String {
        switch value {
        case .text(let text):
            return cell(reference: reference, style: nil, text: text)
        case .status(let status):
            return cell(reference: reference, style: nil, text: status.displayName)
        case .number(let number):
            guard let number else { return "<c r=\"\(reference)\"/>" }
            return "<c r=\"\(reference)\"><v>\(number)</v></c>"
        case .date(let date):
            guard let date else { return "<c r=\"\(reference)\"/>" }
            return cell(reference: reference, style: nil, text: ExportValueFormatter.dateFormatter.string(from: date))
        }
    }

    /// 列序号转 Excel 列名：0 → A，1 → B … 8 → I
    private static func columnName(_ index: Int) -> String {
        var name = ""
        var value = index
        repeat {
            name = String(UnicodeScalar(UInt8(65 + value % 26))) + name
            value = value / 26 - 1
        } while value >= 0
        return name
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private static func data(_ text: String) -> Data {
        Data(text.utf8)
    }

    // MARK: - 固定部件

    private static let contentTypesXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>

    """

    private static let rootRelationshipsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>

    """

    private static let workbookXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="PingDeck" sheetId="1" r:id="rId1"/></sheets></workbook>

    """

    private static let workbookRelationshipsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>

    """

    /// 只定义两套单元格样式：0 普通、1 表头加粗
    private static let stylesXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts><fills count="1"><fill><patternFill patternType="none"/></fill></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs></styleSheet>

    """
}
