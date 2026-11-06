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
}
