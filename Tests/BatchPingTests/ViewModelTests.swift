import XCTest
import PingCore
@testable import BatchPing

final class SelectionTests: XCTestCase {
    private func makeModel(_ hosts: [String]) -> BatchPingViewModel {
        let configuration = AppConfiguration(targets: hosts.map { PingTarget(host: $0) })
        return BatchPingViewModel(configuration: configuration)
    }

    func testSelectOnlyReplacesPreviousSelection() {
        let model = makeModel(["a.com", "b.com", "c.com"])
        let ids = model.targets.map { $0.id }

        model.selectOnly(ids[0])
        model.selectOnly(ids[2])

        XCTAssertEqual(model.selection, [ids[2]])
    }

    func testToggleSelectionAddsAndRemoves() {
        let model = makeModel(["a.com", "b.com", "c.com"])
        let ids = model.targets.map { $0.id }

        model.toggleSelection(ids[0])
        model.toggleSelection(ids[2])
        XCTAssertEqual(model.selection, Set([ids[0], ids[2]]))

        model.toggleSelection(ids[0])
        XCTAssertEqual(model.selection, [ids[2]])
    }

    /// ⇧ 点击按表格当前顺序选中一段区间
    func testSelectRangeCoversIntervalInRowOrder() {
        let model = makeModel(["a.com", "b.com", "c.com", "d.com"])
        let rowIDs = model.rows.map { $0.id }

        model.selectOnly(rowIDs[0])
        model.selectRange(to: rowIDs[2])

        XCTAssertEqual(model.selection, Set(rowIDs[0...2]))
    }

    /// 反向拖选同样成立
    func testSelectRangeBackwards() {
        let model = makeModel(["a.com", "b.com", "c.com", "d.com"])
        let rowIDs = model.rows.map { $0.id }

        model.selectOnly(rowIDs[3])
        model.selectRange(to: rowIDs[1])

        XCTAssertEqual(model.selection, Set(rowIDs[1...3]))
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
}

final class ClearAllTargetsTests: XCTestCase {
    func testClearAllTargetsRemovesEverything() {
        let configuration = AppConfiguration(targets: [PingTarget(host: "a.com"), PingTarget(host: "b.com")])
        let model = BatchPingViewModel(configuration: configuration)
        model.selectAll()

        model.clearAllTargets()

        XCTAssertTrue(model.targets.isEmpty)
        XCTAssertTrue(model.selection.isEmpty)
    }
}

final class BulkImportModeTests: XCTestCase {
    private func makeModel(_ hosts: [String]) -> BatchPingViewModel {
        let configuration = AppConfiguration(targets: hosts.map { PingTarget(host: $0) })
        return BatchPingViewModel(configuration: configuration)
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
