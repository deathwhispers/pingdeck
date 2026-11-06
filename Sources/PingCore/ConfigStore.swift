import Foundation

/// 配置的存放位置
public enum ConfigStore {
    public static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("PingDeck", isDirectory: true)
    }

    public static var configURL: URL {
        directoryURL.appendingPathComponent("config.json")
    }
}

/// 配置持久化接口
///
/// 界面层只依赖这个协议，测试可以注入内存实现，
/// 避免跑单元测试时把用户真实的配置写坏。
public protocol ConfigStoring {
    func load() -> AppConfiguration
    func save(_ configuration: AppConfiguration) throws
}

/// 默认实现：写到 ~/Library/Application Support/PingDeck/config.json
public struct FileConfigStore: ConfigStoring {
    private let url: URL

    public init(url: URL = ConfigStore.configURL) {
        self.url = url
    }

    public func load() -> AppConfiguration {
        guard let data = try? Data(contentsOf: url) else { return AppConfiguration() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let configuration = try? decoder.decode(AppConfiguration.self, from: data) else {
            return AppConfiguration()
        }
        return configuration
    }

    public func save(_ configuration: AppConfiguration) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(configuration)
        try data.write(to: url, options: .atomic)
    }
}
