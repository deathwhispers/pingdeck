import SwiftUI
import AppKit
import PingCore

/// 直接用 `swift run` 启动时进程没有 App Bundle，需要手动激活才能显示窗口
final class AppDelegate: NSObject, NSApplicationDelegate {
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
    }

    /// 返回 true 表示已存在其它实例，本进程应当退出
    private static func activateRunningInstance() -> Bool {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.batchping.app"
        let current = NSRunningApplication.current
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0 != current && !$0.isTerminated }
        guard let existing = others.first else { return false }
        existing.activate(options: [.activateAllWindows])
        return true
    }
}

@main
struct BatchPingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = BatchPingViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 940, minHeight: 480)
        }
    }
}
