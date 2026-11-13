import XCTest
@testable import PingCore

final class ConfigSerializationTests: XCTestCase {
    func testConfigurationRoundTrip() throws {
        let configuration = AppConfiguration(
            targets: [
                PingTarget(host: "1.1.1.1", note: "DNS", enabled: true),
                PingTarget(host: "example.com", note: "", enabled: false),
            ],
            settings: PingSettings(interval: 2, timeout: 3, maxConcurrent: 8, rotationInterval: 15)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(configuration)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AppConfiguration.self, from: data)

        XCTAssertEqual(decoded.targets, configuration.targets)
        XCTAssertEqual(decoded.settings, configuration.settings)
    }

    func testMenuBarSettingsRoundTrip() throws {
        let settings = MenuBarSettings(showTextLabel: false, closeBehavior: .keepRunning)
        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)
        let decoded = try JSONDecoder().decode(MenuBarSettings.self, from: data)
        XCTAssertEqual(decoded, settings)
    }

    func testNotchIslandSettingsRoundTrip() throws {
        let settings = NotchIslandSettings(enabled: true, showMetrics: true, showRecentProblems: false, showQuickControls: true)
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(NotchIslandSettings.self, from: data)
        XCTAssertEqual(decoded, settings)
    }

    func testPingSettingsDecodesLegacyJSONWithoutNotchIsland() throws {
        let legacyJSON = """
        {
          "interval": 1.0,
          "timeout": 2.0,
          "maxConcurrent": 16,
          "rotationInterval": 30.0,
          "appearance": "system",
          "language": "system"
        }
        """.data(using: .utf8)!

        let settings = try JSONDecoder().decode(PingSettings.self, from: legacyJSON)
        XCTAssertEqual(settings.notchIsland.enabled, true)
        XCTAssertEqual(settings.notchIsland.showMetrics, true)
        XCTAssertEqual(settings.notchIsland.showRecentProblems, true)
        XCTAssertEqual(settings.notchIsland.showQuickControls, true)
    }

    func testPingSettingsDecodesWithoutMenuBarFallback() throws {
        // 模拟旧版本没有 menuBar 字段的 JSON
        let json = """
        {
          "interval": 1.0,
          "timeout": 2.0,
          "maxConcurrent": 16,
          "rotationInterval": 30.0,
          "appearance": "system",
          "language": "system"
        }
        """.data(using: .utf8)!

        let settings = try JSONDecoder().decode(PingSettings.self, from: json)
        XCTAssertEqual(settings.menuBar.showTextLabel, true)
        XCTAssertEqual(settings.menuBar.closeBehavior, .ask)
    }

    func testTargetWithGroupAndColorTagRoundTrip() throws {
        let target = PingTarget(
            host: "10.0.0.1",
            note: "Gateway",
            enabled: true,
            group: "IDC-A",
            colorTag: .blue
        )
        let data = try JSONEncoder().encode(target)
        let decoded = try JSONDecoder().decode(PingTarget.self, from: data)
        XCTAssertEqual(decoded.host, "10.0.0.1")
        XCTAssertEqual(decoded.group, "IDC-A")
        XCTAssertEqual(decoded.colorTag, .blue)
    }

    func testTargetDecodesLegacyJSONWithoutGroupAndColor() throws {
        let legacyJSON = """
        {
          "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
          "host": "1.1.1.1",
          "note": "DNS",
          "enabled": true
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(PingTarget.self, from: legacyJSON)
        XCTAssertEqual(decoded.host, "1.1.1.1")
        XCTAssertEqual(decoded.group, "")
        XCTAssertNil(decoded.colorTag)
    }
}

/// 文件实现：读写到指定路径，不碰用户真实配置
final class FileConfigStoreTests: XCTestCase {
    func testRoundTripThroughFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pingdeck-config-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = FileConfigStore(url: url)
        let configuration = AppConfiguration(
            targets: [PingTarget(host: "1.1.1.1", note: "DNS", enabled: true)],
            settings: PingSettings(interval: 2, timeout: 3, maxConcurrent: 8, rotationInterval: 15)
        )

        try store.save(configuration)

        XCTAssertEqual(store.load().targets, configuration.targets)
        XCTAssertEqual(store.load().settings, configuration.settings)
    }

    /// 读不到文件时返回空配置
    func testLoadReturnsEmptyConfigurationWhenFileIsMissing() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pingdeck-missing-\(UUID().uuidString).json")
        let store = FileConfigStore(url: url)

        XCTAssertTrue(store.load().targets.isEmpty)
    }
}
