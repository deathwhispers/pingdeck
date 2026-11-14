import XCTest
import SwiftUI
import PingCore
@testable import PingDeck

@MainActor
final class NotchIslandViewTests: XCTestCase {
    private var controller: NotchWindowController!
    private var model: PingDeckViewModel!
    private var store: InMemoryConfigStore!

    override func setUp() async throws {
        try await super.setUp()
        controller = NotchWindowController()
        store = InMemoryConfigStore()
        model = PingDeckViewModel(configuration: AppConfiguration(), store: store)
    }

    override func tearDown() async throws {
        controller.stop()
        controller = nil
        model = nil
        store = nil
        try await super.tearDown()
    }

    func testNotchIslandViewInitialization() {
        let view = NotchIslandView(controller: controller, model: model)
        XCTAssertNotNil(view)
        XCTAssertTrue(view.controller === controller)
        XCTAssertTrue(view.model === model)

        let defaultView = NotchIslandView(model: model)
        XCTAssertNotNil(defaultView)
    }

    func testHostingViewLoadsNotchIslandView() {
        controller.start(with: model)
        guard let panel = controller.panel else {
            XCTFail("Panel should not be nil")
            return
        }

        XCTAssertNotNil(panel.contentView)
    }

    func testPinToggle() {
        XCTAssertFalse(controller.isPinned)
        controller.togglePin()
        XCTAssertTrue(controller.isPinned)
        controller.togglePin()
        XCTAssertFalse(controller.isPinned)
    }

    func testSettingsToggles() {
        XCTAssertTrue(model.settings.notchIsland.showMetrics)
        XCTAssertTrue(model.settings.notchIsland.showRecentProblems)
        XCTAssertTrue(model.settings.notchIsland.showQuickControls)

        model.settings.notchIsland.showMetrics = false
        XCTAssertFalse(model.settings.notchIsland.showMetrics)

        model.settings.notchIsland.showRecentProblems = false
        XCTAssertFalse(model.settings.notchIsland.showRecentProblems)

        model.settings.notchIsland.showQuickControls = false
        XCTAssertFalse(model.settings.notchIsland.showQuickControls)
    }

    func testProblemRowsInNotchIsland() {
        model.addTarget(host: "example.com", note: "Test Node")
        guard let id = model.targets.first?.id else {
            XCTFail("Target should exist")
            return
        }

        var stats = PingStats()
        stats.status = .timeout
        stats.message = "Request Timeout"
        model.setStats(for: id, stats)

        XCTAssertEqual(model.recentProblemRows.count, 1)
        XCTAssertEqual(model.recentProblemRows.first?.target.host, "example.com")
        XCTAssertEqual(model.recentProblemRows.first?.target.note, "Test Node")
    }
}
