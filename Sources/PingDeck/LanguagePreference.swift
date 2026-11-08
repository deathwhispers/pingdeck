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

    /// 当前应用应使用的 locale；跟随系统时读取全局 AppleLanguages
    static func locale(for language: AppLanguage, defaults: UserDefaults = .standard) -> Locale {
        switch language {
        case .system:
            let global = defaults.persistentDomain(forName: UserDefaults.globalDomain)
            let languages = global?[appleLanguagesKey] as? [String]
            return Locale(identifier: languages?.first ?? Locale.current.identifier)
        case .simplifiedChinese, .english, .japanese:
            return Locale(identifier: language.rawValue)
        }
    }
}
