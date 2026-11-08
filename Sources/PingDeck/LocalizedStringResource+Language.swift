import Foundation
import PingCore

extension LocalizedStringResource {
    /// 用指定目标语言解析文案，主要用于语言切换的确认弹窗。
    func string(for language: AppLanguage, defaults: UserDefaults = .standard) -> String {
        let code = LanguagePreference.localizationCode(for: language, defaults: defaults)
        let localized = LocalizedStringResource(
            String.LocalizationValue(key),
            table: table,
            locale: Locale(identifier: code),
            bundle: bundle
        )
        return String(localized: localized)
    }
}
