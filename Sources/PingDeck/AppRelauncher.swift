import AppKit
import Foundation

/// 切换语言后自动重启，确保 App 菜单、系统控件与界面文案使用同一语言。
enum AppRelauncher {
    static func relaunch() {
        let isAppBundle = Bundle.main.bundleURL.pathExtension == "app"
        let target = isAppBundle
            ? Bundle.main.bundleURL.path
            : (Bundle.main.executableURL?.path ?? CommandLine.arguments[0])
        let pid = String(ProcessInfo.processInfo.processIdentifier)

        // 等待旧进程退出后再启动新实例，避免单实例检查把新实例误判为重复。
        // 最多等 3 秒；超时则向旧进程发 SIGTERM，确保重启不会卡住。
        let launch = isAppBundle ? "/usr/bin/open -n \"$2\"" : "\"$2\""
        let script = """
        for _ in $(seq 1 15); do
            kill -0 "$1" 2>/dev/null || break
            sleep 0.2
        done
        if kill -0 "$1" 2>/dev/null; then
            kill -TERM "$1" 2>/dev/null || true
        fi
        while kill -0 "$1" 2>/dev/null; do
            sleep 0.2
        done
        \(launch)
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", script, "relaunch", pid, target]
        do {
            try process.run()
        } catch {
            NSLog("PingDeck relaunch failed: \(error)")
        }

        // 菜单选择回调中同步调用 terminate 可能被忽略，延迟到下一个运行循环。
        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }
}
