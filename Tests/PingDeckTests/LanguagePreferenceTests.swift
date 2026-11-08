import XCTest
import PingCore
@testable import PingDeck

final class LanguagePreferenceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "LanguagePreferenceTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testEnglishWritesAppleLanguages() {
        LanguagePreference.apply(.english, defaults: defaults)
        XCTAssertEqual(defaults.stringArray(forKey: "AppleLanguages"), ["en"])
    }

    func testJapaneseWritesAppleLanguages() {
        LanguagePreference.apply(.japanese, defaults: defaults)
        XCTAssertEqual(defaults.stringArray(forKey: "AppleLanguages"), ["ja"])
    }

    func testSystemRemovesOverride() {
        LanguagePreference.apply(.english, defaults: defaults)
        LanguagePreference.apply(.system, defaults: defaults)
        defaults.synchronize()
        XCTAssertNil(defaults.persistentDomain(forName: suiteName)?["AppleLanguages"])
    }

    func testLocalizationCodeForManualLanguages() {
        XCTAssertEqual(LanguagePreference.localizationCode(for: .english), "en")
        XCTAssertEqual(LanguagePreference.localizationCode(for: .japanese), "ja")
        XCTAssertEqual(LanguagePreference.localizationCode(for: .simplifiedChinese), "zh-Hans")
    }
}
