import Foundation

/// TXT 导出：对齐的纯文本表格
///
/// 与 CSV 一样只输出明细，不附加汇总与导出时间，保证两类文件都是纯数据。
public enum TextExporter {
    public static func text(for entries: [ExportEntry], labels: ExportLabels) -> String {
        let table = ExportTable(entries: entries, labels: labels)

        let headers = table.columns.map(\.title)
        let rows = table.rows.map { row in
            row.enumerated().map { offset, value in
                ExportValueFormatter.display(value, format: table.columns[offset].format, labels: labels)
            }
        }
        let widths = (0..<table.columns.count).map { column in
            let contentWidth = rows.map { displayWidth($0[column]) }.max() ?? 0
            return max(displayWidth(headers[column]), contentWidth)
        }

        var lines = [formatRow(headers, widths: widths)]
        lines += rows.map { formatRow($0, widths: widths) }
        return lines.joined(separator: "\n") + "\n"
    }

    private static func formatRow(_ cells: [String], widths: [Int]) -> String {
        cells.enumerated().map { index, cell in
            let padding = widths[index] - displayWidth(cell)
            return cell + String(repeating: " ", count: padding)
        }.joined(separator: "  ")
    }

    /// 显示宽度：中日韩全角字符按两个字符计算
    static func displayWidth(_ text: String) -> Int {
        text.unicodeScalars.reduce(0) { $0 + (isWide($1) ? 2 : 1) }
    }

    private static func isWide(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x1100...0x115F,   // 韩文字母
             0x2E80...0x303E,   // 中日韩符号与标点
             0x3041...0x33FF,   // 假名、注音、兼容字符
             0x3400...0x4DBF,   // 中日韩统一表意文字扩展 A
             0x4E00...0x9FFF,   // 中日韩统一表意文字
             0xA000...0xA4CF,   // 彝文
             0xAC00...0xD7A3,   // 韩文音节
             0xF900...0xFAFF,   // 兼容表意文字
             0xFE30...0xFE6F,   // 中日韩兼容形式
             0xFF00...0xFF60,   // 全角 ASCII
             0xFFE0...0xFFE6:   // 全角符号
            return true
        default:
            return false
        }
    }
}
