# 菜单栏状态概览面板与后台常驻设计规范

- **分支**: `feat/menubar-status`
- **日期**: 2026-11-13
- **状态**: 已确认 (Approved)

## 1. 背景与目标

PingDeck 作为一款 macOS 网络连通性监控工具，此前只能通过主应用窗口查看目标节点的探测状态。用户在工作时，需要一个轻量、无侵入的常驻入口，以便在不打扰当前工作流、无需激活或保持主窗口开启的情况下：
1. 一眼查看所有监控节点的实时健康度（在线数与离线异常数）。
2. 点击菜单栏快速弹出概览面板，掌握当前离线节点明细并进行常用控制（打开主窗口、启动/暂停探测、偏好设置、退出应用）。
3. 自由选择主窗口关闭后的行为（在菜单栏后台常驻继续探测或退出应用），并在首次关闭窗口时向用户引导选择。

## 2. 总体架构与交互流程

```
┌────────────────────────────────────────────────────────┐
│ macOS 系统顶部菜单栏                                     │
│ [网络图标] 在线 42  离线 3                               │
└───────────────────────┬────────────────────────────────┘
                        │ 点击展开
                        ▼
┌────────────────────────────────────────────────────────┐
│ 菜单栏下拉面板 (MenuBarPanelView - 320pt 浮窗)          │
├────────────────────────────────────────────────────────┤
│ [概览卡片]                                             │
│  总体在线率: 93%          平均延迟: 18ms                │
│  🟢 在线: 42     🔴 离线/异常: 3     ⚪ 排队: 0        │
├────────────────────────────────────────────────────────┤
│ [异常节点明细] (最多 5 条，按严重度排序)                │
│  • 192.168.1.1 (网关) - 超时                           │
│  • api.service.internal (生产接口) - 不可达             │
│  • db.internal (备库) - 进程退出                       │
│  [在主窗口查看全部 (3)]                                │
├────────────────────────────────────────────────────────┤
│ [快捷操作与生命周期]                                    │
│  ⏵ 暂停探测 / 继续探测                                  │
│  ⊞ 打开主窗口                                          │
│  ⚙ 偏好设置...                                         │
│  ──────────────────────────────────────────           │
│  ⏻ 退出 PingDeck                                       │
└────────────────────────────────────────────────────────┘
```

## 3. 详细设计

### 3.1 数据模型扩展 (`PingCore/Models.swift`)

在 `PingCore` 中为 `AppSettings` 扩展菜单栏偏好与生命周期控制，确保完全向下兼容：

