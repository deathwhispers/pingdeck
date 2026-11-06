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
