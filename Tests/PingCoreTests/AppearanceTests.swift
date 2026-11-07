import XCTest
@testable import PingCore

final class AppearanceModeTests: XCTestCase {
    func testDefaultIsSystem() {
        XCTAssertEqual(PingSettings().appearance, .system)
    }
}

final class AppearancePersistenceTests: XCTestCase {
    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// 旧版本配置没有 appearance 字段，解码必须成功并回落到跟随系统，
    /// 否则 ConfigStore.load() 会退回空配置，用户的目标全部丢失。
    func testLegacyConfigurationWithoutAppearanceLoadsAsSystem() throws {
        let json = """
        {
          "settings" : {
            "interval" : 1,
            "maxConcurrent" : 16,
            "rotationInterval" : 30,
            "timeout" : 2
          },
          "targets" : [
            {
              "enabled" : true,
              "host" : "1.1.1.1",
              "id" : "FA00834B-57DE-4E2B-A33B-CFC84B140058",
              "note" : "DNS"
            }
          ]
        }
        """

        let configuration = try decoder().decode(AppConfiguration.self, from: Data(json.utf8))

        XCTAssertEqual(configuration.settings.appearance, .system)
        XCTAssertEqual(configuration.targets.map(\.host), ["1.1.1.1"])
        XCTAssertEqual(configuration.settings.interval, 1)
    }

    func testAppearanceRoundTrips() throws {
        let settings = PingSettings(
            interval: 1,
            timeout: 2,
            maxConcurrent: 16,
            rotationInterval: 30,
            appearance: .dark
        )
        let data = try JSONEncoder().encode(AppConfiguration(targets: [], settings: settings))

        let decoded = try decoder().decode(AppConfiguration.self, from: data)

        XCTAssertEqual(decoded.settings.appearance, .dark)
        XCTAssertEqual(decoded.settings, settings)
    }

    func testUnknownAppearanceFallsBackToSystem() throws {
        let json = """
        {
          "settings" : {
            "appearance" : "sepia",
            "interval" : 1,
            "maxConcurrent" : 16,
            "rotationInterval" : 30,
            "timeout" : 2
          },
          "targets" : []
        }
        """

        let configuration = try decoder().decode(AppConfiguration.self, from: Data(json.utf8))

        XCTAssertEqual(configuration.settings.appearance, .system)
    }
}
