import Foundation

/// 配置持久化：~/Library/Application Support/BatchPing/config.json
public enum ConfigStore {
    public static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("BatchPing", isDirectory: true)
    }

    public static var configURL: URL {
        directoryURL.appendingPathComponent("config.json")
    }

    public static func load() -> AppConfiguration {
        guard let data = try? Data(contentsOf: configURL) else { return AppConfiguration() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let configuration = try? decoder.decode(AppConfiguration.self, from: data) else {
            return AppConfiguration()
        }
        return configuration
    }

    public static func save(_ configuration: AppConfiguration) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(configuration)
        try data.write(to: configURL, options: .atomic)
    }
}
