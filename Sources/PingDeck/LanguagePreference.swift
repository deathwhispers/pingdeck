import Foundation
import PingCore

/// 把应用语言写入/清除 `AppleLanguages`，重启后由系统按该语言加载资源。
enum LanguagePreference {
    static let appleLanguagesKey = "AppleLanguages"

    static func apply(_ language: AppLanguage, defaults: UserDefaults = .standard) {
        switch language {
        case .system:
            defaults.removeObject(forKey: appleLanguagesKey)
        case .simplifiedChinese, .english, .japanese:
            defaults.set([language.rawValue], forKey: appleLanguagesKey)
        }
    }

    /// 目标语言对应的资源代码；不支持的系统语言回落英文
    static func localizationCode(for language: AppLanguage, defaults: UserDefaults = .standard) -> String {
        switch language {
        case .system:
            let global = defaults.persistentDomain(forName: UserDefaults.globalDomain)
            let languages = global?[appleLanguagesKey] as? [String]
            let first = languages?.first ?? Locale.preferredLanguages.first ?? "en"
            if first.hasPrefix("zh-Hans") { return "zh-Hans" }
            if first.hasPrefix("ja") { return "ja" }
            return "en"
        case .simplifiedChinese:
            return "zh-Hans"
        case .english:
            return "en"
        case .japanese:
            return "ja"
        }
    }
}
