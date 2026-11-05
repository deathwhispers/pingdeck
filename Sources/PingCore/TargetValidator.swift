import Foundation

/// 目标（IP 或域名）合法性校验
public enum TargetValidator {
    public static func validate(_ host: String) -> String? {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "目标不能为空" }
        if trimmed.contains("://") { return "请不要填写协议前缀，例如 http://" }
        if trimmed.contains("/") { return "请只填写主机名或 IP，不要带路径" }
        if trimmed.contains(" ") { return "目标不能包含空格" }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_:[]%")
        if trimmed.rangeOfCharacter(from: allowed.inverted) != nil {
            return "目标包含非法字符"
        }
        return nil
    }
}
