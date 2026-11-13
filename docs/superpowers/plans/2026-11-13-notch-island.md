# 刘海灵动岛扩展实施计划 (Implementation Plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 PingDeck 实现零打扰纯主动触发的刘海灵动岛扩展（鼠标划入刘海平滑下拉展开、移出收起、支持图钉固定），自适应物理刘海与无刘海大屏，核心指标/异常速览/控制栏模块可自由配置。

**Architecture:**
- 在 `PingCore/Models.swift` 中定义 `NotchIslandSettings`，扩展 `PingSettings` 并保证向前兼容历史配置安全反序列化；
- 在 `PingDeck/NotchGeometry.swift` 中提供屏幕硬件刘海与正上方居中定位算法；
- 在 `PingDeck/NotchWindowController.swift` 中管理独立的无边框置顶透明 `NSPanel`（`.floating` 层级，`.canJoinAllSpaces`），调度 150ms 防误触移入与 300ms 移出收缩状态机，支持图钉锁定；
- 在 `PingDeck/NotchIslandView.swift` 中用纯正深黑毛玻璃风格实现灵动岛展开面板，通过弹性弹簧动画呈现三大模块（核心指标、异常速览、快捷控制）；
- 在 `SettingsSheet.swift` 中集成灵动岛总开关与模块勾选开关。

**Tech Stack:** Swift 5.9, macOS 14.4+ SDK, AppKit (`NSPanel`, `NSScreen`, `NSEvent`), SwiftUI (`SpringAnimation`), XCTest.

**Spec:** `docs/superpowers/specs/2026-11-13-notch-island-design.md`

## Global Constraints

- 严禁忽略需求或杜撰逻辑，严禁临时硬编码，严禁遗留 TODO。
- 一个 PR 只做一件事，所有改动在分支 `feat/notch-island` 上进行。
- 保证配置兼容性：旧版缺少 `notchIsland` 键的 JSON 配置反序列化时必须平滑回退至默认值。
- 所有用户可见文案均需在 `Localizable.xcstrings` 中配置简体中文 (`zh-Hans`)、英语 (`en`)、日语 (`ja`) 三种语言，并通过 `scripts/generate-localization-symbols.sh` 生成。
- 每个任务完成时必须通过 `swift build` 与 `swift test`。

---

### Task 1: 灵动岛配置模型与向前兼容反序列化

**Files:**
- Modify: `Sources/PingCore/Models.swift`
- Test: `Tests/PingCoreTests/ConfigSerializationTests.swift`

**Interfaces:**
- Produces:
  ```swift
  public struct NotchIslandSettings: Codable, Equatable, Sendable {
      public var enabled: Bool
      public var showMetrics: Bool
      public var showRecentProblems: Bool
      public var showQuickControls: Bool

      public init(enabled: Bool = true, showMetrics: Bool = true, showRecentProblems: Bool = true, showQuickControls: Bool = true)
  }
  ```
- Extends `PingSettings`:
  ```swift
  public var notchIsland: NotchIslandSettings
  ```

- [ ] **Step 1: 编写失败的单元测试**

在 `Tests/PingCoreTests/ConfigSerializationTests.swift` 中添加测试：
```swift
func testNotchIslandSettingsRoundTrip() throws {
    let settings = NotchIslandSettings(enabled: true, showMetrics: true, showRecentProblems: false, showQuickControls: true)
    let data = try JSONEncoder().encode(settings)
    let decoded = try JSONDecoder().decode(NotchIslandSettings.self, from: data)
    XCTAssertEqual(decoded, settings)
}

func testPingSettingsDecodesLegacyJSONWithoutNotchIsland() throws {
    let legacyJSON = """
    {
      "interval": 1.0,
      "timeout": 2.0,
      "maxConcurrent": 16,
      "rotationInterval": 30.0,
      "appearance": "system",
      "language": "system"
    }
    """.data(using: .utf8)!

    let settings = try JSONDecoder().decode(PingSettings.self, from: legacyJSON)
    XCTAssertEqual(settings.notchIsland.enabled, true)
    XCTAssertEqual(settings.notchIsland.showMetrics, true)
    XCTAssertEqual(settings.notchIsland.showRecentProblems, true)
    XCTAssertEqual(settings.notchIsland.showQuickControls, true)
}
```

