# 目标分组与颜色标签过滤实施计划 (Implementation Plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 PingDeck 实现目标按项目/机房/用途分组管理，主表格支持分段折叠与平铺双视图切换，顶部工具栏提供快捷彩色圆点标签过滤，以及编辑、批量导入和全格式导出保留分组与标签。

**Architecture:**
- 在 `PingCore/Models.swift` 中定义 `TargetColorTag` 枚举并扩展 `PingTarget` 模型（`group` 与 `colorTag`），手写 `init(from:)` 确保向前兼容历史配置解码；
- 在 `PingCore/Export/*` 与 `BulkImport` 中适配分组与标签字段，确保导入与导出的完整性；
- 在 `PingDeckViewModel` 中维护颜色过滤状态、视图模式（平铺/分组）与折叠状态，计算并分发分组数据与颜色统计；
- 在 `PingDeck` 界面层新增 `ColorFilterBar`，升级 `TargetsTableView` 与 `GroupedTargetsTableView`，并在 `TargetEditorSheet` 与 `BulkImportSheet` 中集成标签选择；
- 扩展 `Localizable.xcstrings` 覆盖中英日三语标签与分组文案。

**Tech Stack:** Swift 5.9, macOS 14.4+ SDK, SwiftUI (Table, DisclosureGroup / Card Sections), XCTest.

**Spec:** `docs/superpowers/specs/2026-11-13-target-groups-and-tags-design.md`

## Global Constraints

- 严禁忽略需求或杜撰逻辑，严禁临时硬编码，严禁遗留 TODO。
- 一个 PR 只做一件事，所有改动在分支 `feat/target-groups-and-tags` 上进行。
- 保证配置兼容性：解码旧版本缺少 `group` 与 `colorTag` 字段的 JSON 配置时必须平滑回落，不得破坏现有用户配置。
- 所有用户可见文案均需在 `Localizable.xcstrings` 中配置简体中文 (`zh-Hans`)、英语 (`en`)、日语 (`ja`) 三种语言，并通过 `scripts/generate-localization-symbols.sh` 自动生成。
- 每个任务完成时必须通过 `swift build` 与 `swift test`。

---

### Task 1: 核心数据模型扩展与向前兼容序列化 (`TargetColorTag` & `PingTarget`)

**Files:**
- Modify: `Sources/PingCore/Models.swift`
- Test: `Tests/PingCoreTests/ConfigSerializationTests.swift`

**Interfaces:**
- Produces:
  ```swift
  public enum TargetColorTag: String, Codable, CaseIterable, Hashable, Sendable {
      case red, orange, yellow, green, blue, purple, gray
  }

  public struct PingTarget: Identifiable, Codable, Hashable, Sendable {
      public var id: UUID
      public var host: String
      public var note: String
      public var enabled: Bool
      public var group: String
      public var colorTag: TargetColorTag?

      public init(id: UUID = UUID(), host: String, note: String = "", enabled: Bool = true, group: String = "", colorTag: TargetColorTag? = nil)
  }
  ```

- [ ] **Step 1: 编写失败的单元测试**

在 `Tests/PingCoreTests/ConfigSerializationTests.swift` 中添加：
```swift
func testTargetWithGroupAndColorTagRoundTrip() throws {
    let target = PingTarget(
        host: "10.0.0.1",
        note: "Gateway",
        enabled: true,
        group: "IDC-A",
        colorTag: .blue
    )
    let data = try JSONEncoder().encode(target)
    let decoded = try JSONDecoder().decode(PingTarget.self, from: data)
    XCTAssertEqual(decoded.host, "10.0.0.1")
    XCTAssertEqual(decoded.group, "IDC-A")
    XCTAssertEqual(decoded.colorTag, .blue)
}

func testTargetDecodesLegacyJSONWithoutGroupAndColor() throws {
    let legacyJSON = """
    {
      "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
      "host": "1.1.1.1",
      "note": "DNS",
      "enabled": true
    }
    """.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(PingTarget.self, from: legacyJSON)
    XCTAssertEqual(decoded.host, "1.1.1.1")
    XCTAssertEqual(decoded.group, "")
    XCTAssertNil(decoded.colorTag)
}
```

- [ ] **Step 2: 运行测试验证失败**

运行: `swift test --filter ConfigSerializationTests`
预期: 编译失败，`TargetColorTag` 与 `group` 未定义。

