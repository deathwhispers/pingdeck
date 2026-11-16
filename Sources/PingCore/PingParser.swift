import Foundation

/// 从 ping 输出行中解析出的一条事件
public enum PingEvent: Equatable, Sendable {
    /// 收到回包
    case reply(seq: Int?, latencyMs: Double, peerAddress: String?, ttl: Int?)
    /// 超时（丢包）
    case timeout(seq: Int?)
    /// 网络不可达
    case unreachable(String)
    /// 致命错误（目标无效、权限不足等）
    case failure(String)
    /// 其它信息行，忽略即可
    case info(String)
}

/// macOS `ping` / `ping6` 输出解析器
public enum PingLineParser {
    public static func parse(_ rawLine: String) -> PingEvent {
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return .info("") }

        if line.hasPrefix("ping:") || line.hasPrefix("ping6:") {
            let body = line.drop(while: { $0 != ":" }).dropFirst()
            let text = String(body).trimmingCharacters(in: .whitespaces)
            return classifySystemMessage(text)
        }

        if let latency = latency(in: line) {
            return .reply(
                seq: sequence(in: line),
                latencyMs: latency,
                peerAddress: peerAddress(in: line),
                ttl: ttl(in: line)
            )
        }

        let lower = line.lowercased()
        if lower.contains("request timeout") || lower.contains("timeout for icmp_seq") || lower.hasPrefix("timeout") {
            return .timeout(seq: sequence(in: line))
        }
        if lower.contains("cannot resolve") || lower.contains("unknown host") || lower.contains("name or service not known") {
            return .failure(line)
        }
        return .info(line)
    }

    /// 处理 `ping: xxx` 形式的消息
    private static func classifySystemMessage(_ text: String) -> PingEvent {
        let lower = text.lowercased()
        if lower.contains("no route to host") || lower.contains("network is unreachable") || lower.contains("host is down") {
            return .unreachable(text)
        }
        if lower.contains("sendto") {
            // 发包失败，计为一次丢包，进程本身仍可继续运行
            return .timeout(seq: nil)
        }
        return .failure(text)
    }

    private static func latency(in line: String) -> Double? {
        guard let range = line.range(of: "time=") else { return nil }
        let tail = line[range.upperBound...]
        let number = tail.prefix { $0.isNumber || $0 == "." }
        guard let value = Double(number), value >= 0, value < 600_000 else { return nil }
        return value
    }

    /// 从 `64 bytes from <address>: ...` 中提取对端地址；IPv6 地址同样以冒号结尾
    private static func peerAddress(in line: String) -> String? {
        guard let range = line.range(of: "from ") else { return nil }
        let tail = line[range.upperBound...]
        let token = tail.prefix { !$0.isWhitespace }
        let address = token.hasSuffix(":") ? token.dropLast() : token
        return address.isEmpty ? nil : String(address)
    }

    /// IPv4 输出 `ttl=`，IPv6 输出 `hlim=`，两者都表示生存时间
    private static func ttl(in line: String) -> Int? {
        for key in ["ttl=", "hlim="] {
            guard let range = line.range(of: key) else { continue }
            let digits = line[range.upperBound...].prefix { $0.isNumber }
            if let value = Int(digits) {
                return value
            }
        }
        return nil
    }

    private static func sequence(in line: String) -> Int? {
        let marker: String
        if line.contains("icmp6_seq") {
            marker = "icmp6_seq"
        } else if line.contains("icmp_seq") {
            marker = "icmp_seq"
        } else {
            return nil
        }

        guard let range = line.range(of: marker) else { return nil }
        var tail = line[range.upperBound...]
        tail = tail.drop(while: { $0 == " " || $0 == "=" })
        let digits = tail.prefix { $0.isNumber }
        return Int(digits)
    }
}
