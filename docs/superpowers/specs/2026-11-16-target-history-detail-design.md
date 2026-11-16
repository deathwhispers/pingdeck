# 单目标探测历史明细设计

## 背景

当前表格只展示每个目标的聚合统计（成功/失败、平均/最小/最大延迟等）。排查间歇性丢包或延迟抖动时，用户需要看到该目标最近每一次探测的结果。PingInfoView 的做法是选中一行后在下方列出全部 ping 记录，本设计将这一能力引入 PingDeck。

## 目标

- 记录每个目标最近 200 次探测样本，仅在内存中保留。
- 选中单个目标时，在窗口底部提供可折叠、可拖动高度的明细面板。
- 明细面板同时展示目标属性摘要与逐条历史记录。
- 不改变现有统计口径、导出内容与目标配置格式。

## 非目标

- 不持久化历史样本，应用重启后清空。
- 不实现按目标单独配置探测参数（由后续 feat 分支负责）。
- 不改变保存/导出入口（由后续 feat 分支负责）。
- 不对历史样本做告警或通知。

## 数据模型

新增 `PingSample`（`Sources/PingCore/PingSample.swift`）：

```swift
public struct PingSample: Identifiable, Sendable, Equatable {
    public enum Outcome: String, Sendable, Equatable {
        case reply
        case timeout
        case unreachable
        case failure
    }

    public let id: UUID
    public let timestamp: Date
    public let seq: Int?
    public let outcome: Outcome
    public let latencyMs: Double?
    public let peerAddress: String?
    public let ttl: Int?
    public let message: String
}
```

- `id` 用于 SwiftUI 列表标识。
- `seq` 来自 `icmp_seq` / `icmp6_seq`，可能为空。
- `peerAddress`、`ttl` 仅成功回包含有值。
- `message` 保存不可达/错误的原始文本，成功与超时为 `""`。

## 解析器扩展

`PingEvent.reply` 增加 `peerAddress` 与 `ttl`：

```swift
case reply(seq: Int?, latencyMs: Double, peerAddress: String?, ttl: Int?)
```

- 从 `from <address>:` 提取对端地址，去掉末尾冒号。
- 同时识别 `ttl=` 与 IPv6 的 `hlim=`。
- `sequence(in:)` 同时识别 `icmp_seq` 与 `icmp6_seq`。
- 无法提取时返回 `nil`，不影响原有延迟解析。

## 引擎事件

`PingEngine` 新增回调：

```swift
public var onSample: ((UUID, PingSample) -> Void)?
```

- `reply`：记录成功样本，携带延迟、对端地址、TTL。
- `timeout`：记录超时样本，携带 seq。
- `unreachable`：记录不可达样本，携带原始文本。
- `failure`：记录错误样本，携带原始文本。
- 静默超时判定（`applyStaleTimeoutLocked`）在把状态改为 `.timeout` 时补记一条超时样本；由于状态随后不再是 `.alive` / `.running`，同一段故障不会每秒重复补记。
- 引擎只负责产生样本，不保存历史；历史由 ViewModel 持有。

## ViewModel 缓冲

- 新增：

```swift
@Published private(set) var samples: [UUID: [PingSample]] = [:]
@Published var detailExpanded = false
private var pendingSamples: [UUID: [PingSample]] = [:]
static let sampleLimit = 200
```

- `engine.onSample` 回调切到主线程后写入 `pendingSamples`，复用现有 0.25 秒刷新节流，与 `stats` 一起合并发布。
- 每个目标只保留最近 200 条，超出时从头部丢弃。
- `clearResults()` 同时清空 `samples` 与 `pendingSamples`。
- `applyTargets(_:)` 清理已删除目标的历史；停止/重新开始探测不清空历史。
- `selection` 不再恰好包含一个目标时，自动把 `detailExpanded` 置为 `false`。
- 新增派生数据：

```swift
var detailRow: PingTableRow?          // 恰好选中一个目标时返回该行
func samples(for id: UUID) -> [PingSample]
func toggleDetailExpanded()
func clearSamples(for id: UUID)
```

## 明细面板

新增 `Sources/PingDeck/TargetDetailPanel.swift`，插入在表格与底部状态栏之间。

### 折叠摘要栏

- 仅在 `detailRow != nil` 时显示。
- 默认折叠；内容为：展开箭头、主机名、备注、状态徽标、最近记录条数。
- 双击表格中的目标行可直接选中并展开该目标的明细。
- 点击摘要栏切换展开/收起。
- 选中另一个单个目标时保持当前展开状态；选中 0 个或多个目标时面板消失并复位折叠状态。

### 展开内容

- 高度可拖动，范围 120–400pt，使用 `@AppStorage("targets.detailPanelHeight")` 记忆。
- 顶部为属性摘要，采用自适应网格：
  - 分组、颜色标签、成功/失败、丢包率
  - 平均、最小、最大、上次响应、最后失败时间
- 属性下方为历史表格，按时间倒序：
  - 时间、序号、结果、延迟 (ms)、对端 IP、TTL、信息
- 空状态显示「暂无探测记录」。
- 展开时摘要栏右侧提供「清空明细」按钮，只清空该目标历史，不影响统计结果。

### 结果与颜色

- 成功：绿色；超时：橙色；不可达/错误：红色。
- 非成功样本的延迟、对端 IP、TTL 显示 `-`。

## 本地化

所有新增文案进入 `Localizable.xcstrings`（zh-Hans / en / ja），并运行 `scripts/generate-localization-symbols.sh` 生成 `L10n.swift`。禁止硬编码用户可见字符串。

## 测试

- `PingCoreTests`：
  - 解析 IPv4 回包的 peer 与 ttl。
  - 解析 IPv6 回包的 peer、`hlim`、`icmp6_seq`。
  - 缺少 peer/ttl 时返回 `nil`。
- `PingEngineTests`（或现有引擎测试文件）：
  - 回包产生 `.reply` 样本。
  - 超时行产生 `.timeout` 样本。
- `ViewModelTests`：
  - 样本按目标累积、超过 200 条丢弃最旧。
  - `clearResults()` 清空历史。
  - 删除目标清理对应历史。
  - 多选时 `detailRow == nil`，单选时返回正确目标。
- `swift build` 与 `swift test` 全绿。

## 兼容性

- `PingSample` 不写入配置文件，不影响 `AppConfiguration` 解码。
- `PingEvent.reply` 的签名变化只影响解析器、引擎与测试，需同步更新所有模式匹配。
- 历史仅驻留内存；200 条 × 目标数的规模在可接受范围内。
