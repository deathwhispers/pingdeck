# 目标分组与颜色标签过滤设计规范 (Design Spec)

- **分支**: `feat/target-groups-and-tags`
- **日期**: 2026-11-13
- **状态**: 已确认 (Approved)

## 1. 背景与目标

随着用户监控的探测目标增加（如几十上百台设备分布在不同机房、VPC、支付网关、数据库备库等业务场景），当前的扁平单列表无法有效组织与过滤节点。
本特性的目标：
1. **多维分类**：为每个探测目标赋予独立的「分组名」（如“华东1机房”、“海外CDN”）与「颜色标签」（红/橙/黄/绿/蓝/紫/灰）；
2. **分组折叠视图**：主表格支持「按组分段折叠」与「经典平铺」无缝切换，分段组头显示该组的节点健康度卡片；
3. **彩色过滤条**：主窗口搜索区提供彩色圆点过滤胶囊，点击单色秒级高亮/筛选目标；
4. **编辑与批量导入导出**：单机编辑、批量导入（支持全局打标与扩展格式解析）与导出（CSV/XLSX/JSON/Markdown）全链路保留分组与颜色信息。

## 2. 总体交互与视觉设计

```
┌────────────────────────────────────────────────────────────────────────┐
│ 工具栏与过滤器                                                           │
│ [搜索框: 关键字...]  [● 全部 45] [🔴 3] [🟡 5] [🔵 12] ... [视图: ⊞平铺 / ☷分组] │
├────────────────────────────────────────────────────────────────────────┤
│ 表格区域 (分组折叠模式)                                                  │
│                                                                        │
│ ▼ 华东机房生产网关 (在线 12 / 离线 1)                     [展开全部/折叠全部] │
│ ┌───┬──────────────┬──────────────┬────────┬────────┬───────┬────────┐ │
│ │ 标│ 目标         │ 备注         │ 状态   │ 延迟   │ 丢包  │ 操作   │ │
│ ├───┼──────────────┼──────────────┼────────┼────────┼───────┼────────┤ │
│ │ 🔴│ 192.168.1.1  │ 核心交换机   │ 超时   │ -      │ 100%  │ ...    │ │
│ │ 🔵│ 192.168.1.10 │ 应用服务器 A │ 正常   │ 1.2ms  │ 0%    │ ...    │ │
│ └───┴──────────────┴──────────────┴────────┴────────┴───────┴────────┘ │
│                                                                        │
│ ▶ 海外 VPC 香港节点 (在线 20 / 离线 0) - [已折叠]                        │
│                                                                        │
│ ▼ 默认分组 (未分类) (在线 12 / 离线 0)                                   │
│ ...                                                                    │
└────────────────────────────────────────────────────────────────────────┘
```

## 3. 详细设计

### 3.1 数据模型扩展 (`PingCore/Models.swift`)

#### A. 预设调色板枚举
```swift
public enum TargetColorTag: String, Codable, CaseIterable, Hashable, Sendable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case gray
}
```

#### B. `PingTarget` 模型
```swift
public struct PingTarget: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var host: String
    public var note: String
    public var enabled: Bool
    public var group: String             // 分组名，空字符串代表“默认未分组”
    public var colorTag: TargetColorTag? // 颜色标签，nil 代表无标签

    public init(
        id: UUID = UUID(),
        host: String,
        note: String = "",
        enabled: Bool = true,
        group: String = "",
        colorTag: TargetColorTag? = nil
    ) {
        self.id = id
        self.host = host
        self.note = note
        self.enabled = enabled
        self.group = group
        self.colorTag = colorTag
    }
}
```

#### C. 向前兼容解码 (Backward Compatibility)
在 `PingTarget.init(from decoder: Decoder)` 中：
```swift
group = (try? container.decodeIfPresent(String.self, forKey: .group)) ?? ""
colorTag = try? container.decodeIfPresent(TargetColorTag.self, forKey: .colorTag)
```
确保旧版本（0.0.8 及之前）保存的 `config.json` 或导出的历史文件在加载时不会因缺少字段报错，原有配置平滑升级。

### 3.2 视图模型数据流 (`PingDeck/PingDeckViewModel.swift`)

