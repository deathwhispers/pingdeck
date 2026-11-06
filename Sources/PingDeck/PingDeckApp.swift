import SwiftUI
import AppKit
import PingCore

/// 直接用 `swift run` 启动时进程没有 App Bundle，需要手动激活才能显示窗口
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appearanceObservation: NSKeyValueObservation?

    func applicationWillFinishLaunching(_ notification: Notification) {
        let configuration = FileConfigStore().load()
        LanguagePreference.apply(configuration.settings.language)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 已经有实例在跑时激活它并退出自己，避免出现两个窗口、两套配置互相覆盖
        if Self.activateRunningInstance() {
            NSApp.terminate(nil)
            return
        }

        NSApp.setActivationPolicy(.regular)
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }

        applyAppearanceIcon()
        // 系统浅色/深色切换时同步 Dock 与 App Switcher 图标
        appearanceObservation = NSApp.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.applyAppearanceIcon()
            }
        }
    }

    deinit {
        appearanceObservation?.invalidate()
    }

    private func applyAppearanceIcon() {
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let name = isDark ? "AppIcon-Dark" : "AppIcon-Light"
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return }
        NSApp.applicationIconImage = image
    }

    /// 返回 true 表示已存在其它实例，本进程应当退出
    private static func activateRunningInstance() -> Bool {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.pingdeck.app"
        let current = NSRunningApplication.current
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0 != current && !$0.isTerminated }
        guard let existing = others.first else { return false }
        existing.activate(options: [.activateAllWindows])
        return true
    }
}

@main
struct PingDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = PingDeckViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(model.settings.appearance.colorScheme)
                .frame(minWidth: 1000, minHeight: 560)
        }
        .defaultSize(width: 1280, height: 760)
        .commands {
            // App 菜单中的“设置…”项，⌘, 打开现有设置 sheet
            CommandGroup(replacing: .appSettings) {
                Button("设置…") {
                    model.openSettingsSheet()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

private extension AppearanceMode {
    /// nil 表示跟随系统
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
