# 菜单栏状态概览面板与后台常驻实施计划 (Implementation Plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 PingDeck 实现 macOS 菜单栏常驻状态项（显示「在线 X / 离线 Y」）、点击下拉状态概览面板（健康度概览卡片、异常节点列表、快捷控制）、主窗口关闭行为偏好控制（后台常驻/退出）及首发引导弹窗。

**Architecture:**
- 在 `PingCore` 中为 `PingSettings` 增加 `MenuBarSettings` 与 `WindowCloseBehavior`，支持配置持久化与历史配置安全向下兼容；
- 在 `PingDeckViewModel` 中提供菜单栏专用的统计指标、异常节点过滤及多语言标题格式化；
- 在 `PingDeckApp` 中声明原生 `MenuBarExtra`（配合 `.menuBarExtraStyle(.window)`），挂载 `MenuBarLabelView` 与 `MenuBarPanelView`；
- 通过 `NSWindowDelegate`（`WindowCloseInterceptor`）与 `AppDelegate` 拦截主窗口关闭动作，首次关闭时弹窗让用户选择后台常驻或退出，并在 Dock 点击时重新唤出主窗口；
- 在 `SettingsSheet` 中提供菜单栏文本开关与窗口关闭偏好设置项。

**Tech Stack:** Swift 5.9, macOS 14.4+ SDK, SwiftUI (`MenuBarExtra`), AppKit (`NSWindowDelegate`, `NSAlert`, `NSRunningApplication`), XCTest.

**Spec:** `docs/superpowers/specs/2026-11-13-menubar-status-overview-design.md`

## Global Constraints

- 严禁忽略需求或杜撰逻辑，严禁临时硬编码，严禁遗留 TODO。
- 一个 PR 只做一件事，所有改动须在分支 `feat/menubar-status` 上进行。
- 保证配置兼容性：解码旧版本缺失 `menuBar` 键的 JSON 配置时，必须平滑回落到默认值，不得解码失败。
- 所有对用户可见的文本均需在 `Localizable.xcstrings` 中配置简体中文 (`zh-Hans`)、英语 (`en`)、日语 (`ja`) 三种语言，并通过 `scripts/generate-localization-symbols.sh` 生成类型安全符号。
- 所有任务执行前后必须保证 `swift build` 与 `swift test` 全部通过。

---

### Task 1: 数据模型与配置序列化 (`MenuBarSettings` & `WindowCloseBehavior`)

**Files:**
- Modify: `Sources/PingCore/Models.swift`
- Test: `Tests/PingCoreTests/ConfigSerializationTests.swift`

**Interfaces:**
- Produces:
  ```swift
  public enum WindowCloseBehavior: String, Codable, CaseIterable, Sendable {
      case ask
      case keepRunning
      case terminate
  }

  public struct MenuBarSettings: Codable, Equatable, Sendable {
      public var showTextLabel: Bool
      public var closeBehavior: WindowCloseBehavior
      public init(showTextLabel: Bool = true, closeBehavior: WindowCloseBehavior = .ask)
  }
  ```
- Extends `PingSettings`:
  ```swift
  public var menuBar: MenuBarSettings
  ```

- [ ] **Step 1: 编写失败的单元测试**

在 `Tests/PingCoreTests/ConfigSerializationTests.swift` 中添加测试用例：
```swift
func testMenuBarSettingsRoundTrip() throws {
    let settings = MenuBarSettings(showTextLabel: false, closeBehavior: .keepRunning)
    let encoder = JSONEncoder()
    let data = try encoder.encode(settings)
    let decoded = try JSONDecoder().decode(MenuBarSettings.self, from: data)
    XCTAssertEqual(decoded, settings)
}

func testPingSettingsDecodesWithoutMenuBarFallback() throws {
    // 模拟旧版本没有 menuBar 字段的 JSON
    let json = """
    {
      "interval": 1.0,
      "timeout": 2.0,
      "maxConcurrent": 16,
      "rotationInterval": 30.0,
      "appearance": "system",
      "language": "system"
    }
    """.data(using: .utf8)!

    let settings = try JSONDecoder().decode(PingSettings.self, from: json)
    XCTAssertEqual(settings.menuBar.showTextLabel, true)
    XCTAssertEqual(settings.menuBar.closeBehavior, .ask)
}
```

- [ ] **Step 2: 运行测试以确认失败**