#### A. 过滤与视图模式状态
- `@Published var selectedColorFilter: TargetColorTag? = nil`: 当前选中的颜色过滤器（nil 代表全部）。
- `@Published var isGroupedView: Bool = false`: 是否开启按组折叠分段显示模式。
- `@Published var collapsedGroups: Set<String> = []`: 当前折叠的分组集合。

#### B. 分组与统计计算属性
- `var availableGroups: [String]`: 当前所有目标中已存在的不重复非空分组列表（按字典序排）。
- `var colorTagCounts: [TargetColorTag: Int]`: 统计各颜色标签的目标数量，供工具栏胶囊展示。
- `var filteredRows: [PingTableRow]`: 结合 `searchText` 与 `selectedColorFilter` 的过滤结果。
- `var groupedSections: [TargetGroupSection]`:
  ```swift
  struct TargetGroupSection: Identifiable {
      var id: String { groupName }
      var groupName: String // 空字符串渲染为 L10n.groupDefault
      var rows: [PingTableRow]
      var aliveCount: Int
      var problemCount: Int
      var totalCount: Int
      var isCollapsed: Bool
  }
  ```

### 3.3 界面与交互设计

#### A. 工具栏彩色过滤胶囊 (`ColorFilterBar.swift`)
位于搜索栏右侧或上方：
- `全部 (总数)` 胶囊。
- 各个存在节点的颜色点胶囊（带颜色圆点和节点数，如 `● 3`）。
- 点击单色即切换筛选，再次点击或点击“全部”取消筛选。
- 视图切换按钮：提供平铺图标（`rectangle.grid.1x2`）与分组图标（`square.stack.3d.up`）切换 `isGroupedView`。

#### B. 主表格视图扩展 (`TargetsTableView.swift` & `GroupedTargetsTableView.swift`)
- **平铺模式**：经典 `Table` 增加「标签」颜色指示列与「分组」列。
- **分组折叠模式**：
  - 各组作为独立卡片渲染，组头包含展开/收起箭头、分组名称、在线/离线健康状态药丸、组内快捷全选操作；
  - 组内复用统一的列规范渲染表格内容；
  - 提供全局「全部折叠 / 全部展开」快捷按钮。

#### C. 目标添加与编辑弹窗 (`TargetEditorSheet.swift`)
- 增加「分组」输入框，支持直接输入新分组名或通过下拉菜单选择已有分组；
- 增加「颜色标签」色盘选择器（无颜色 + 7 种系统预设色圆点）。

#### D. 批量导入弹窗 (`BulkImportSheet.swift`)
- 导入界面增加「统一设置分组（可选）」与「统一设置颜色标签（可选）」；
- 扩展批量导入解析器（`BulkImportParser`），支持兼容格式：
  `host,note,group,color` 或带有分组前缀的行解析。

### 3.4 导出模块全格式兼容 (`PingCore/Export/*`)

更新所有导出器以包含分组与标签：
1. **CSV 导出** (`CsvExporter.swift`): 增加 `Group` 和 `ColorTag` 列；
2. **Excel 导出** (`XlsxExporter.swift`): 增加分组与标签列；
3. **JSON 导出** (`JsonExporter.swift`): `group` 与 `colorTag` 字段；
4. **Markdown 导出** (`MarkdownExporter.swift`): Markdown 表格追加分组列；
5. **文本导出** (`TextExporter.swift`): 文本行增加分组标识。

### 3.5 国际化支持 (`Localizable.xcstrings` & `L10n`)

支持中英日三种语言：
- 颜色名称：红色、橙色、黄色、绿色、蓝色、紫色、灰色。
- 分组文案：默认分组（未分类）、分组、按组显示、平铺显示、全部折叠、全部展开、新建分组等。

## 4. 验证与测试策略

1. **配置兼容性测试** (`ConfigSerializationTests.swift`):
   - 验证缺少 `group` 和 `colorTag` 的旧 JSON 解码为默认值；
   - 验证带分组和颜色的模型往返序列化。
2. **ViewModel 过滤与分组测试** (`ViewModelTests.swift`):
   - 验证颜色标签筛选过滤逻辑；
   - 验证分组提取、统计与折叠状态切换。
3. **导出测试** (`ExportTests.swift`):
   - 验证 CSV/XLSX/JSON/Markdown 导出包含分组和颜色列。
4. **批量导入解析测试** (`BulkImportTests.swift`):
   - 验证支持统一打标与行内扩展字段解析。
