import AppKit
import SwiftUI
import Combine
import PingCore

/// 灵动岛无边框浮窗控制器与全局鼠标悬停/点击事件监听器
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
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?

    // MARK: - Initialization

    public override init() {
        super.init()
    }

    // MARK: - Lifecycle

    /// 启动控制器，初始化浮窗与全局鼠标事件监听
    func start(with model: PingDeckViewModel) {
        self.model = model

        setupPanelIfNeeded()
        setupEventMonitors()
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

        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }

        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }

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

        let newPanel = NSPanel(
            contentRect: geometry.expandedPanelFrame,
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )
        // 使用 .floating 层级（保证浮动在应用窗口上方，同时绝对不会覆盖系统鼠标光标）
        newPanel.level = .floating
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.isMovable = false
        newPanel.isMovableByWindowBackground = false
        newPanel.hidesOnDeactivate = false

        if let model {
            let containerView = NotchIslandContainerView(controller: self, model: model)
            let hostingView = NSHostingView(rootView: AnyView(containerView))
            newPanel.contentView = hostingView
        }

        self.panel = newPanel
    }

    // MARK: - Observers & Event Monitoring

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

    private func setupEventMonitors() {
        if globalEventMonitor == nil {
            globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self] event in
                Task { @MainActor [weak self] in
                    self?.handleMouseEvent(event)
                }
            }
        }
        if localEventMonitor == nil {
            localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self] event in
                Task { @MainActor [weak self] in
                    self?.handleMouseEvent(event)
                }
                return event
            }
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

    // MARK: - Mouse Event Handling

    private func handleMouseEvent(_ event: NSEvent) {
        guard let model, model.settings.notchIsland.enabled else { return }
        let geometry = currentGeometry()
        let mouseLocation = NSEvent.mouseLocation

        // 刘海/居中感应区：包含物理刘海及下方留出的 10pt 舒适感应区
        let triggerRect = CGRect(
            x: geometry.notchRect.minX - 10,
            y: geometry.notchRect.minY - 10,
            width: geometry.notchRect.width + 20,
            height: geometry.notchRect.height + 14
        )

        // 展开面板实际覆盖区域（包含微小缓冲垫）
        let cardRect = CGRect(
            x: geometry.expandedPanelFrame.minX - 12,
            y: geometry.expandedPanelFrame.minY - 12,
            width: geometry.expandedPanelFrame.width + 24,
            height: geometry.expandedPanelFrame.height + 16
        )

        if event.type == .leftMouseDown {
            if !isExpanded && triggerRect.contains(mouseLocation) {
                // 点击物理刘海区域：立刻瞬间展开
                expand()
                return
            }
            if isExpanded && !isPinned && !cardRect.contains(mouseLocation) {
                // 点击卡片外部空白区域：立即收起
                collapse()
                return
            }
        }

        if event.type == .mouseMoved {
            if !isExpanded {
                if triggerRect.contains(mouseLocation) {
                    onMouseEnterTrigger()
                } else {
                    onMouseLeaveTrigger()
                }
            } else {
                if cardRect.contains(mouseLocation) {
                    collapseTimer?.invalidate()
                    collapseTimer = nil
                } else if !isPinned {
                    onMouseLeaveCard()
                }
            }
        }
    }

    public func onMouseEnter() {
        onMouseEnterTrigger()
    }

    public func onMouseLeave() {
        if isExpanded {
            onMouseLeaveCard()
        } else {
            onMouseLeaveTrigger()
        }
    }

    private func onMouseEnterTrigger() {
        collapseTimer?.invalidate()
        collapseTimer = nil

        guard !isExpanded else { return }
        guard expandTimer == nil else { return }

        expandTimer?.invalidate()
        let timer = Timer(timeInterval: expandDelay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.expand()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.expandTimer = timer
    }

    private func onMouseLeaveTrigger() {
        expandTimer?.invalidate()
        expandTimer = nil
    }

    private func onMouseLeaveCard() {
        guard !isPinned, isExpanded else { return }
        guard collapseTimer == nil else { return }

        let timer = Timer(timeInterval: collapseDelay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.collapse()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.collapseTimer = timer
    }

    // MARK: - Expand & Collapse

    public func expand() {
        expandTimer?.invalidate()
        expandTimer = nil
        collapseTimer?.invalidate()
        collapseTimer = nil

        guard !isExpanded else { return }

        setupPanelIfNeeded()
        updateLayout()
        panel?.orderFrontRegardless()

        isExpanded = true
    }

    public func collapse() {
        collapseTimer?.invalidate()
        collapseTimer = nil
        expandTimer?.invalidate()
        expandTimer = nil

        guard isExpanded else { return }
        isExpanded = false

        // 待 SwiftUI 弹簧收缩动画完成（约 350ms）后隐藏浮窗，完全释放菜单栏
        let timer = Timer(timeInterval: 0.35, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, !self.isExpanded else { return }
                self.panel?.orderOut(nil)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    public func togglePin() {
        isPinned.toggle()
        if isPinned {
            collapseTimer?.invalidate()
            collapseTimer = nil
        }
    }
}

// MARK: - Container View

struct NotchIslandContainerView: View {
    @ObservedObject var controller: NotchWindowController
    @ObservedObject var model: PingDeckViewModel

    var body: some View {
        NotchIslandView(controller: controller, model: model)
    }
}