运行: `swift test --filter ConfigSerializationTests`
预期: 编译失败，提示 `MenuBarSettings` 未定义。

- [ ] **Step 3: 实现模型与解码逻辑**

在 `Sources/PingCore/Models.swift` 中添加 `WindowCloseBehavior` 与 `MenuBarSettings`，并更新 `PingSettings`:
```swift
/// 主窗口关闭时的处理行为
public enum WindowCloseBehavior: String, Codable, CaseIterable, Sendable {
    case ask              // 首次未决定，关闭时弹窗询问
    case keepRunning      // 保持后台常驻继续探测
    case terminate        // 直接退出应用
}

/// 菜单栏与后台生命周期偏好
public struct MenuBarSettings: Codable, Equatable, Sendable {
    public var showTextLabel: Bool
    public var closeBehavior: WindowCloseBehavior

    public init(
        showTextLabel: Bool = true,
        closeBehavior: WindowCloseBehavior = .ask
    ) {
        self.showTextLabel = showTextLabel
        self.closeBehavior = closeBehavior
    }
}
```
更新 `PingSettings`:
- 添加 `public var menuBar: MenuBarSettings`
- 在 `public init(...)` 参数中增加 `menuBar: MenuBarSettings = MenuBarSettings()`
- 在 `CodingKeys` 中增加 `case menuBar`
- 在 `init(from decoder: Decoder)` 中：
  ```swift
  menuBar = (try? container.decodeIfPresent(MenuBarSettings.self, forKey: .menuBar)) ?? MenuBarSettings()
  ```

- [ ] **Step 4: 运行测试验证通过**

运行: `swift test --filter ConfigSerializationTests`
预期: PASS

- [ ] **Step 5: 提交更改**

```bash
git add Sources/PingCore/Models.swift Tests/PingCoreTests/ConfigSerializationTests.swift
git commit -m "feat(core): 支持菜单栏与窗口关闭行为配置模型与向前兼容解码

Co-Authored-By: Claude Haiku 5.5 <noreply@Google.com>"
```

---

### Task 2: 国际化多语言文案与代码生成 (`Localizable.xcstrings` & `L10n`)

**Files:**
- Modify: `Sources/PingDeck/Resources/Localizable.xcstrings`
- Modify: `Sources/PingDeck/Generated/L10n.swift` (由脚本自动更新)
- Test: `Tests/PingDeckTests/LocalizationCatalogTests.swift`

**Interfaces:**
- Produces:
  - `L10n.menuBarSummary(alive: Int, problem: Int) -> LocalizedStringResource`
  - `L10n.menuBarOverviewTitle: LocalizedStringResource`
  - `L10n.menuBarOnlineRate: LocalizedStringResource`
  - `L10n.menuBarAvgLatency: LocalizedStringResource`
  - `L10n.menuBarAllNormal: LocalizedStringResource`
  - `L10n.menuBarRecentProblems: LocalizedStringResource`
  - `L10n.menuBarViewAllProblems: LocalizedStringResource`
  - `L10n.menuBarOpenMainWindow: LocalizedStringResource`
  - `L10n.menuBarPausePing: LocalizedStringResource`
  - `L10n.menuBarResumePing: LocalizedStringResource`
  - `L10n.menuBarQuit: LocalizedStringResource`
  - `L10n.closeDialogTitle: LocalizedStringResource`
  - `L10n.closeDialogMessage: LocalizedStringResource`
  - `L10n.closeDialogKeepRunning: LocalizedStringResource`
  - `L10n.closeDialogTerminate: LocalizedStringResource`
  - `L10n.closeDialogRemember: LocalizedStringResource`
  - `L10n.settingsMenuBarSection: LocalizedStringResource`
  - `L10n.settingsMenuBarShowText: LocalizedStringResource`
  - `L10n.settingsCloseBehavior: LocalizedStringResource`
  - `L10n.settingsCloseBehaviorAsk: LocalizedStringResource`
  - `L10n.settingsCloseBehaviorKeepRunning: LocalizedStringResource`
  - `L10n.settingsCloseBehaviorTerminate: LocalizedStringResource`

- [ ] **Step 1: 编辑 `Localizable.xcstrings` 填入多语言词条**

