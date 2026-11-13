import AppKit
import PingCore
import SwiftUI

final class WindowCloseInterceptor: NSObject, NSWindowDelegate {
    static let shared = WindowCloseInterceptor()
    private weak var model: PingDeckViewModel?
    private(set) weak var mainWindow: NSWindow?

    func setup(for window: NSWindow, model: PingDeckViewModel) {
        self.model = model
        self.mainWindow = window
        window.delegate = self
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard let model else { return true }
        switch model.settings.menuBar.closeBehavior {
        case .keepRunning:
            sender.orderOut(nil)
            return false
        case .terminate:
            NSApp.terminate(nil)
            return true
        case .ask:
            return handleAsk(sender: sender, model: model)
        }
    }

    private func handleAsk(sender: NSWindow, model: PingDeckViewModel) -> Bool {
        let alert = NSAlert()
        alert.messageText = String(localized: L10n.closeDialogTitle)
        alert.informativeText = String(localized: L10n.closeDialogMessage)
        alert.alertStyle = .informational
        alert.addButton(withTitle: String(localized: L10n.closeDialogKeepRunning))
        alert.addButton(withTitle: String(localized: L10n.closeDialogTerminate))
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = String(localized: L10n.closeDialogRemember)

        let response = alert.runModal()
        let remember = alert.suppressionButton?.state == .on

        if response == .alertFirstButtonReturn {
            // 用户选择保持后台常驻
            if remember {
                model.settings.menuBar.closeBehavior = .keepRunning
                model.saveSettings()
            }
            sender.orderOut(nil)
            return false
        } else {
            // 用户选择退出应用
            if remember {
                model.settings.menuBar.closeBehavior = .terminate
                model.saveSettings()
            }
            NSApp.terminate(nil)
            return true
        }
    }
}

extension PingDeckViewModel {
    func saveSettings() {
        saveNow()
    }
}

extension NSWindow {
    var isStatusBarWindow: Bool {
        if let statusBarClass = NSClassFromString("NSStatusBarWindow"), self.isKind(of: statusBarClass) {
            return true
        }
        return className.contains("StatusBar")
    }
}

private final class WindowAccessorView: NSView {
    var onWindow: ((NSWindow) -> Void)?

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = window {
            DispatchQueue.main.async { [weak self, weak window] in
                guard let window else { return }
                self?.onWindow?(window)
            }
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = WindowAccessorView()
        view.onWindow = onWindow
        DispatchQueue.main.async { [weak view] in
            if let window = view?.window {
                view?.onWindow?(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? WindowAccessorView {
            view.onWindow = onWindow
            if let window = view.window {
                DispatchQueue.main.async { [weak view, weak window] in
                    guard let window else { return }
                    view?.onWindow?(window)
                }
            }
        }
    }
}