- [ ] **Step 3: 实现模型与向前兼容解码**

在 `Sources/PingCore/Models.swift` 中：
- 定义 `TargetColorTag` 枚举；
- 为 `PingTarget` 增加 `group` 与 `colorTag` 字段，并在全参构造器中赋予默认值 `group: String = ""`、`colorTag: TargetColorTag? = nil`；
- 实现 `init(from decoder: Decoder)`，当缺少字段时使用空字符串与 nil 回退；
- 实现 `encode(to encoder: Encoder)` 正常写入所有字段。

- [ ] **Step 4: 运行测试验证通过**

运行: `swift test --filter ConfigSerializationTests`
预期: PASS

- [ ] **Step 5: 提交更改**

```bash
git add Sources/PingCore/Models.swift Tests/PingCoreTests/ConfigSerializationTests.swift
git commit -m "feat(core): 支持目标分组与颜色标签数据模型及历史向前兼容解码

Co-Authored-By: Claude Haiku 5.5 <noreply@Google.com>"
```

---

### Task 2: 国际化多语言文案扩展与代码生成 (`Localizable.xcstrings` & `L10n`)

**Files:**
- Modify: `Sources/PingDeck/Resources/Localizable.xcstrings`
- Modify: `Sources/PingDeck/Generated/L10n.swift` (由脚本自动更新)
- Test: `Tests/PingDeckTests/LocalizationCatalogTests.swift`

**Interfaces:**
- Produces:
  - `L10n.groupColumnTitle: LocalizedStringResource` ("分组" / "Group" / "グループ")
  - `L10n.colorTagColumnTitle: LocalizedStringResource` ("标签" / "Tag" / "タグ")
  - `L10n.groupDefaultName: LocalizedStringResource` ("默认分组" / "Default Group" / "デフォルトグループ")
  - `L10n.filterAllTags: LocalizedStringResource` ("全部" / "All" / "すべて")
  - `L10n.viewModeFlat: LocalizedStringResource` ("平铺视图" / "Flat View" / "フラット表示")
  - `L10n.viewModeGrouped: LocalizedStringResource` ("分组视图" / "Grouped View" / "グループ表示")
  - `L10n.collapseAllGroups: LocalizedStringResource` ("全部折叠" / "Collapse All" / "すべて折りたたむ")
  - `L10n.expandAllGroups: LocalizedStringResource` ("全部展开" / "Expand All" / "すべて展開")
  - `L10n.targetEditorGroup: LocalizedStringResource` ("所属分组" / "Group" / "所属グループ")
  - `L10n.targetEditorGroupPlaceholder: LocalizedStringResource` ("输入或选择分组" / "Enter or select group" / "グループを入力または選択")
  - `L10n.targetEditorColorTag: LocalizedStringResource` ("颜色标签" / "Color Tag" / "カラータグ")
  - `L10n.targetEditorNoColorTag: LocalizedStringResource` ("无标签" / "None" / "なし")
  - `L10n.bulkImportGroup: LocalizedStringResource` ("统一分配分组" / "Assign Group" / "グループを一括割り当て")
  - `L10n.bulkImportColorTag: LocalizedStringResource` ("统一分配颜色" / "Assign Color Tag" / "カラータグを一括割り当て")
  - 7 种颜色显示名：`colorRed`, `colorOrange`, `colorYellow`, `colorGreen`, `colorBlue`, `colorPurple`, `colorGray`.

- [ ] **Step 1: 编辑 `Localizable.xcstrings` 填入多语言词条**

添加上述所有键，并完整提供 `zh-Hans`、`en`、`ja` 三种语言的本地化译文。

- [ ] **Step 2: 执行代码生成脚本**

运行: `bash scripts/generate-localization-symbols.sh`
预期: 成功更新 `Sources/PingDeck/Generated/L10n.swift`。

- [ ] **Step 3: 运行本地化检查测试**

运行: `swift test --filter Localization`
预期: PASS

- [ ] **Step 4: 提交更改**

```bash
git add Sources/PingDeck/Resources/Localizable.xcstrings Sources/PingDeck/Generated/L10n.swift
git commit -m "feat(i18n): 增加目标分组、颜色标签与视图切换的多语言文案

Co-Authored-By: Claude Haiku 5.5 <noreply@Google.com>"
```

