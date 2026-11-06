import XCTest
import PingCore
@testable import PingDeck

/// 测试用的内存配置存储：避免单元测试写坏用户真实的配置文件
final class InMemoryConfigStore: ConfigStoring {
    var saved: AppConfiguration?

    func load() -> AppConfiguration {
        saved ?? AppConfiguration()
    }

    func save(_ configuration: AppConfiguration) throws {
        saved = configuration
    }
}

/// 配置读写必须可注入
final class ConfigStoreInjectionTests: XCTestCase {
    /// 保存必须写到注入的存储里
    func testSavingWritesToInjectedStore() throws {
        let store = InMemoryConfigStore()
        let model = PingDeckViewModel(configuration: AppConfiguration(), store: store)

        model.addTarget(host: "1.1.1.1", note: "DNS", enabled: true)
        model.saveNow()

        let saved = try XCTUnwrap(store.saved)
        XCTAssertEqual(saved.targets.map(\.host), ["1.1.1.1"])
    }

    /// 不传配置时从注入的存储里读
    func testLoadingUsesInjectedStore() {
        let store = InMemoryConfigStore()
        store.saved = AppConfiguration(targets: [PingTarget(host: "9.9.9.9")])

        let model = PingDeckViewModel(store: store)

        XCTAssertEqual(model.targets.map(\.host), ["9.9.9.9"])
    }
}

/// 外观设置需要随配置一起持久化
final class AppearanceSettingTests: XCTestCase {
    func testAppearanceChangeIsSaved() throws {
        let store = InMemoryConfigStore()
        let model = PingDeckViewModel(configuration: AppConfiguration(), store: store)

        model.settings.appearance = .dark
        model.saveNow()

        XCTAssertEqual(try XCTUnwrap(store.saved).settings.appearance, .dark)
    }
}
