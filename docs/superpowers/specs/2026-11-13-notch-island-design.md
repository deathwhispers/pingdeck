# 刘海灵动岛扩展设计规范 (Design Spec)

- **分支**: `feat/notch-island`
- **日期**: 2026-11-13
- **状态**: 已确认 (Approved)

## 1. 背景与目标

PingDeck 已拥有独立主窗口与菜单栏状态项，但在多任务高频巡检或全屏工作流中，用户需要一种既**零视觉打扰**（平时完全隐形）、又能在需要时**一秒主动呼出**网络全貌的现代交互方式。

本特性的设计目标：
1. **纯主动触发、绝不被动打扰**：平时 100% 贴合刘海隐形，不弹扰民告警；鼠标移入刘海区域时顺滑展开，移出自动收缩；
2. **硬件刘海与外显自适应**：
   - 具备物理刘海的 MacBook：精确定位刘海坐标，面板从硬件刘海底部无缝向下顺滑延展；
   - 无物理刘海或外接显示器：在主屏幕正上方居中自适应模拟优雅小黑胶囊；
3. **模块化与高度可定制**：三大模块（核心指标、异常速览、快捷控制）均支持在偏好设置中自由开启/关闭；
4. **图钉固定 (Pin)**：面板右上角提供图钉按钮，点击可锁定常驻面板，方便持续观测。

## 2. 总体交互与视觉呈现

```
                       ┌──────────────────┐
                       │   MacBook 刘海   │ (平时 100% 隐形)
                       └─────────┬────────┘
                                 │ 鼠标滑入 (150ms 防误触)
                                 ▼
 ┌───────────────────────────────────────────────────────────────┐
 │ 灵动岛展开面板 (NotchIslandView - 弹性水滴弹簧动画)    [📌 固定] │
 ├───────────────────────────────────────────────────────────────┤
 │ [模块 1: 核心健康指标]                                        │
 │  在线率: 94.2%                   平均延迟: 18.5 ms            │
 │  🟢 在线: 47        🔴 异常: 3        ⚪ 排队: 0              │
 ├───────────────────────────────────────────────────────────────┤
 │ [模块 2: 异常节点速览] (可设置开启/关闭)                       │
 │  • 192.168.1.1 (核心网关) - 超时                              │
 │  • db-slave.internal (数据库备库) - 不可达                    │
 │  [在主窗口查看全部 (3)]                                       │
 ├───────────────────────────────────────────────────────────────┤
 │ [模块 3: 快捷操作栏] (可设置开启/关闭)                         │
 │  ⊞ 打开主窗口        ⏵ 暂停探测        ⚙ 设置                 │
 └───────────────────────────────────────────────────────────────┘
```

## 3. 详细设计

### 3.1 配置模型扩展 (`PingCore/Models.swift`)

在 `PingSettings` 中新增 `NotchIslandSettings`，默认启用且各模块全开，保证向下兼容：

```swift
/// 灵动岛偏好配置
public struct NotchIslandSettings: Codable, Equatable, Sendable {
    /// 是否启用刘海灵动岛功能
    public var enabled: Bool
    /// 是否展示核心健康指标模块
    public var showMetrics: Bool
    /// 是否展示最近异常节点列表模块
    public var showRecentProblems: Bool
    /// 是否展示快捷控制按钮栏模块
    public var showQuickControls: Bool

    public init(
        enabled: Bool = true,
        showMetrics: Bool = true,
        showRecentProblems: Bool = true,
        showQuickControls: Bool = true
    ) {
        self.enabled = enabled
        self.showMetrics = showMetrics
        self.showRecentProblems = showRecentProblems
        self.showQuickControls = showQuickControls
    }
}
```

在 `PingSettings` 中增加：
```swift
public var notchIsland: NotchIslandSettings = NotchIslandSettings()
```
手写解码器中使用 `decodeIfPresent`，旧版配置未含此字段时安全回退默认值。

### 3.2 窗口与硬件几何计算架构 (`NotchWindowController.swift`)

灵动岛通过专有的轻量无边框置顶 `NSPanel` 承载：
- **面板属性**：
  - `styleMask: [.borderless, .nonactivatingPanel]`
  - `level = .floating`（或 `.mainMenu + 1`，保证在全屏应用和系统菜单栏上方平滑弹出）
  - `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]`
  - `isOpaque = false`，`backgroundColor = .clear`，`hasShadow = false`