在 `Localizable.xcstrings` 的 `"strings"` 中添加上述所有键，并完整提供 `zh-Hans`、`en`、`ja` 三种语言的本地化译文：
- 中文示例：
  - `menu.bar.summary`: `在线 %lld  离线 %lld`
  - `close.dialog.title`: `关闭主窗口`
  - `close.dialog.message`: `你希望在菜单栏后台保持网络探测，还是直接退出应用？`
  - `close.dialog.keepRunning`: `保持后台运行`
  - `close.dialog.terminate`: `退出应用`
  - `close.dialog.remember`: `记住我的选择（可在设置中随时更改）`
- 英文示例：
  - `menu.bar.summary`: `%lld Up  %lld Down`
  - `close.dialog.title`: `Close Main Window`
  - `close.dialog.message`: `Would you like to keep PingDeck running in the menu bar, or quit the app?`
  - `close.dialog.keepRunning`: `Keep Running in Background`
  - `close.dialog.terminate`: `Quit App`
  - `close.dialog.remember`: `Remember my choice (can be changed in Settings)`
- 日文示例：
  - `menu.bar.summary`: `オンライン %lld  オフライン %lld`
  - `close.dialog.title`: `メインウィンドウを閉じる`
  - `close.dialog.message`: `メニューバーのバックグラウンドで監視を継続しますか、それともアプリケーションを終了しますか？`
  - `close.dialog.keepRunning`: `バックグラウンドで継続`
  - `close.dialog.terminate`: `終了`
  - `close.dialog.remember`: `選択を記憶する（設定でいつでも変更可能）`

- [ ] **Step 2: 执行代码生成脚本**

运行: `bash scripts/generate-localization-symbols.sh`
预期: 脚本成功重新生成 `Sources/PingDeck/Generated/L10n.swift`，包含新增的类型安全属性和函数。

- [ ] **Step 3: 运行本地化检查测试**

运行: `swift test --filter Localization`
预期: PASS

- [ ] **Step 4: 提交更改**

```bash
git add Sources/PingDeck/Resources/Localizable.xcstrings Sources/PingDeck/Generated/L10n.swift
git commit -m "feat(i18n): 增加菜单栏、后台生命周期与提示弹窗的多语言文案

Co-Authored-By: Claude Haiku 5.5 <noreply@Google.com>"
```

---

### Task 3: ViewModel 状态指标扩展与单元测试

**Files:**
- Modify: `Sources/PingDeck/PingDeckViewModel.swift`
- Test: `Tests/PingDeckTests/ViewModelTests.swift`

**Interfaces:**
- Produces in `PingDeckViewModel`:
  ```swift
  /// 所有在线目标的平均延迟（毫秒），无在线目标时为 nil
  public var averageAliveLatency: Double? { get }
  /// 状态异常（超时、不可达、错误）的前 5 个目标
  public var recentProblemRows: [PingTableRow] { get }
  /// 菜单栏标题显示文本（例如 "在线 42  离线 3"）
  public var menuBarTitle: String { get }
  ```

- [ ] **Step 1: 编写失败的单元测试**

在 `Tests/PingDeckTests/ViewModelTests.swift` 中添加测试用例：
```swift
func testMenuBarTitleAndMetrics() {
    let store = InMemoryConfigStore()
    let model = PingDeckViewModel(configStore: store)

    // 添加 2 个目标
    model.addTargets(host: "1.1.1.1", note: "DNS1", enabled: true)
    model.addTargets(host: "1.0.0.1", note: "DNS2", enabled: true)

    // 默认未探测前
    XCTAssertEqual(model.aliveCount, 0)
    XCTAssertEqual(model.problemCount, 0)
    XCTAssertEqual(model.recentProblemRows.count, 0)
    XCTAssertNil(model.averageAliveLatency)

    // 验证格式化文本生成
    let title = model.menuBarTitle
    XCTAssertFalse(title.isEmpty)
}
```

- [ ] **Step 2: 运行测试以确认失败**

运行: `swift test --filter ViewModelTests`
预期: 编译失败，找不到 `averageAliveLatency`、`recentProblemRows` 或 `menuBarTitle`。

- [ ] **Step 3: 在 `PingDeckViewModel` 中实现计算逻辑**