---

### Task 3: 导出模块适配分组与标签 (`Export/*`)

**Files:**
- Modify: `Sources/PingCore/Export/ExportTable.swift`
- Modify: `Sources/PingCore/Export/CsvExporter.swift`
- Modify: `Sources/PingCore/Export/XlsxExporter.swift`
- Modify: `Sources/PingCore/Export/JsonExporter.swift`
- Modify: `Sources/PingCore/Export/MarkdownExporter.swift`
- Modify: `Sources/PingCore/Export/TextExporter.swift`
- Test: `Tests/PingCoreTests/ExportTests.swift`

**Interfaces:**
- Updates `ExportRow`:
  - 增加 `group: String` 与 `colorTag: String`（或 `TargetColorTag?`）；
- 各 Exporter 增加对应表头列与数据输出。

- [ ] **Step 1: 编写失败的单元测试**

在 `Tests/PingCoreTests/ExportTests.swift` 中添加测试验证 CSV / JSON / Markdown 导出包含 `group` 与 `colorTag` 信息。

- [ ] **Step 2: 运行测试以确认失败**

运行: `swift test --filter ExportTests`
预期: 失败。

- [ ] **Step 3: 更新导出实现**

更新 `ExportTable.swift`、`CsvExporter.swift`、`JsonExporter.swift`、`MarkdownExporter.swift`、`TextExporter.swift`、`XlsxExporter.swift`。

- [ ] **Step 4: 运行测试验证通过**

运行: `swift test --filter ExportTests`
预期: PASS

- [ ] **Step 5: 提交更改**

```bash
git add Sources/PingCore/Export/ Tests/PingCoreTests/ExportTests.swift
git commit -m "feat(export): 导出 CSV、Excel、JSON、Markdown 时保留分组与颜色标签

Co-Authored-By: Claude Haiku 5.5 <noreply@Google.com>"
```

---

### Task 4: 批量导入解析器扩展 (`BulkImport`)

**Files:**
- Modify: `Sources/PingCore/BulkImport.swift`
- Test: `Tests/PingCoreTests/BulkImportTests.swift`

**Interfaces:**
- Produces:
  `BulkImportParser.parse(text:defaultGroup:defaultColorTag:)`
  支持统一分配默认分组与标签，同时支持 `host,note,group,color` 行级格式解析。

- [ ] **Step 1: 编写失败的单元测试**

在 `Tests/PingCoreTests/BulkImportTests.swift` 中添加：
- 测试带默认 group 和 colorTag 的批量解析；
- 测试 CSV 格式包含 4 列（host, note, group, color）的解析。

- [ ] **Step 2: 运行测试验证失败**

运行: `swift test --filter BulkImportTests`
预期: FAIL。

- [ ] **Step 3: 实现解析逻辑扩展**

在 `Sources/PingCore/BulkImport.swift` 中更新 `BulkImportParser`，提取第 3、4 列为 group 与 colorTag，或在未指定时使用传入的 defaultGroup / defaultColorTag。

- [ ] **Step 4: 运行测试验证通过**

运行: `swift test --filter BulkImportTests`
预期: PASS

- [ ] **Step 5: 提交更改**

```bash
git add Sources/PingCore/BulkImport.swift Tests/PingCoreTests/BulkImportTests.swift
git commit -m "feat(import): 批量导入支持行内分组标签解析与默认分组颜色分配

Co-Authored-By: Claude Haiku 5.5 <noreply@Google.com>"
```

---

### Task 5: ViewModel 过滤、统计与分组视图状态 (`PingDeckViewModel`)

**Files:**
- Modify: `Sources/PingDeck/PingDeckViewModel.swift`
- Test: `Tests/PingDeckTests/ViewModelTests.swift`

**Interfaces:**
- Produces in `PingDeckViewModel`:
  ```swift
  @Published public var selectedColorFilter: TargetColorTag? = nil
  @Published public var isGroupedView: Bool = false
  @Published public var collapsedGroups: Set<String> = []

  public var availableGroups: [String] { get }
  public var colorTagCounts: [TargetColorTag: Int] { get }
  public var filteredRows: [PingTableRow] { get }
  public var groupedSections: [TargetGroupSection] { get }

  public func toggleGroupCollapse(_ groupName: String)
  public func collapseAllGroups()
  public func expandAllGroups()
  public func addTarget(host: String, note: String, enabled: Bool, group: String, colorTag: TargetColorTag?)
  public func updateTarget(_ target: PingTarget)
  ```