- [ ] **Step 2: 运行测试验证失败**

运行: `swift test --filter ConfigSerializationTests`
预期: 编译失败。

- [ ] **Step 3: 实现配置模型与解码回退**

在 `Sources/PingCore/Models.swift` 中添加 `NotchIslandSettings` 并在 `PingSettings` 中增加 `notchIsland` 属性与解码容错。

- [ ] **Step 4: 运行测试验证通过**

运行: `swift test --filter ConfigSerializationTests`
预期: PASS

- [ ] **Step 5: 提交更改**

```bash
git add Sources/PingCore/Models.swift Tests/PingCoreTests/ConfigSerializationTests.swift
git commit -m "feat(core): 增加灵动岛偏好配置模型与向前兼容反序列化

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: 国际化多语言文案扩展与代码生成

**Files:**
- Modify: `Sources/PingDeck/Resources/Localizable.xcstrings`
- Modify: `Sources/PingDeck/Generated/L10n.swift`
- Test: `Tests/PingDeckTests/LocalizationCatalogTests.swift`

**Interfaces:**
- Produces:
  - `L10n.settingsNotchIslandSection: LocalizedStringResource` ("刘海灵动岛" / "Notch Island" / "ノッチアイランド")
  - `L10n.settingsNotchIslandEnable: LocalizedStringResource` ("启用刘海灵动岛" / "Enable Notch Island" / "ノッチアイランドを有効にする")
  - `L10n.settingsNotchIslandShowMetrics: LocalizedStringResource` ("显示核心指标卡片" / "Show Health Metrics" / "メトリクスを表示")
  - `L10n.settingsNotchIslandShowRecentProblems: LocalizedStringResource` ("显示异常节点速览" / "Show Recent Problems" / "問題ノードの概要を表示")
  - `L10n.settingsNotchIslandShowQuickControls: LocalizedStringResource` ("显示快捷控制栏" / "Show Quick Controls" / "クイックコントロールを表示")
  - `L10n.notchIslandPinHelp: LocalizedStringResource` ("固定面板" / "Pin Island" / "固定する")
  - `L10n.notchIslandUnpinHelp: LocalizedStringResource` ("取消固定" / "Unpin Island" / "固定を解除")
  - `L10n.notchIslandAllNormal: LocalizedStringResource` ("所有节点正常" / "All Nodes Healthy" / "全ノード正常")

- [ ] **Step 1: 编辑 `Localizable.xcstrings` 添加词条**

添加上述所有键并配置 `zh-Hans`、`en`、`ja` 三语对照。

- [ ] **Step 2: 执行代码生成脚本**

运行: `bash scripts/generate-localization-symbols.sh`
预期: 成功更新 `L10n.swift`。

- [ ] **Step 3: 运行本地化测试**

运行: `swift test --filter Localization`
预期: PASS

- [ ] **Step 4: 提交更改**

```bash
git add Sources/PingDeck/Resources/Localizable.xcstrings Sources/PingDeck/Generated/L10n.swift
git commit -m "feat(i18n): 增加刘海灵动岛设置与面板多语言文案

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 3: 屏幕硬件刘海几何计算与自适应 (`NotchGeometry`)

**Files:**
- Create: `Sources/PingDeck/NotchGeometry.swift`
- Test: `Tests/PingDeckTests/NotchGeometryTests.swift`

**Interfaces:**
- Produces:
  ```swift
  public struct NotchGeometry: Equatable {
      public let hasPhysicalNotch: Bool
      public let notchRect: CGRect
      public let expandedSize: CGSize

      public static func calculate(for screen: NSScreen, expandedHeight: CGFloat) -> NotchGeometry
  }
  ```

- [ ] **Step 1: 编写单元测试**

在 `Tests/PingDeckTests/NotchGeometryTests.swift` 中模拟屏幕尺寸并验证有刘海与无刘海情况下的居中和几何尺寸。

- [ ] **Step 2: 运行测试以确认失败**

运行: `swift test --filter NotchGeometryTests`
预期: 失败。

- [ ] **Step 3: 实现 `NotchGeometry`**

在 `Sources/PingDeck/NotchGeometry.swift` 中实现尺寸计算逻辑。

- [ ] **Step 4: 运行测试验证通过**

