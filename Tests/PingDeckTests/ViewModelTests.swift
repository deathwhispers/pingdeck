import XCTest
import PingCore
@testable import PingDeck

final class SelectionTests: XCTestCase {
    private func makeModel(_ hosts: [String]) -> PingDeckViewModel {
        let configuration = AppConfiguration(targets: hosts.map { PingTarget(host: $0) })
        return PingDeckViewModel(configuration: configuration)
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

final class ClearAllTargetsTests: XCTestCase {
    func testClearAllTargetsRemovesEverything() {
        let configuration = AppConfiguration(targets: [PingTarget(host: "a.com"), PingTarget(host: "b.com")])
        let model = PingDeckViewModel(configuration: configuration)
        model.selectAll()

        model.clearAllTargets()

        XCTAssertTrue(model.targets.isEmpty)
        XCTAssertTrue(model.selection.isEmpty)
    }
}

final class BulkImportModeTests: XCTestCase {
    private func makeModel(_ hosts: [String]) -> PingDeckViewModel {
        let configuration = AppConfiguration(targets: hosts.map { PingTarget(host: $0) })
        return PingDeckViewModel(configuration: configuration)
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
