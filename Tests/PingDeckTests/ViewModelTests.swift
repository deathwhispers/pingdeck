import XCTest
import PingCore
@testable import PingDeck

final class SelectionTests: XCTestCase {
    private func makeModel(_ hosts: [String]) -> PingDeckViewModel {
        let configuration = AppConfiguration(targets: hosts.map { PingTarget(host: $0) })
        return PingDeckViewModel(configuration: configuration, store: InMemoryConfigStore())
    }

    func testSelectAllAndClearSelection() {
        let model = makeModel(["a.com", "b.com", "c.com"])

        model.selectAll()
        XCTAssertEqual(model.selection.count, 3)

        model.clearSelection()
        XCTAssertTrue(model.selection.isEmpty)
    }

    func testRemoveTargetsRemovesOnlySelected() {
        let model = makeModel(["a.com", "b.com", "c.com"])
        let ids = model.targets.map { $0.id }

        model.removeTargets(ids: Set([ids[0], ids[2]]))

        XCTAssertEqual(model.targets.map { $0.host }, ["b.com"])
        XCTAssertTrue(model.selection.isEmpty)
    }

    /// 批量删除后，选中集合不能残留已删除的 id
    func testRemoveTargetsDropsStaleSelection() {
        let model = makeModel(["a.com", "b.com"])
        let ids = model.targets.map { $0.id }

        model.selection = Set(ids)
        model.removeTargets(ids: [ids[0]])

        XCTAssertEqual(model.selection, [ids[1]])
    }

    /// 导出全部：不受选中影响
    func testAllEntriesIgnoreSelection() {
        let model = makeModel(["a.com", "b.com", "c.com"])
        let ids = model.targets.map { $0.id }
        model.selection = [ids[1]]

        XCTAssertEqual(model.allEntries.count, 3)
    }

    /// 导出选中：只包含选中的行
    func testSelectedEntriesContainOnlySelectedRows() {
        let model = makeModel(["a.com", "b.com", "c.com"])
        let ids = model.targets.map { $0.id }
        model.selection = [ids[1]]

        XCTAssertEqual(model.selectedEntries.count, 1)
        XCTAssertEqual(model.selectedEntries.first?.target.host, "b.com")
    }
}

final class SettingsSheetTests: XCTestCase {
    /// 菜单里的“设置…”与工具栏按钮共用同一个 sheet 状态
    func testOpenSettingsSheetPresentsSettings() {
        let model = PingDeckViewModel(
            configuration: AppConfiguration(),
            store: InMemoryConfigStore()
        )

        model.openSettingsSheet()

        guard case .settings? = model.sheet else {
            return XCTFail("期望呈现设置 sheet，实际为 \(String(describing: model.sheet))")
        }
    }

    func testSetLanguageUpdatesLocaleImmediately() {
        let suiteName = "ViewModelLanguageTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let model = PingDeckViewModel(
            configuration: AppConfiguration(),
            store: InMemoryConfigStore(),
            languageDefaults: defaults
        )

        model.setLanguage(.english)

        XCTAssertEqual(model.settings.language, .english)
        XCTAssertEqual(defaults.stringArray(forKey: "AppleLanguages"), ["en"])
        XCTAssertEqual(L10n.locale.identifier, "en")
        XCTAssertNil(model.alert)
    }

    override func tearDown() {
        L10n.locale = .current
        super.tearDown()
    }
}

final class ClearAllTargetsTests: XCTestCase {
    func testClearAllTargetsRemovesEverything() {
        let configuration = AppConfiguration(targets: [PingTarget(host: "a.com"), PingTarget(host: "b.com")])
        let model = PingDeckViewModel(configuration: configuration, store: InMemoryConfigStore())
        model.selectAll()

        model.clearAllTargets()

        XCTAssertTrue(model.targets.isEmpty)
        XCTAssertTrue(model.selection.isEmpty)
    }
}

final class BulkImportModeTests: XCTestCase {
    private func makeModel(_ hosts: [String]) -> PingDeckViewModel {
        let configuration = AppConfiguration(targets: hosts.map { PingTarget(host: $0) })
        return PingDeckViewModel(configuration: configuration, store: InMemoryConfigStore())
    }

    /// 导入 CIDR 网段会展开为一个个独立目标
    func testImportingCIDRExpandsTargets() {
        let model = makeModel([])

        let result = model.importTargets("10.0.0.0/24", mode: .append)

        XCTAssertEqual(result.entries.count, 256)
        XCTAssertEqual(model.targets.count, 256)
        XCTAssertEqual(model.targets.first?.host, "10.0.0.0")
        XCTAssertEqual(model.targets.last?.host, "10.0.0.255")
    }

    /// 追加模式：保留现有目标，只在末尾加新的
    func testAppendModeKeepsExistingTargets() {
        let model = makeModel(["old.com"])

        let result = model.importTargets("new.com", mode: .append)

        XCTAssertEqual(result.entries.count, 1)
        XCTAssertEqual(model.targets.map { $0.host }, ["old.com", "new.com"])
    }

    /// 追加模式：与现有目标重复的行会被跳过
    func testAppendModeSkipsDuplicates() {
        let model = makeModel(["old.com"])

        let result = model.importTargets("old.com\nnew.com", mode: .append)

        XCTAssertEqual(result.entries.count, 1)
        XCTAssertEqual(result.rejected.count, 1)
        XCTAssertEqual(model.targets.map { $0.host }, ["old.com", "new.com"])
    }

