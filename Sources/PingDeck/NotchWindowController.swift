import AppKit
import SwiftUI
import Combine
import PingCore

/// 灵动岛无边框浮窗控制器与悬停防误触状态机
@MainActor
public final class NotchWindowController: NSObject, ObservableObject {
    public static let shared = NotchWindowController()

    // MARK: - Properties

    public private(set) var panel: NSPanel?
    private(set) weak var model: PingDeckViewModel?

    @Published public private(set) var isExpanded: Bool = false
    @Published public var isPinned: Bool = false

    public private(set) var expandTimer: Timer?
    public private(set) var collapseTimer: Timer?

    /// 鼠标移入展开延迟（默认 150ms）
    public var expandDelay: TimeInterval = 0.15
    /// 鼠标移出收起延迟（默认 300ms）
    public var collapseDelay: TimeInterval = 0.30

    private var cancellables = Set<AnyCancellable>()
    private var screenObserver: NSObjectProtocol?

    // MARK: - Initialization

    public override init() {
        super.init()
    }

    // MARK: - Lifecycle

    /// 启动控制器，创建并定位浮窗面板，监听屏幕与设置变动
    func start(with model: PingDeckViewModel) {
        self.model = model

        setupPanelIfNeeded()
        setupObservers()
        updateLayout()

        handleSettingsChanged(model.settings.notchIsland)
    }

    /// 停止控制器，隐藏并销毁面板，注销所有监听与定时器
    public func stop() {
        expandTimer?.invalidate()
        expandTimer = nil

        collapseTimer?.invalidate()
        collapseTimer = nil

        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }

        cancellables.removeAll()

        panel?.orderOut(nil)
        panel = nil

