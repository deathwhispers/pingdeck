import Foundation

/// 网段解析错误
public enum IPv4RangeError: Equatable, Sendable {
    case ipv6Unsupported
    case malformedCIDR
    case cidrNotNetworkAddress
    case rangeTooLarge(limit: Int)
    case malformedRange
    case endBeforeStart
}

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
        case invalid(IPv4RangeError)
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
            return .invalid(.ipv6Unsupported)
        }
        guard let address = parseIPv4(addressText) else { return .notARange }
        guard parts[1].allSatisfy(isASCIIDigit),
              let prefix = Int(parts[1]),
              (0...32).contains(prefix) else {
            return .invalid(.malformedCIDR)
        }

        let mask: UInt32 = prefix == 0 ? 0 : UInt32.max << UInt32(32 - prefix)
        // 只接受规范 CIDR：主机位必须为 0
        guard address & ~mask == 0 else {
            return .invalid(.cidrNotNetworkAddress)
        }

        let range = IPv4Range(start: address, end: address | ~mask)
        guard range.count <= maxAddressCount else {
            return .invalid(.rangeTooLarge(limit: maxAddressCount))
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
            return .invalid(.malformedRange)
        }

        let end: UInt32
        if let endAddress = parseIPv4(endText) {
            end = endAddress
        } else if endText.allSatisfy(isASCIIDigit),
                  let lastOctet = UInt32(endText),
                  lastOctet <= 255 {
            end = (start & 0xFFFF_FF00) | lastOctet
        } else {
            return .invalid(.malformedRange)
        }

        guard end >= start else {
            return .invalid(.endBeforeStart)
        }
        let range = IPv4Range(start: start, end: end)
        guard range.count <= maxAddressCount else {
            return .invalid(.rangeTooLarge(limit: maxAddressCount))
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
        public let group: String
        public let colorTag: TargetColorTag?

        public init(
            host: String,
            note: String,
            group: String = "",
            colorTag: TargetColorTag? = nil
        ) {
            self.host = host
            self.note = note
            self.group = group
            self.colorTag = colorTag
        }
    }

    public enum RejectionReason: Equatable, Sendable {
        case duplicate
        case invalidTarget(TargetValidationIssue)
        case invalidRange(IPv4RangeError)
    }

    public struct Rejected: Equatable, Sendable {
        public let line: Int
        public let text: String
        public let reason: RejectionReason

        public init(line: Int, text: String, reason: RejectionReason) {
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
    public static func parse(
        _ text: String,
        existing: Set<String> = [],
        defaultGroup: String = "",
        defaultColorTag: TargetColorTag? = nil
    ) -> Result {
        var entries: [Entry] = []
        var rejected: [Rejected] = []
        var seen = Set(existing.map { $0.lowercased() })

        let lines = text.components(separatedBy: .newlines)
        for (index, rawLine) in lines.enumerated() {
            // 用 whitespacesAndNewlines 修剪，顺带去掉 CRLF 文件里的 \r
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") { continue }

            let (host, note, group, colorTag) = split(
                line,
                defaultGroup: defaultGroup,
                defaultColorTag: defaultColorTag
            )
            append(
                host: host,
                note: note,
                group: group,
                colorTag: colorTag,
                lineNumber: index + 1,
                rawLine: line,
                seen: &seen,
                entries: &entries,
                rejected: &rejected
            )
        }

        return Result(entries: entries, rejected: rejected)
    }

    /// 便捷重载：支持 labeled `text:` 参数
    public static func parse(
        text: String,
        existing: Set<String> = [],
        defaultGroup: String = "",
        defaultColorTag: TargetColorTag? = nil
    ) -> Result {
        parse(text, existing: existing, defaultGroup: defaultGroup, defaultColorTag: defaultColorTag)
    }

    /// 解析单个输入（目标或网段），供「添加」弹窗使用
    /// - Parameter existing: 已存在的目标（用于去重），比较时忽略大小写
    public static func parse(
        host: String,
        note: String,
        group: String = "",
        colorTag: TargetColorTag? = nil,
        existing: Set<String> = []
    ) -> Result {
        var entries: [Entry] = []
        var rejected: [Rejected] = []
        var seen = Set(existing.map { $0.lowercased() })

        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGroup = group.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawLine = trimmedNote.isEmpty ? trimmedHost : "\(trimmedHost) \(trimmedNote)"
        append(
            host: trimmedHost,
            note: trimmedNote,
            group: trimmedGroup,
            colorTag: colorTag,
            lineNumber: 1,
            rawLine: rawLine,
            seen: &seen,
            entries: &entries,
            rejected: &rejected
        )
        return Result(entries: entries, rejected: rejected)
    }

    /// 支持逗号分隔（如 CSV 格式 `host,note,group,colorTag`）以及空白分隔
    private static func split(
        _ line: String,
        defaultGroup: String,
        defaultColorTag: TargetColorTag?
    ) -> (host: String, note: String, group: String, colorTag: TargetColorTag?) {
        if line.contains(",") {
            let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            // 如果第一列包含空格，说明逗号出现在备注内部（如 "1.1.1.1 DNS, Gateway"）而非作为 CSV 列分隔符，回退为空白字符分隔
            if let first = parts.first, !first.contains(where: { $0.isWhitespace }) {
                let host = first
                let note = parts.count > 1 ? parts[1] : ""
                let group: String
                if parts.count >= 3 && !parts[2].isEmpty {
                    group = parts[2]
                } else {
                    group = defaultGroup
                }
                let colorTag: TargetColorTag?
                if parts.count >= 4 {
                    let colorText = parts[3].trimmingCharacters(in: .whitespaces).lowercased()
                    colorTag = TargetColorTag(rawValue: colorText) ?? defaultColorTag
                } else {
                    colorTag = defaultColorTag
                }
                return (host, note, group, colorTag)
            }
        }

        if let boundary = line.firstIndex(where: { $0 == " " || $0 == "\t" }) {
            return (
                String(line[line.startIndex..<boundary]),
                String(line[line.index(after: boundary)...]).trimmingCharacters(in: .whitespaces),
                defaultGroup,
                defaultColorTag
            )
        }
        return (line, "", defaultGroup, defaultColorTag)
    }

    private static func append(
        host: String,
        note: String,
        group: String,
        colorTag: TargetColorTag?,
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
                entries.append(Entry(host: address, note: note, group: group, colorTag: colorTag))
                added += 1
            }
            if added == 0 {
                rejected.append(Rejected(line: lineNumber, text: rawLine, reason: .duplicate))
            }
            return
        case .invalid(let error):
            rejected.append(Rejected(line: lineNumber, text: rawLine, reason: .invalidRange(error)))
            return
        case .notARange:
            break
        }

        if let issue = TargetValidator.validate(host) {
            rejected.append(Rejected(line: lineNumber, text: rawLine, reason: .invalidTarget(issue)))
            return
        }
        let key = host.lowercased()
        if seen.contains(key) {
            rejected.append(Rejected(line: lineNumber, text: rawLine, reason: .duplicate))
            return
        }
        seen.insert(key)
        entries.append(Entry(host: host, note: note, group: group, colorTag: colorTag))
    }
}