- **屏幕与物理刘海检测**：
  - 检查当前屏幕 `screen.safeAreaInsets.top > 0`；
  - 物理刘海宽度计算：通过 `screen.frame.width - (screen.auxiliaryTopLeftArea?.width ?? 0) - (screen.auxiliaryTopRightArea?.width ?? 0)`，或者根据典型 MacBook 刘海宽度（约 160-180pt）与高度（约 32-34pt）进行基准校准；
  - 无物理刘海屏幕：在主屏幕顶部中央定位（宽 160pt，高 32pt 居中胶囊）。
- **坐标同步与多屏插拔适配**：
  - 监听 `NSApplication.didChangeScreenParametersNotification`，当用户插拔外接显示器、合盖或调整分辨率时自动重置位置与尺寸。

### 3.3 交互状态机与防误触机制 (`NotchIslandCoordinator`)

1. **静息隐形态 (`idle`)**：
   - 窗口收缩为一个位于刘海区域的高度仅刘海高度（约 32pt）的感应区域，完全透明。
2. **移入感应 (`hoverIn`)**：
   - 鼠标划入感应区，触发 150ms 延时计时器；
   - 若 150ms 内鼠标仍停留在感应区，说明用户是有意识想要查看灵动岛（而非快速划向菜单栏菜单项），触发状态进入 `expanded`；
   - 窗口高度动态调整为展开高度，SwiftUI 视图播放顺滑的弹性水滴展开动画（`spring(response: 0.35, dampingFraction: 0.78)`）。
3. **移出收起 (`hoverOut`)**：
   - 鼠标离开面板后，触发 300ms 延时计时器；若未处于固定状态（`isPinned == false`），则弹性回弹收缩并隐藏。
4. **图钉固定 (`pinned`)**：
   - 点击面板右上角图钉按钮，切换 `isPinned`。固定状态下，鼠标移开面板不会收缩，直到用户再次点击取消固定或主动关闭。

### 3.4 视图组件设计 (`NotchIslandView.swift`)

- **外观**：纯正 Apple 原生深黑毛玻璃风格（`Color.black.opacity(0.85)` + 微弱高光描边），顶部弧度与物理刘海紧密咬合；
- **模块 1（健康指标）**：
  - 左侧大字号在线率百分比，右侧大字号平均在线延迟；
  - 状态胶囊药丸：🟢 在线 / 🔴 异常 / ⚪ 排队。
- **模块 2（异常节点速览）**：
  - 若无异常：显示「🎉 所有监控目标均正常」；
  - 若有异常：列出前 3 个异常节点（主机名、备注、错误原因），点击唤出主窗口并定位。
- **模块 3（快捷控制栏）**：
  - 「打开主窗口」、「开始/暂停探测」、「偏好设置」。
- **图钉按钮**：
  - 右上角极简图标，固定时高亮显示。

### 3.5 偏好设置集成 (`SettingsSheet.swift`)

在设置面板新增「刘海灵动岛 (Notch Island)」配置区：
- 总开关：启用灵动岛扩展（开启/关闭）；
- 模块选项（在总开关开启时可用）：
  - 勾选「显示核心指标」
  - 勾选「显示异常节点速览」
  - 勾选「显示快捷控制栏」

### 3.6 国际化与文案 (`Localizable.xcstrings` & `L10n`)

支持中英日三语：
- 偏好设置中的灵动岛模块标题与说明；
- 图钉固定与取消固定悬停提示；
- 展开面板中的文案提示。

## 4. 验证与测试策略

1. **配置序列化测试** (`ConfigSerializationTests.swift`):
   - 测试缺少 `notchIsland` 键的历史 JSON 配置反序列化；
   - 测试所有开关状态的持久化与还原。
2. **硬件几何与安全计算单元测试**:
   - 验证无刘海与有刘海屏幕下的尺寸计算与回退机制。
3. **自动化构建与端到端运行验证**:
   - `swift test` 保证全套测试通过；
   - `make app` 打包并在真机上进行悬停滑入/滑出展开与图钉固定交互测试。
