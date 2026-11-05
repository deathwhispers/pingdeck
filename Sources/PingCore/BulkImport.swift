import Foundation

/// 批量导入解析器
///
/// 每行一个目标，支持 `目标` 或 `目标 备注` 两种写法（备注可含空格）。
/// 以 `#` 开头的行与空行会被忽略；重复目标与非法目标会被剔除并给出原因。
public enum BulkImportParser {
    public struct Entry: Equatable, Sendable {
        public let host: String
        public let note: String

        public init(host: String, note: String) {
            self.host = host
            self.note = note
        }
    }

    public struct Rejected: Equatable, Sendable {
        public let line: Int
        public let text: String
        public let reason: String

        public init(line: Int, text: String, reason: String) {
            self.line = line
            self.text = text
            self.reason = reason
        }
    }

    public struct Result: Equatable, Sendable {
        public let entries: [Entry]
        public let rejected: [Rejected]

        public init(entries: [Entry], rejected: [Rejected]) {
            self.entries = entries
            self.rejected = rejected
        }
    }

    /// - Parameter existing: 已存在的目标（用于去重），比较时忽略大小写
    public static func parse(_ text: String, existing: Set<String> = []) -> Result {
        var entries: [Entry] = []
        var rejected: [Rejected] = []
        var seen = Set(existing.map { $0.lowercased() })

        let lines = text.components(separatedBy: .newlines)
        for (index, rawLine) in lines.enumerated() {
            // 用 whitespacesAndNewlines 修剪，顺带去掉 CRLF 文件里的 \r
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") { continue }

            // 第一个空白字符之前是目标，之后整体作为备注
            let host: String
            let note: String
            if let boundary = line.firstIndex(where: { $0 == " " || $0 == "\t" }) {
                host = String(line[line.startIndex..<boundary])
                note = String(line[line.index(after: boundary)...]).trimmingCharacters(in: .whitespaces)
            } else {
                host = line
                note = ""
            }

            if let error = TargetValidator.validate(host) {
                rejected.append(Rejected(line: index + 1, text: line, reason: error))
                continue
            }
            let key = host.lowercased()
            if seen.contains(key) {
                rejected.append(Rejected(line: index + 1, text: line, reason: "与已有目标重复"))
                continue
            }
            seen.insert(key)
            entries.append(Entry(host: host, note: note))
        }

        return Result(entries: entries, rejected: rejected)
    }
}