        isExpanded = false
        isPinned = false
        model = nil
    }

    // MARK: - Layout & Geometry

    /// 目标主屏幕
    private func targetScreen() -> NSScreen? {
        if let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) {
            return screen
        }
        return NSScreen.main ?? NSScreen.screens.first
    }

    public func currentGeometry() -> NotchGeometry {
        if let screen = targetScreen() {
            return NotchGeometry.calculate(for: screen)
        }
        return NotchGeometry.calculate(
            screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            safeAreaTopInset: 0,
            auxiliaryTopLeft: nil,
            auxiliaryTopRight: nil
        )
    }

    public func updateLayout() {
        let geometry = currentGeometry()
        panel?.setFrame(geometry.expandedPanelFrame, display: true)
    }

    private func setupPanelIfNeeded() {
        guard panel == nil else { return }

        let geometry = currentGeometry()
        let initialFrame = geometry.expandedPanelFrame

        let newPanel = NSPanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // 浮窗层级严格置于系统菜单栏上方，确保纯黑背景能完全覆盖物理刘海与顶沿菜单栏
        newPanel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 2)
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.isMovable = false
        newPanel.isMovableByWindowBackground = false
        newPanel.hidesOnDeactivate = false

        if let model {
            let containerView = NotchIslandContainerView(controller: self, model: model)
            let hostingView = NotchTrackingHostingView(rootView: AnyView(containerView), controller: self)
            newPanel.contentView = hostingView
        }

        self.panel = newPanel
    }

    private func setupObservers() {
        if screenObserver == nil {
            screenObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.updateLayout()
                }
            }
        }

        cancellables.removeAll()
        if let model {
            model.$settings
                .map(\.notchIsland)
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] settings in
                    self?.handleSettingsChanged(settings)
                }
                .store(in: &cancellables)
        }
    }

    private func handleSettingsChanged(_ settings: NotchIslandSettings) {
        if settings.enabled {
            setupPanelIfNeeded()
            updateLayout()
            panel?.orderFrontRegardless()
        } else {
            expandTimer?.invalidate()
            expandTimer = nil
            collapseTimer?.invalidate()
            collapseTimer = nil
            isExpanded = false
            panel?.orderOut(nil)
        }
    }

    // MARK: - State Machine & Hover Tracking

    public func onMouseEnter() {
        collapseTimer?.invalidate()
        collapseTimer = nil

        guard !isExpanded else { return }

        expandTimer?.invalidate()
        let timer = Timer(timeInterval: expandDelay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.expand()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.expandTimer = timer
    }

    public func onMouseLeave() {
        expandTimer?.invalidate()
        expandTimer = nil

        guard !isPinned else { return }
        guard isExpanded else { return }

        collapseTimer?.invalidate()
        let timer = Timer(timeInterval: collapseDelay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.collapse()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.collapseTimer = timer
    }

    public func expand() {
        expandTimer?.invalidate()
        expandTimer = nil
        isExpanded = true
    }

    public func expandImmediately() {
        expandTimer?.invalidate()
        expandTimer = nil
        collapseTimer?.invalidate()
        collapseTimer = nil
        isExpanded = true
    }

    public func collapse() {
        collapseTimer?.invalidate()
        collapseTimer = nil
        isExpanded = false
    }

    public func cancelCollapse() {
        collapseTimer?.invalidate()
        collapseTimer = nil
    }

    public func togglePin() {
        isPinned.toggle()
        if isPinned {
            collapseTimer?.invalidate()
            collapseTimer = nil
        }
    }

    /// 当前允许响应鼠标点击/悬停的有效区域（折叠态仅限刘海矩形，不阻挡两侧菜单栏）
    public func activeHitTestRect(in bounds: NSRect) -> NSRect {
        let geometry = currentGeometry()
        if isExpanded {
            return NSRect(
                x: 0,
                y: bounds.height - geometry.expandedSize.height,
                width: geometry.expandedSize.width,
                height: geometry.expandedSize.height
            )
        } else {
            let notchX = (bounds.width - geometry.notchRect.width) / 2
            let notchY = bounds.height - geometry.notchRect.height
            return NSRect(
                x: notchX,
                y: notchY,
                width: geometry.notchRect.width,
                height: geometry.notchRect.height
            )
        }
    }
}

// MARK: - Hosting & Container Views

final class NotchTrackingHostingView: NSHostingView<AnyView> {
    private var trackingArea: NSTrackingArea?
    private weak var controller: NotchWindowController?

    init(rootView: AnyView, controller: NotchWindowController) {
        self.controller = controller
        super.init(rootView: rootView)
    }

    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor required public init(rootView: AnyView) {
        super.init(rootView: rootView)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let controller else { return nil }
        let activeRect = controller.activeHitTestRect(in: bounds)
        guard activeRect.contains(point) else {
            // 当鼠标不在灵动岛当前有效范围内时（例如折叠态下的两侧菜单栏），返回 nil 让系统穿透点击菜单栏
            return nil
        }
        return super.hitTest(point)
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        guard let controller else { return }
        let point = convert(event.locationInWindow, from: nil)
        let activeRect = controller.activeHitTestRect(in: bounds)

        if !controller.isExpanded {
            if activeRect.contains(point) {
                controller.onMouseEnter()
            } else {
                controller.onMouseLeave()
            }
        } else {
            if activeRect.contains(point) {
                controller.cancelCollapse()
            } else {
                controller.onMouseLeave()
            }
        }
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        let point = convert(event.locationInWindow, from: nil)
        if let controller, controller.activeHitTestRect(in: bounds).contains(point) {
            controller.onMouseEnter()
        }
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        controller?.onMouseLeave()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let controller, !controller.isExpanded {
            let activeRect = controller.activeHitTestRect(in: bounds)
            if activeRect.contains(point) {
                // 点击物理刘海区域立即展开，无需等待 150ms 延时
                controller.expandImmediately()
                return
            }
        }
        super.mouseDown(with: event)
    }
}

struct NotchIslandContainerView: View {
    @ObservedObject var controller: NotchWindowController
    @ObservedObject var model: PingDeckViewModel

    var body: some View {
        NotchIslandView(controller: controller, model: model)
    }
}
