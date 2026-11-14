import XCTest
import AppKit
import PingCore
@testable import PingDeck

@MainActor
final class NotchWindowControllerTests: XCTestCase {
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

    func testInitialState() {
        XCTAssertFalse(controller.isExpanded)
        XCTAssertFalse(controller.isPinned)
        XCTAssertNil(controller.panel)
        XCTAssertNil(controller.expandTimer)
        XCTAssertNil(controller.collapseTimer)
        XCTAssertEqual(controller.expandDelay, 0.15, accuracy: 0.001)
        XCTAssertEqual(controller.collapseDelay, 0.30, accuracy: 0.001)
    }

    func testStartCreatesPanelWithCorrectAttributes() {
        controller.start(with: model)

        guard let panel = controller.panel else {
            XCTFail("Panel should be created on start")
            return
        }

        XCTAssertEqual(panel.level, .mainMenu)
        XCTAssertFalse(panel.isOpaque)
        XCTAssertEqual(panel.backgroundColor, .clear)
        XCTAssertFalse(panel.hasShadow)
        XCTAssertTrue(panel.styleMask.contains(.borderless))
        XCTAssertTrue(panel.styleMask.contains(.nonactivatingPanel))
        XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllSpaces))
        XCTAssertTrue(panel.collectionBehavior.contains(.fullScreenAuxiliary))
        XCTAssertTrue(panel.collectionBehavior.contains(.ignoresCycle))
    }

    func testExpandAndCollapseDirectly() {
        controller.start(with: model)

        controller.expand()
        XCTAssertTrue(controller.isExpanded)

        controller.collapse()
        XCTAssertFalse(controller.isExpanded)
    }

    func testHoverExpandStateMachine() async throws {
        controller.start(with: model)
        controller.expandDelay = 0.05

        controller.onMouseEnter()
        XCTAssertNotNil(controller.expandTimer)
        XCTAssertFalse(controller.isExpanded)

        // 等待定时器触发
        try await Task.sleep(nanoseconds: 80_000_000)

        XCTAssertTrue(controller.isExpanded)
        XCTAssertNil(controller.expandTimer)
    }

    func testHoverFastPassCancelsExpand() async throws {
        controller.start(with: model)
        controller.expandDelay = 0.05

        controller.onMouseEnter()
        XCTAssertNotNil(controller.expandTimer)

        // 快速移出（小于 50ms）
        try await Task.sleep(nanoseconds: 10_000_000)
        controller.onMouseLeave()

        XCTAssertNil(controller.expandTimer)

        // 等待超过 50ms 验证未触发 expand
        try await Task.sleep(nanoseconds: 60_000_000)
        XCTAssertFalse(controller.isExpanded)
    }

    func testHoverCollapseStateMachine() async throws {
        controller.start(with: model)
        controller.collapseDelay = 0.05
        controller.expand()
        XCTAssertTrue(controller.isExpanded)

        controller.onMouseLeave()
        XCTAssertNotNil(controller.collapseTimer)
        XCTAssertTrue(controller.isExpanded)

        // 等待收起定时器触发
        try await Task.sleep(nanoseconds: 80_000_000)

        XCTAssertFalse(controller.isExpanded)
        XCTAssertNil(controller.collapseTimer)
    }

    func testHoverReenterCancelsCollapse() async throws {
        controller.start(with: model)
        controller.collapseDelay = 0.05
        controller.expand()

        controller.onMouseLeave()
        XCTAssertNotNil(controller.collapseTimer)

        // 在收起前快速重新移入
        try await Task.sleep(nanoseconds: 15_000_000)
        controller.onMouseEnter()

        XCTAssertNil(controller.collapseTimer)
        XCTAssertTrue(controller.isExpanded)

        // 等待超过收起时间确认仍然保持展开
        try await Task.sleep(nanoseconds: 60_000_000)
        XCTAssertTrue(controller.isExpanded)
    }

    func testTogglePinPreventsCollapse() async throws {
        controller.start(with: model)
        controller.collapseDelay = 0.05
        controller.expand()

        controller.togglePin()
        XCTAssertTrue(controller.isPinned)

        // 固定状态下离开，不应启动收起定时器
        controller.onMouseLeave()
        XCTAssertNil(controller.collapseTimer)
        XCTAssertTrue(controller.isExpanded)

        // 取消固定
        controller.togglePin()
        XCTAssertFalse(controller.isPinned)

        // 再次离开，应正常收起
        controller.onMouseLeave()
        XCTAssertNotNil(controller.collapseTimer)

        try await Task.sleep(nanoseconds: 80_000_000)
        XCTAssertFalse(controller.isExpanded)
    }

    func testSettingsEnabledChangeControlsVisibility() async throws {
        controller.start(with: model)
        XCTAssertNotNil(controller.panel)
        XCTAssertTrue(controller.panel?.isVisible ?? false)

        // 禁用灵动岛
        model.settings.notchIsland.enabled = false
        try await Task.sleep(nanoseconds: 20_000_000)
        XCTAssertFalse(controller.panel?.isVisible ?? true)

        // 重新启用
        model.settings.notchIsland.enabled = true
        try await Task.sleep(nanoseconds: 20_000_000)
        XCTAssertTrue(controller.panel?.isVisible ?? false)
    }

    func testStopTearsDownAllResources() {
        controller.start(with: model)
        controller.expand()
        controller.togglePin()

        controller.stop()

        XCTAssertNil(controller.panel)
        XCTAssertNil(controller.model)
        XCTAssertFalse(controller.isExpanded)
        XCTAssertFalse(controller.isPinned)
        XCTAssertNil(controller.expandTimer)
        XCTAssertNil(controller.collapseTimer)
    }
}