在 `Sources/PingDeck/PingDeckViewModel.swift` 中实现：
```swift
public var averageAliveLatency: Double? {
    let aliveRows = rows.filter { $0.stats.status == .alive }
    let validRtts = aliveRows.compactMap { $0.stats.rttAvg ?? $0.stats.rttLast }
    guard !validRtts.isEmpty else { return nil }
    return validRtts.reduce(0, +) / Double(validRtts.count)
}

public var recentProblemRows: [PingTableRow] {
    rows.filter { row in
        row.stats.status == .timeout || row.stats.status == .unreachable || row.stats.status == .error
    }
    .sorted { $0.stats.status.sortRank < $1.stats.status.sortRank }
    .prefix(5)
    .map { $0 }
}

public var menuBarTitle: String {
    String(localized: L10n.menuBarSummary(aliveCount, problemCount))
}
```

- [ ] **Step 4: 运行测试验证通过**

运行: `swift test --filter ViewModelTests`
预期: PASS

- [ ] **Step 5: 提交更改**

```bash
git add Sources/PingDeck/PingDeckViewModel.swift Tests/PingDeckTests/ViewModelTests.swift
git commit -m "feat(viewmodel): 增加菜单栏统计指标与异常节点提取

Co-Authored-By: Claude Haiku 5.5 <noreply@Google.com>"
```

---

### Task 4: 菜单栏标签与下拉面板视图 (`MenuBarLabelView` & `MenuBarPanelView`)

**Files:**
- Create: `Sources/PingDeck/MenuBarLabelView.swift`
- Create: `Sources/PingDeck/MenuBarPanelView.swift`

**Interfaces:**
- Produces:
  ```swift
  struct MenuBarLabelView: View {
      @ObservedObject var model: PingDeckViewModel
  }

  struct MenuBarPanelView: View {
      @ObservedObject var model: PingDeckViewModel
      var onOpenMainWindow: () -> Void
      var onOpenSettings: () -> Void
  }
  ```

- [ ] **Step 1: 创建 `Sources/PingDeck/MenuBarLabelView.swift`**

实现状态栏常驻标签视图：
- 图标：若 `model.problemCount > 0`，使用告警状态图标 `network.slash` 或带黄色/红色的网络指示；若无异常，使用 `network` 或绿点指示。
- 文本：若 `model.settings.menuBar.showTextLabel` 为 `true`，展示 `model.menuBarTitle`；若为 `false`，则隐藏文本仅留图标。

- [ ] **Step 2: 创建 `Sources/PingDeck/MenuBarPanelView.swift`**

实现宽度 320pt 的概览面板：
1. **健康度卡片 (Overview Card)**:
   - 计算在线率百分比与平均延迟毫秒显示。
   - 包含 🟢 在线、🔴 异常、⚪ 排队数药丸标签。
2. **异常列表 (Problem List)**:
   - 若 `model.recentProblemRows.isEmpty`，展示居中「🎉 所有监控节点均正常」绿色状态文案。
   - 若非空，展示前 5 个异常节点条目（主机名、备注、状态红点及错误描述），点击跳转/唤起主窗口。
   - 底部提供「在主窗口查看全部 (X)」按钮。
3. **底部操作栏 (Actions Bar)**:
   - 「打开主窗口」按钮（调用 `onOpenMainWindow`）。
   - 「暂停探测 / 继续探测」按钮（调用 `model.toggleEngine()`）。
   - 「偏好设置…」按钮（调用 `onOpenSettings`）。
   - 分隔线。
   - 「退出 PingDeck」按钮（调用 `NSApp.terminate(nil)`）。

- [ ] **Step 3: 运行 `swift build` 验证编译**

运行: `swift build`
预期: 成功编译无错误。

- [ ] **Step 4: 提交更改**

```bash
git add Sources/PingDeck/MenuBarLabelView.swift Sources/PingDeck/MenuBarPanelView.swift
git commit -m "feat(ui): 实现菜单栏标签视图与下拉状态概览面板

Co-Authored-By: Claude Haiku 5.5 <noreply@Google.com>"
```

---

### Task 5: 窗口关闭拦截与生命周期协调 (`WindowCloseInterceptor` & `AppDelegate`)

**Files:**
- Create: `Sources/PingDeck/WindowCloseInterceptor.swift`
- Modify: `Sources/PingDeck/PingDeckApp.swift`

**Interfaces:**
- Produces:
  ```swift
  final class WindowCloseInterceptor: NSObject, NSWindowDelegate {
      static let shared = WindowCloseInterceptor()
      func setup(for window: NSWindow, model: PingDeckViewModel)
  }
  ```

