import Foundation

/// 解析出来的 IPv4 网段
struct IPv4Range: Equatable {
    /// 单个网段最多展开的地址数，避免误输入 /8 之类的大网段拖垮界面
    static let maxAddressCount = 1024

    let start: UInt32
    let end: UInt32

    var count: Int { Int(end - start + 1) }

    var addresses: [String] {
        guard count <= Self.maxAddressCount else { return [] }
        return (start...end).map(Self.string(from:))
    }

    enum ParseResult {
        /// 不是网段，按普通目标处理
        case notARange
        case range(IPv4Range)
        /// 看起来是网段但格式不对
        case invalid(String)
    }

    /// 支持 CIDR、完整范围与末段简写：
    /// - `10.0.0.0/24`
    /// - `10.0.0.1-10.0.0.254`
    /// - `10.0.0.1-254`
    static func parse(_ text: String) -> ParseResult {
        if text.contains("/") {
            return parseCIDR(text)
        }
        if text.contains("-") {
            return parseRange(text)
        }
        return .notARange
    }

    private static func parseCIDR(_ text: String) -> ParseResult {
        // 协议前缀与路径交给 TargetValidator 给出更贴切的提示
        guard !text.contains("://") else { return .notARange }
        let parts = text.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return .notARange }
        let addressText = String(parts[0])
        guard !addressText.contains(":") else {
            return .invalid("暂不支持 IPv6 网段，请填写 IPv4 网段")
        }
        guard let address = parseIPv4(addressText) else { return .notARange }
        guard parts[1].allSatisfy(isASCIIDigit),
              let prefix = Int(parts[1]),
              (0...32).contains(prefix) else {
            return .invalid("网段格式不正确：请写成 10.0.0.0/24 这样的 CIDR")
        }

        let mask: UInt32 = prefix == 0 ? 0 : UInt32.max << UInt32(32 - prefix)
        // 只接受规范 CIDR：主机位必须为 0
        guard address & ~mask == 0 else {
            return .invalid("网段格式不正确：CIDR 请填写网络地址，例如 10.0.0.0/24")
        }

        let range = IPv4Range(start: address, end: address | ~mask)
        guard range.count <= maxAddressCount else {
            return .invalid("网段过大：单个网段最多支持 \(maxAddressCount) 个地址")
        }
        return .range(range)
    }

    private static func parseRange(_ text: String) -> ParseResult {
        // 主机名可能包含多个连字符，只有第一个连字符左侧是合法 IPv4 时才按范围处理
        guard let separator = text.firstIndex(of: "-") else { return .notARange }
        let startText = String(text[text.startIndex..<separator])
        guard let start = parseIPv4(startText) else { return .notARange }
        let endText = String(text[text.index(after: separator)...])
        guard !endText.isEmpty else {
            return .invalid("网段格式不正确：请写成 10.0.0.1-10.0.0.254 或 10.0.0.1-254")
        }

        let end: UInt32
        if let endAddress = parseIPv4(endText) {
            end = endAddress
        } else if endText.allSatisfy(isASCIIDigit),
                  let lastOctet = UInt32(endText),
                  lastOctet <= 255 {
            end = (start & 0xFFFF_FF00) | lastOctet
        } else {
            return .invalid("网段格式不正确：请写成 10.0.0.1-10.0.0.254 或 10.0.0.1-254")
        }

        guard end >= start else {
            return .invalid("网段格式不正确：结束地址不能小于起始地址")
        }
        let range = IPv4Range(start: start, end: end)
        guard range.count <= maxAddressCount else {
            return .invalid("网段过大：单个网段最多支持 \(maxAddressCount) 个地址")
        }
        return .range(range)
    }

    private static func parseIPv4(_ text: String) -> UInt32? {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return nil }
        var value: UInt32 = 0
        for part in parts {
            guard !part.isEmpty,
                  part.count <= 3,
                  part.allSatisfy(isASCIIDigit),
                  let octet = UInt32(part),
                  octet <= 255 else { return nil }
            value = (value << 8) | octet
        }
        return value
    }

    private static func isASCIIDigit(_ character: Character) -> Bool {
        character >= "0" && character <= "9"
    }

    private static func string(from value: UInt32) -> String {
        "\((value >> 24) & 0xFF).\((value >> 16) & 0xFF).\((value >> 8) & 0xFF).\(value & 0xFF)"
    }
}

/// 批量导入解析器
///
/// 每行一个目标或网段，支持 `目标` 或 `目标 备注` 两种写法（备注可含空格）。
/// 网段支持 CIDR、起止范围与末段简写；以 `#` 开头的行与空行会被忽略；
/// 重复目标与非法目标会被剔除并给出原因。
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

    /// 解析多行文本
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

            let (host, note) = split(line)
            append(
                host: host,
                note: note,
                lineNumber: index + 1,
                rawLine: line,
                seen: &seen,
                entries: &entries,
                rejected: &rejected
            )
        }

        return Result(entries: entries, rejected: rejected)
    }

    /// 解析单个输入（目标或网段），供「添加」弹窗使用
    /// - Parameter existing: 已存在的目标（用于去重），比较时忽略大小写
    public static func parse(host: String, note: String, existing: Set<String> = []) -> Result {
        var entries: [Entry] = []
        var rejected: [Rejected] = []
        var seen = Set(existing.map { $0.lowercased() })

        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawLine = trimmedNote.isEmpty ? trimmedHost : "\(trimmedHost) \(trimmedNote)"
        append(
            host: trimmedHost,
            note: trimmedNote,
            lineNumber: 1,
            rawLine: rawLine,
            seen: &seen,
            entries: &entries,
            rejected: &rejected
        )
        return Result(entries: entries, rejected: rejected)
    }

    /// 第一个空白字符之前是目标，之后整体作为备注
    private static func split(_ line: String) -> (host: String, note: String) {
        if let boundary = line.firstIndex(where: { $0 == " " || $0 == "\t" }) {
            return (
                String(line[line.startIndex..<boundary]),
                String(line[line.index(after: boundary)...]).trimmingCharacters(in: .whitespaces)
            )
        }
        return (line, "")
    }

    private static func append(
        host: String,
        note: String,
        lineNumber: Int,
        rawLine: String,
        seen: inout Set<String>,
        entries: inout [Entry],
        rejected: inout [Rejected]
    ) {
        switch IPv4Range.parse(host) {
        case .range(let range):
            var added = 0
            for address in range.addresses {
                let key = address.lowercased()
                guard !seen.contains(key) else { continue }
                seen.insert(key)
                entries.append(Entry(host: address, note: note))
                added += 1
            }
            if added == 0 {
                rejected.append(Rejected(line: lineNumber, text: rawLine, reason: "与已有目标重复"))
            }
            return
        case .invalid(let reason):
            rejected.append(Rejected(line: lineNumber, text: rawLine, reason: reason))
            return
        case .notARange:
            break
        }

        if let error = TargetValidator.validate(host) {
            rejected.append(Rejected(line: lineNumber, text: rawLine, reason: error))
            return
        }
        let key = host.lowercased()
        if seen.contains(key) {
            rejected.append(Rejected(line: lineNumber, text: rawLine, reason: "与已有目标重复"))
            return
        }
        seen.insert(key)
        entries.append(Entry(host: host, note: note))
    }
}
