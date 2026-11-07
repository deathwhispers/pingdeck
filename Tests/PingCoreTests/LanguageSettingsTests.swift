import XCTest
@testable import PingCore

final class LanguageSettingsTests: XCTestCase {
    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func testDefaultLanguageIsSystem() {
        XCTAssertEqual(PingSettings().language, .system)
    }

    func testLanguageRoundTrips() throws {
        let settings = PingSettings(language: .japanese)
        let data = try JSONEncoder().encode(AppConfiguration(targets: [], settings: settings))
        let decoded = try decoder().decode(AppConfiguration.self, from: data)
        XCTAssertEqual(decoded.settings.language, .japanese)
        XCTAssertEqual(decoded.settings, settings)
    }

    func testLegacyConfigurationWithoutLanguageFallsBackToSystem() throws {
        let json = """
        {
          "settings" : {
            "appearance" : "system",
            "interval" : 1,
            "maxConcurrent" : 16,
            "rotationInterval" : 30,
            "timeout" : 2
          },
          "targets" : []
        }
        """
        let configuration = try decoder().decode(AppConfiguration.self, from: Data(json.utf8))
        XCTAssertEqual(configuration.settings.language, .system)
    }

    func testUnknownLanguageFallsBackToSystem() throws {
        let json = """
        {
          "settings" : {
            "appearance" : "system",
            "interval" : 1,
            "language" : "fr",
            "maxConcurrent" : 16,
            "rotationInterval" : 30,
            "timeout" : 2
          },
          "targets" : []
        }
        """
        let configuration = try decoder().decode(AppConfiguration.self, from: Data(json.utf8))
        XCTAssertEqual(configuration.settings.language, .system)
    }
}
