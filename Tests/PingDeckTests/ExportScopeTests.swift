import XCTest
import PingCore
@testable import PingDeck

final class ExportScopeTests: XCTestCase {
    private func makeModel(_ hosts: [String]) -> PingDeckViewModel {
        let configuration = AppConfiguration(targets: hosts.map { PingTarget(host: $0) })
        return PingDeckViewModel(configuration: configuration, store: InMemoryConfigStore())
    }

    func testResolvedAutomaticFollowsSelection() {
        XCTAssertEqual(ExportScope.automatic.resolved(hasSelection: true), .selection)
        XCTAssertEqual(ExportScope.automatic.resolved(hasSelection: false), .all)
        XCTAssertEqual(ExportScope.all.resolved(hasSelection: true), .all)
        XCTAssertEqual(ExportScope.selection.resolved(hasSelection: false), .selection)
    }

    func testAutomaticWithoutSelectionSavesAll() {
        let model = makeModel(["a.com", "b.com", "c.com"])

        let entries = ExportScope.automatic.entries(in: model)

        XCTAssertEqual(entries.map(\.target.host), ["a.com", "b.com", "c.com"])
    }

    func testAutomaticWithSelectionSavesOnlySelection() {
        let model = makeModel(["a.com", "b.com", "c.com"])
        let ids = model.targets.map(\.id)
        model.selection = [ids[1]]

        let entries = ExportScope.automatic.entries(in: model)

        XCTAssertEqual(entries.map(\.target.host), ["b.com"])
    }

    func testExplicitAllIgnoresSelection() {
        let model = makeModel(["a.com", "b.com"])
        model.selection = [model.targets[0].id]

        XCTAssertEqual(ExportScope.all.entries(in: model).count, 2)
    }

    func testExplicitSelectionWithoutSelectionIsEmpty() {
        let model = makeModel(["a.com", "b.com"])

        XCTAssertTrue(ExportScope.selection.entries(in: model).isEmpty)
    }

    /// 取消选中后应回到「保存全部」的默认范围
    func testClearingSelectionRestoresAutomaticAllScope() {
        let model = makeModel(["a.com", "b.com"])
        model.selection = [model.targets[0].id]

        model.clearSelection()

        XCTAssertEqual(ExportScope.automatic.entries(in: model).count, 2)
    }
}