```swift
/// 主窗口关闭时的处理行为
public enum WindowCloseBehavior: String, Codable, Sendable {
    case ask              // 首次未决定，关闭时弹窗询问
    case keepRunning      // 保持后台常驻继续探测
    case terminate        // 直接退出应用
}

/// 菜单栏与生命周期配置
public struct MenuBarSettings: Codable, Equatable, Sendable {
    /// 是否在菜单栏显示文字标签（在线/离线计数），关闭时仅显示图标
    public var showTextLabel: Bool
    /// 主窗口关闭时的行为
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

在 `AppSettings` 中新增：
```swift
public var menuBar: MenuBarSettings = MenuBarSettings()
```
当解码早期配置文件（缺少 `menuBar` 键）时，利用自定义或自动补齐的解码默认值赋为 `MenuBarSettings()`，确保向前兼容、不破坏现有配置。

### 3.2 视图模型状态暴露 (`PingDeck/PingDeckViewModel.swift`)

在 `PingDeckViewModel` 中提供专门针对菜单栏的计算属性与辅助方法：
1. `var aliveCount: Int`: 在线节点数（已存在）。
2. `var problemCount: Int`: 异常节点数（包含 `timeout`, `unreachable`, `error`）。
3. `var queuedTargetCount: Int`: 排队中节点数（已存在）。
4. `var averageAliveLatency: Double?`: 当前所有处于 `alive` 状态节点的平均 `rttAvg`（或最近 RTT）。
5. `var recentProblemRows: [PingTableRow]`: 筛选出的异常节点列表，最多截取前 5 项，供菜单栏面板快捷展示。
6. `var menuBarTitle: String`: 状态栏标题文本，支持多语言本地化格式（`在线 %lld  离线 %lld` 等）。

### 3.3 界面实现

#### A. 菜单栏场景 (`PingDeck/PingDeckApp.swift`)
使用 SwiftUI 原生 `MenuBarExtra`：
```swift
MenuBarExtra {
    MenuBarPanelView(model: model)
} label: {
    MenuBarLabelView(model: model)
}
.menuBarExtraStyle(.window)
```

#### B. 状态栏标签视图 (`PingDeck/Views/MenuBarLabelView.swift`)
- 图标：若 `problemCount > 0`，显示告警状态网络图标或色彩（`network.slash` 或带警示状态的 SF Symbol）；若全正常，显示标准绿色/默认状态网络图标。
- 文本：若 `model.settings.menuBar.showTextLabel` 为 `true`，显示多语言格式化的 `model.menuBarTitle`；若为 `false`，则不显示文本，仅保留图标。

#### C. 下拉面板视图 (`PingDeck/Views/MenuBarPanelView.swift`)
- 宽度统一为 320pt，带有卡片分组样式和系统自适应背景。
- **健康度概览**：在线总数、异常总数、平均延迟。
- **异常列表**：无异常时展示健康提示图文；有异常时展示节点列表，点击任意节点或点击「在主窗口查看全部」唤醒并前置主窗口。
- **控制按钮**：
  - 打开主窗口（`openWindow(id: "main")` 配合 `NSApp.activate(ignoringOtherApps: true)`）。
  - 开始/暂停探测（调用 `model.toggleEngine()`）。
  - 打开设置（呼出主窗口并打开 `SettingsSheet`，或直接展示独立设置）。
  - 退出 PingDeck（`NSApp.terminate(nil)`）。

### 3.4 窗口关闭拦截与首次引导 (`WindowCloseInterceptor` / `AppDelegate`)

1. **主窗口拦截**：
   - 在主窗口关联 `NSWindowDelegate` 监听 `windowShouldClose(_:)`。
   - 若 `settings.menuBar.closeBehavior == .ask`：
     - 弹出 `NSAlert` 询问用户：「关闭主窗口时，希望在菜单栏后台保持探测，还是直接退出应用？」。
     - 提供单选/复选框「记住我的选择（可在设置中随时更改）」。
     - 按钮 1（默认）：保持后台运行（将偏好设为 `.keepRunning` 并保存）。
     - 按钮 2：退出应用（将偏好设为 `.terminate` 并保存）。
     - 若用户未勾选记住，则保持 `.ask`，仅执行本次动作。
     - 若选择后台运行：主窗口调用 `window.orderOut(nil)` 隐藏，返回 `false`（阻止窗口真正销毁并退出应用）。
     - 若选择退出应用：调用 `NSApp.terminate(nil)`。
   - 若 `settings.menuBar.closeBehavior == .keepRunning`：
     - 直接 `window.orderOut(nil)` 并返回 `false`。
   - 若 `settings.menuBar.closeBehavior == .terminate`：
     - 调用 `NSApp.terminate(nil)`。

2. **重新唤醒主窗口**：
   - 监听 `applicationShouldHandleReopen(_:hasVisibleWindows:)`：当用户点击 Dock 图标时，若主窗口当前处于隐藏状态，自动调用 `makeKeyAndOrderFront` 重新展示主窗口。

### 3.5 设置面板扩展 (`PingDeck/SettingsSheet.swift`)

在设置窗口中新增「菜单栏与后台」设置区块：
- **菜单栏文本标签**：开关切换 `showTextLabel`。
- **关闭主窗口时**：Picker 选项：
  - 在菜单栏保持后台运行 (`keepRunning`)
  - 退出应用 (`terminate`)
  - 每次询问 (`ask`)

### 3.6 国际化 (`Localizable.xcstrings` & `L10n`)
为所有新增文本提供三种语言支持（中文简体 `zh-Hans`、英语 `en`、日语 `ja`）：
1. 菜单栏状态格式化：`在线 %lld  离线 %lld` / `%lld Up  %lld Down` / `オンライン %lld  オフライン %lld`
2. 窗口关闭提示弹窗的标题、描述、按钮文本。
3. 概览面板中健康率、异常列表、操作按钮文本。
4. 设置面板中的对应选项文案。

## 4. 验证与测试策略

1. **配置兼容性单元测试** (`Tests/PingCoreTests/ConfigSerializationTests.swift`):
   - 测试包含/不包含 `menuBar` 字段的 JSON 反序列化。
   - 测试所有 `WindowCloseBehavior` 枚举值的往返编解码。
2. **ViewModel 单元测试** (`Tests/PingDeckTests/ViewModelTests.swift`):
   - 验证各种健康状态下的统计指标（全在线、部分离线、全部离线、排队）。
   - 验证异常节点提取的过滤与排序截断逻辑。
   - 验证菜单栏格式化文本输出。
3. **构建与功能验证**:
   - 运行 `swift test` 保证全部单元测试通过。
   - 运行 `swift build` 验证构建通过。