运行: `swift test --filter NotchGeometryTests`
预期: PASS

- [ ] **Step 5: 提交更改**

```bash
git add Sources/PingDeck/NotchGeometry.swift Tests/PingDeckTests/NotchGeometryTests.swift
git commit -m "feat(ui): 实现硬件刘海与屏幕顶部居中几何计算引擎

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 4: 灵动岛无边框浮窗控制器与状态机 (`NotchWindowController`)

**Files:**
- Create: `Sources/PingDeck/NotchWindowController.swift`
- Modify: `Sources/PingDeck/PingDeckApp.swift`

**Interfaces:**
- Produces:
  ```swift
  @MainActor
  public final class NotchWindowController: NSObject {
      public static let shared = NotchWindowController()
      public func start(with model: PingDeckViewModel)
      public func stop()
      public func updateLayout()
  }
  ```

- [ ] **Step 1: 实现 `NotchWindowController.swift`**

实现 `NSPanel` 创建、透明浮动层级设置、150ms 悬停移入防误触、300ms 移出收起及屏幕变化监听。

- [ ] **Step 2: 编译与测试验证**

运行: `swift build && swift test`
预期: PASS

- [ ] **Step 3: 提交更改**

```bash
git add Sources/PingDeck/NotchWindowController.swift
git commit -m "feat(ui): 实现灵动岛无边框浮窗控制器与悬停防误触状态机

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 5: 灵动岛 SwiftUI 展开视图 (`NotchIslandView`)

**Files:**
- Create: `Sources/PingDeck/NotchIslandView.swift`

**Interfaces:**
- Produces:
  ```swift
  public struct NotchIslandView: View {
      @ObservedObject var model: PingDeckViewModel
      @Binding var isExpanded: Bool
      @Binding var isPinned: Bool
  }
  ```

- [ ] **Step 1: 实现 `NotchIslandView.swift`**

编写三大模块：
1. 核心指标（在线率、平均延迟、状态药丸）；
2. 异常速览（前 3 个异常节点，支持点击跳转主窗口）；
3. 快捷控制（打开主窗口、启动/暂停探测、偏好设置）；
4. 右上角图钉固定按钮。

- [ ] **Step 2: 编译与测试验证**

运行: `swift build && swift test`
预期: PASS

- [ ] **Step 3: 提交更改**

```bash
git add Sources/PingDeck/NotchIslandView.swift
git commit -m "feat(ui): 实现灵动岛黑晶流线展开卡片与模块化布局

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 6: 设置界面扩展灵动岛模块配置 (`SettingsSheet`)

**Files:**
- Modify: `Sources/PingDeck/SettingsSheet.swift`
- Test: `Tests/PingDeckTests/ConfigStoreInjectionTests.swift`

- [ ] **Step 1: 编写测试**

验证 `model.settings.notchIsland` 变更能被持久化保存。

- [ ] **Step 2: 在 `SettingsSheet.swift` 中添加灵动岛配置区块**

增加总开关及三个模块的 Toggle 选项。

- [ ] **Step 3: 运行测试验证通过**

运行: `swift test --filter ConfigStoreInjectionTests`
预期: PASS

- [ ] **Step 4: 提交更改**

```bash
git add Sources/PingDeck/SettingsSheet.swift Tests/PingDeckTests/ConfigStoreInjectionTests.swift
git commit -m "feat(settings): 在偏好设置中增加灵动岛总开关与模块自定义配置

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 7: 应用入口集成与端到端构建验证

**Files:**
- Modify: `Sources/PingDeck/PingDeckApp.swift`

- [ ] **Step 1: 在 `PingDeckApp.swift` 中挂载 `NotchWindowController`**

在 `applicationDidFinishLaunching` 中启动控制器，当设置变化时更新显示状态。

- [ ] **Step 2: 运行全量单元测试**

运行: `swift test`
预期: 100% 通过（0 失败）。

- [ ] **Step 3: 完整打包 Release**

运行: `make app`
预期: 成功产出 `dist/PingDeck.app`。

- [ ] **Step 4: 提交更改**

```bash
git add Sources/PingDeck/PingDeckApp.swift
git commit -m "feat(lifecycle): 将灵动岛控制器挂载至应用生命周期并联动设置

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```
