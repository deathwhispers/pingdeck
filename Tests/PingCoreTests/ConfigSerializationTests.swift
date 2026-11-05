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