    /// 替换模式：丢弃现有目标，只保留导入内容
    func testReplaceModeDiscardsExistingTargets() {
        let model = makeModel(["old.com", "older.com"])

        let result = model.importTargets("new.com", mode: .replace)

        XCTAssertEqual(result.entries.count, 1)
        XCTAssertEqual(model.targets.map { $0.host }, ["new.com"])
    }

    /// 替换模式下不与现有目标去重（现有目标本来就会被丢弃）
    func testReplaceModeDoesNotDeduplicateAgainstExisting() {
        let model = makeModel(["old.com"])

        let result = model.importTargets("old.com", mode: .replace)

        XCTAssertEqual(result.entries.count, 1)
        XCTAssertTrue(result.rejected.isEmpty)
        XCTAssertEqual(model.targets.map { $0.host }, ["old.com"])
    }
}

/// 启动时的目标同步
final class StartWithLoadedConfigurationTests: XCTestCase {
    /// 从配置加载的目标必须在启动时同步给引擎，否则点「开始」不会发起任何探测
    func testStartProbesTargetsLoadedFromConfiguration() {
        let loopback = PingTarget(host: "127.0.0.1")
        let configuration = AppConfiguration(
            targets: [loopback],
            settings: PingSettings(interval: 0.3, timeout: 1, maxConcurrent: 2, rotationInterval: 0)
        )
        let model = PingDeckViewModel(configuration: configuration, store: InMemoryConfigStore())

        model.start()
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if let stats = model.stats[loopback.id], stats.received > 0 { break }
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        }
        model.stop()

        XCTAssertGreaterThan(
            model.stats[loopback.id]?.received ?? 0, 0,
            "从配置加载的目标在点击开始后应开始探测"
        )
    }
}

/// 「添加」弹窗的网段展开
final class AddTargetsTests: XCTestCase {
    private func makeModel(_ hosts: [String]) -> PingDeckViewModel {
        let configuration = AppConfiguration(targets: hosts.map { PingTarget(host: $0) })
        return PingDeckViewModel(configuration: configuration, store: InMemoryConfigStore())
    }

    func testAddTargetsExpandsRangeAndAppliesEnabled() {
        let model = makeModel([])

        let result = model.addTargets(host: "10.0.0.1-3", note: "机房 A", enabled: false)

        XCTAssertEqual(result.entries.count, 3)
        XCTAssertEqual(model.targets.count, 3)
        XCTAssertTrue(model.targets.allSatisfy { $0.note == "机房 A" && !$0.enabled })
    }

    func testAddTargetsSkipsDuplicates() {
        let model = makeModel(["10.0.0.1"])

        let result = model.addTargets(host: "10.0.0.1-3", note: "", enabled: true)

        XCTAssertEqual(result.entries.map(\.host), ["10.0.0.2", "10.0.0.3"])
        XCTAssertEqual(model.targets.map(\.host), ["10.0.0.1", "10.0.0.2", "10.0.0.3"])
    }

    func testAddTargetsRejectsFullyDuplicateRange() {
        let model = makeModel(["10.0.0.1", "10.0.0.2"])

        let result = model.addTargets(host: "10.0.0.1-2", note: "", enabled: true)

        XCTAssertTrue(result.entries.isEmpty)
        XCTAssertEqual(model.targets.count, 2)
        XCTAssertEqual(result.rejected.first?.reason, .duplicate)
    }
}

/// 启动时自动匹配并发数
final class ConcurrencyAdjustmentTests: XCTestCase {
    private func makeModel(hosts: [String], concurrent: Int, disabled: Set<Int> = []) -> PingDeckViewModel {
        let targets = hosts.enumerated().map { index, host in
            PingTarget(host: host, enabled: !disabled.contains(index))
        }
        let configuration = AppConfiguration(
            targets: targets,
            settings: PingSettings(maxConcurrent: concurrent)
        )
        return PingDeckViewModel(configuration: configuration, store: InMemoryConfigStore())
    }

    func testAdjustRaisesConcurrencyToEnabledTargetCount() {
        let hosts = (1...20).map { "10.0.0.\($0)" }
        let model = makeModel(hosts: hosts, concurrent: 4)

        model.adjustConcurrencyForStart()

        XCTAssertEqual(model.settings.maxConcurrent, 20)
        XCTAssertNotNil(model.alert)
    }

    func testAdjustCapsAtLimit() {
        let hosts = (0..<600).map { "10.0.\($0 / 256).\($0 % 256)" }
        let model = makeModel(hosts: hosts, concurrent: 16)

        model.adjustConcurrencyForStart()

        XCTAssertEqual(model.settings.maxConcurrent, PingSettings.maxConcurrentLimit)
    }

    func testAdjustIgnoresDisabledTargets() {
        let hosts = (1...20).map { "10.0.0.\($0)" }
        let model = makeModel(hosts: hosts, concurrent: 4, disabled: Set(0..<5))

        model.adjustConcurrencyForStart()

        XCTAssertEqual(model.settings.maxConcurrent, 15)
    }

    func testAdjustDoesNotLowerConcurrency() {
        let model = makeModel(hosts: ["1.1.1.1"], concurrent: 64)

        model.adjustConcurrencyForStart()

        XCTAssertEqual(model.settings.maxConcurrent, 64)
        XCTAssertNil(model.alert)
    }

    func testQueuedCountReflectsTargetsBeyondConcurrency() {
        let hosts = (1...20).map { "10.0.0.\($0)" }
        let model = makeModel(hosts: hosts, concurrent: 4)

        XCTAssertEqual(model.enabledTargetCount, 20)
        XCTAssertEqual(model.queuedTargetCount, 16)
    }
}
