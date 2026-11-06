import Foundation

/// 目标（IP 或域名）校验失败原因
public enum TargetValidationIssue: Equatable, Sendable {
    case empty
    case protocolPrefix
    case path
    case whitespace
    case invalidCharacters
}

/// 目标（IP 或域名）合法性校验
public enum TargetValidator {
    public static func validate(_ host: String) -> TargetValidationIssue? {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .empty }
        if trimmed.contains("://") { return .protocolPrefix }
        if trimmed.contains("/") { return .path }
        if trimmed.contains(" ") { return .whitespace }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_:[]%")
        if trimmed.rangeOfCharacter(from: allowed.inverted) != nil {
            return .invalidCharacters
        }
        return nil
    }
}