- [ ] **Step 1: 编写失败的单元测试**

在 `Tests/PingDeckTests/ViewModelTests.swift` 中编写测试：
- 测试 `selectedColorFilter` 过滤不同颜色标签目标；
- 测试 `groupedSections` 正确分组与组内在线/异常统计；
- 测试折叠/展开分组逻辑。

- [ ] **Step 2: 运行测试确认失败**

运行: `swift test --filter ViewModelTests`
预期: FAIL。

- [ ] **Step 3: 实现 ViewModel 状态与计算属性**

在 `Sources/PingDeck/PingDeckViewModel.swift` 中实现过滤与分组流。

- [ ] **Step 4: 运行测试验证通过**

运行: `swift test --filter ViewModelTests`
预期: PASS

- [ ] **Step 5: 提交更改**

```bash
git add Sources/PingDeck/PingDeckViewModel.swift Tests/PingDeckTests/ViewModelTests.swift
git commit -m "feat(viewmodel): 实现颜色标签过滤、分组统计与折叠状态驱动

Co-Authored-By: Claude Haiku 5.5 <noreply@Google.com>"
```

---

### Task 6: 界面组件开发与整合 (ColorFilterBar, GroupedTable, Sheets)

**Files:**
- Create: `Sources/PingDeck/ColorFilterBar.swift`
- Create: `Sources/PingDeck/GroupedTargetsTableView.swift`
- Modify: `Sources/PingDeck/TargetsTableView.swift`
- Modify: `Sources/PingDeck/TargetEditorSheet.swift`
- Modify: `Sources/PingDeck/BulkImportSheet.swift`
- Modify: `Sources/PingDeck/ContentView.swift`

**Interfaces:**
- Produces:
  - `ColorFilterBar`: 工具栏彩色圆点胶囊栏与视图切换按钮；
  - `GroupedTargetsTableView`: 分段折叠卡片分组表格；
  - `TargetsTableView`: 新增标签圆点列与分组列；
  - `TargetEditorSheet`: 分组与颜色标签输入选择；
  - `BulkImportSheet`: 默认分组与颜色标签选择。

- [ ] **Step 1: 创建 `ColorFilterBar.swift`**

实现颜色圆点过滤胶囊栏，展示“全部 (N)”以及各色圆点 `🔴 N`、`🔵 N`，支持点击选中/取消，右侧放置平铺/分组视图切换开关。

- [ ] **Step 2: 创建 `GroupedTargetsTableView.swift` 并升级 `TargetsTableView.swift`**

实现分段卡片折叠视图，组头展示展开图标、分组名、在线/异常健康统计胶囊与快速折叠按钮；平铺表增加标签列与分组列。

- [ ] **Step 3: 升级 `TargetEditorSheet.swift` 与 `BulkImportSheet.swift`**

单机编辑弹窗增加分组选择/输入框与颜色调色板选择器；批量导入弹窗增加统一设置分组与颜色的控件。

- [ ] **Step 4: 在 `ContentView.swift` 中集成**

在搜索工具栏下方或右侧嵌入 `ColorFilterBar`，并在表格区域根据 `model.isGroupedView` 条件渲染 `GroupedTargetsTableView` 或 `TargetsTableView`。

- [ ] **Step 5: 运行 `swift build` 与 `swift test` 验证**

运行: `swift build && swift test`
预期: 成功编译，所有测试通过。

- [ ] **Step 6: 提交更改**

```bash
git add Sources/PingDeck/
git commit -m "feat(ui): 实现彩色圆点过滤栏、分组折叠表格与标签编辑选择器

Co-Authored-By: Claude Haiku 5.5 <noreply@Google.com>"
```

---

### Task 7: 完整构建与端到端验证

**Files:**
- All files

- [ ] **Step 1: 运行全量单元测试**

运行: `swift test`
预期: 100% 通过（0 失败）。

- [ ] **Step 2: 运行工程完整构建**

运行: `swift build`
预期: 0 错误、0 警告。

- [ ] **Step 3: 验证 Release 打包**

运行: `make app`
预期: 打包生成 `dist/PingDeck.app`。