- [ ] **Step 1: 创建 `Sources/PingDeck/WindowCloseInterceptor.swift`**

实现主窗口关闭拦截：
```swift
import AppKit
import PingCore

final class WindowCloseInterceptor: NSObject, NSWindowDelegate {
    static let shared = WindowCloseInterceptor()
    private weak var model: PingDeckViewModel?

    func setup(for window: NSWindow, model: PingDeckViewModel) {
        self.model = model
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
```

- [ ] **Step 2: 更新 `AppDelegate` 与 `PingDeckApp.swift` 挂载 `MenuBarExtra` 与拦截器**

在 `AppDelegate` 中支持 Dock 点击重新打开主窗口：
```swift
func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
        if let window = NSApp.windows.first(where: { !($0 is NSStatusBarWindow) }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return true
        }
    }
    return true
}
```

在 `PingDeckApp.swift` 的 `ContentView` 挂载窗口委托，并添加 `MenuBarExtra`:
```swift
MenuBarExtra {
    MenuBarPanelView(
        model: model,
        onOpenMainWindow: {
            if let window = NSApp.windows.first(where: { !($0 is NSStatusBarWindow) }) {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        },
        onOpenSettings: {
            if let window = NSApp.windows.first(where: { !($0 is NSStatusBarWindow) }) {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            model.openSettingsSheet()
        }
    )
} label: {
    MenuBarLabelView(model: model)
}
.menuBarExtraStyle(.window)
```

- [ ] **Step 3: 运行 `swift build` 验证**

运行: `swift build`
预期: PASS

- [ ] **Step 4: 提交更改**

```bash
git add Sources/PingDeck/WindowCloseInterceptor.swift Sources/PingDeck/PingDeckApp.swift
git commit -m "feat(lifecycle): 支持窗口关闭拦截、首发引导询问弹窗与菜单栏挂载

Co-Authored-By: Claude Haiku 5.5 <noreply@Google.com>"
```

---

### Task 6: 设置界面扩展 (`SettingsSheet.swift`)

**Files:**
- Modify: `Sources/PingDeck/SettingsSheet.swift`
- Test: `Tests/PingDeckTests/ConfigStoreInjectionTests.swift`

**Interfaces:**
- Extends `SettingsSheet` UI:
  - 增加「菜单栏与后台」分组
  - 绑定 `model.settings.menuBar.showTextLabel`
  - 绑定 `model.settings.menuBar.closeBehavior`（Picker：`.keepRunning` / `.terminate` / `.ask`）

- [ ] **Step 1: 在 `SettingsSheet.swift` 中增加菜单栏与后台设置项**

在 `Form` 中添加 `Section`:
```swift
Section(header: Text(L10n.settingsMenuBarSection)) {
    Toggle(isOn: $settings.menuBar.showTextLabel) {
        Text(L10n.settingsMenuBarShowText)
    }

    Picker(L10n.settingsCloseBehavior, selection: $settings.menuBar.closeBehavior) {
        Text(L10n.settingsCloseBehaviorKeepRunning).tag(WindowCloseBehavior.keepRunning)
        Text(L10n.settingsCloseBehaviorTerminate).tag(WindowCloseBehavior.terminate)
        Text(L10n.settingsCloseBehaviorAsk).tag(WindowCloseBehavior.ask)
    }
}
```

- [ ] **Step 2: 验证设置保存测试**

运行: `swift test --filter ConfigStoreInjectionTests`
预期: PASS

- [ ] **Step 3: 提交更改**

```bash
git add Sources/PingDeck/SettingsSheet.swift
git commit -m "feat(settings): 在偏好设置中增加菜单栏文本与窗口关闭行为配置项

Co-Authored-By: Claude Haiku 5.5 <noreply@Google.com>"
```

---

### Task 7: 完整构建与端到端测试验证

**Files:**
- All modified/created files

- [ ] **Step 1: 运行全量单元测试**

运行: `swift test`
预期: 全部测试用例 100% 通过（0 failures）。

- [ ] **Step 2: 运行工程完整构建**

运行: `swift build`
预期: Build 成功无任何编译警告或错误。

- [ ] **Step 3: 检查代码格式与提交状态**

运行: `git status`
预期: 工作区干净，没有未提交的代码或临时文件。
