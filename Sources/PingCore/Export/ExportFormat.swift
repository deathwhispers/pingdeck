import Foundation

/// 支持的导出格式
public enum ExportFormat: String, CaseIterable, Sendable {
    case csv
    case json
    case txt
    case markdown
    case xlsx

    /// 菜单里显示的名字
    public var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .txt: return "TXT"
        case .markdown: return "Markdown"
        case .xlsx: return "Excel (XLSX)"
        }
    }

    /// 文件扩展名（不含点）
    public var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .txt: return "txt"
        case .markdown: return "md"
        case .xlsx: return "xlsx"
        }
    }
}
