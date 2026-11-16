# 单目标探测历史明细实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为每个目标记录最近 200 次探测样本，并在选中单个目标时提供可折叠、可拖动高度的底部明细面板。

**Architecture:** `PingCore` 新增 `PingSample` 并扩展解析器输出对端 IP/TTL；`PingEngine` 通过 `onSample` 增量回调；`PingDeckViewModel` 用 0.25 秒节流维护每目标环形缓冲；SwiftUI 新增 `TargetDetailPanel` 承载属性摘要与历史表。

**Tech Stack:** Swift 5.9、SwiftUI、AppKit、XCTest、SwiftPM。

**Spec:** `docs/superpowers/specs/2026-11-16-target-history-detail-design.md`

## Global Constraints

- 每个目标最多保留 200 条样本，仅内存，不写入配置。
- 历史在应用重启、清空结果、删除目标时清空；停止/重新开始探测不清空。
- 明细面板仅在恰好选中一个目标时出现，默认折叠。
- 面板高度范围 120–400pt，使用 `@AppStorage("targets.detailPanelHeight")` 记忆。
- 所有用户可见文案必须进入 String Catalog（zh-Hans / en / ja），禁止硬编码。
- 不改变现有导出、目标配置格式与统计口径。

---

### Task 1: 新增 PingSample 并扩展解析器

**Files:**
- Create: `Sources/PingCore/PingSample.swift`
- Modify: `Sources/PingCore/PingParser.swift`
- Modify: `Sources/PingCore/PingEngine.swift:239-257`
- Test: `Tests/PingCoreTests/PingCoreTests.swift`

**Interfaces:**
- Produces: `PingSample`, `PingSample.Outcome`, `PingEvent.reply(seq:latencyMs:peerAddress:ttl:)`
- Consumes: 现有 `PingLineParser.parse(_:)`

- [ ] **Step 1: 新建 PingSample**

```swift
import Foundation

/// 单次探测样本，仅用于界面展示，不持久化。
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

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        seq: Int? = nil,
        outcome: Outcome,
        latencyMs: Double? = nil,
        peerAddress: String? = nil,
        ttl: Int? = nil,
        message: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.seq = seq
        self.outcome = outcome
        self.latencyMs = latencyMs
        self.peerAddress = peerAddress
        self.ttl = ttl
        self.message = message
    }
}
```

- [ ] **Step 2: 扩展 PingEvent.reply 与解析器**

`PingParser.swift` 中：

```swift
case reply(seq: Int?, latencyMs: Double, peerAddress: String?, ttl: Int?)
```

解析入口改为：

```swift
if let latency = latency(in: line) {
    return .reply(
        seq: sequence(in: line),
        latencyMs: latency,
        peerAddress: peerAddress(in: line),
        ttl: ttl(in: line)
    )
}
```

新增：

```swift
private static func peerAddress(in line: String) -> String? {
    guard let range = line.range(of: "from ") else { return nil }
    let tail = line[range.upperBound...]
    let token = tail.prefix { !$0.isWhitespace }
    let address = token.hasSuffix(":") ? token.dropLast() : token
    return address.isEmpty ? nil : String(address)
}

private static func ttl(in line: String) -> Int? {
    for key in ["ttl=", "hlim="] {
        guard let range = line.range(of: key) else { continue }
        let digits = line[range.upperBound...].prefix { $0.isNumber }
        if let value = Int(digits) {
            return value
        }
    }
    return nil
}

private static func sequence(in line: String) -> Int? {
    let marker: String
    if line.contains("icmp6_seq") {
        marker = "icmp6_seq"
    } else if line.contains("icmp_seq") {
        marker = "icmp_seq"
    } else {
        return nil
    }
    guard let range = line.range(of: marker) else { return nil }
    var tail = line[range.upperBound...]
    tail = tail.drop(while: { $0 == " " || $0 == "=" })
    let digits = tail.prefix { $0.isNumber }
    return Int(digits)
}
```

- [ ] **Step 3: 更新引擎模式匹配**

`PingEngine.handleEventLocked` 中：

```swift
case .reply(let seq, let latency, _, _):
    value.recordSuccess(latency, at: Date(), seq: seq)
```

本任务只保证编译，不产生样本。

- [ ] **Step 4: 更新并新增解析器测试**

`testParsesReplyLine` 期望：

```swift
XCTAssertEqual(
    event,
    .reply(seq: 0, latencyMs: 13.163, peerAddress: "8.8.8.8", ttl: 118)
)
```

`testParsesIPv6ReplyLine` 期望：

```swift
XCTAssertEqual(
    event,
    .reply(seq: 2, latencyMs: 8.001, peerAddress: "2001:4860:4860::8888", ttl: 52)
)
```

新增：

```swift
func testReplyWithoutPeerAndTTL() {
    let event = PingLineParser.parse("64 bytes icmp_seq=1 time=1.5 ms")
    XCTAssertEqual(
        event,
        .reply(seq: 1, latencyMs: 1.5, peerAddress: nil, ttl: nil)
    )
}

func testParsesICMP6Sequence() {
    let event = PingLineParser.parse("64 bytes from fe80::1%en0: icmp6_seq=7 ttl=64 time=0.300 ms")
    XCTAssertEqual(
        event,
        .reply(seq: 7, latencyMs: 0.3, peerAddress: "fe80::1%en0", ttl: 64)
    )
}
```

- [ ] **Step 5: 运行测试**

Run: `swift test --filter PingParserTests`
Expected: PASS

- [ ] **Step 6: 提交**

```bash
git add Sources/PingCore/PingSample.swift Sources/PingCore/PingParser.swift Sources/PingCore/PingEngine.swift Tests/PingCoreTests/PingCoreTests.swift
git commit -m "feat: 新增探测样本模型并解析对端地址与 TTL"
```

---

### Task 2: 引擎产生样本事件

**Files:**
- Modify: `Sources/PingCore/PingEngine.swift`
- Test: `Tests/PingCoreTests/PingCoreTests.swift`

**Interfaces:**
- Consumes: `PingSample`、`PingEvent`
- Produces: `PingEngine.onSample: ((UUID, PingSample) -> Void)?`、`PingEngine.sample(for:)`（internal，供测试）

- [ ] **Step 1: 新增回调与事件映射**

```swift
public var onSample: ((UUID, PingSample) -> Void)?
```

在 `PingEngine` 内新增：

```swift
static func sample(for event: PingEvent) -> PingSample? {
    switch event {
    case .reply(let seq, let latency, let peer, let ttl):
        return PingSample(seq: seq, outcome: .reply, latencyMs: latency, peerAddress: peer, ttl: ttl)
    case .timeout(let seq):
        return PingSample(seq: seq, outcome: .timeout)
    case .unreachable(let text):
        return PingSample(outcome: .unreachable, message: text)
    case .failure(let text):
        return PingSample(outcome: .failure, message: text)
    case .info:
        return nil
    }
}
```

`handleEventLocked` 每个分支后调用：

```swift
if let sample = Self.sample(for: event) {
    onSample?(id, sample)
}
```

注意 `failure` 分支会先停止进程，样本仍应在停止前发出。

- [ ] **Step 2: 静默超时补记样本**

`applyStaleTimeoutLocked` 中状态改为 `.timeout` 后：

```swift
onSample?(id, PingSample(outcome: .timeout))
```

- [ ] **Step 3: 新增映射测试**

```swift
func testEngineMapsReplyEventToSample() {
    let sample = PingEngine.sample(
        for: .reply(seq: 3, latencyMs: 12.5, peerAddress: "8.8.8.8", ttl: 118)
    )
    XCTAssertEqual(sample?.outcome, .reply)
    XCTAssertEqual(sample?.seq, 3)
    XCTAssertEqual(sample?.latencyMs, 12.5)
    XCTAssertEqual(sample?.peerAddress, "8.8.8.8")
    XCTAssertEqual(sample?.ttl, 118)
}

func testEngineMapsTimeoutEventToSample() {
    let sample = PingEngine.sample(for: .timeout(seq: 4))
    XCTAssertEqual(sample?.outcome, .timeout)
    XCTAssertEqual(sample?.seq, 4)
}

func testEngineIgnoresInfoEvent() {
    XCTAssertNil(PingEngine.sample(for: .info("statistics")))
}
```

- [ ] **Step 4: 运行测试**

Run: `swift test --filter PingParserTests`
Expected: PASS（新增测试可放在 `PingParserTests` 或新测试类）

- [ ] **Step 5: 提交**

```bash
git add Sources/PingCore/PingEngine.swift Tests/PingCoreTests/PingCoreTests.swift
git commit -m "feat: 引擎增量回调探测样本"
```

---

### Task 3: ViewModel 维护历史缓冲与明细状态

**Files:**
- Modify: `Sources/PingDeck/PingDeckViewModel.swift`
- Test: `Tests/PingDeckTests/ViewModelTests.swift`

**Interfaces:**
- Consumes: `PingEngine.onSample`
- Produces:
  - `@Published private(set) var samples: [UUID: [PingSample]]`
  - `@Published var detailExpanded: Bool`
  - `var detailRow: PingTableRow?`
  - `func samples(for id: UUID) -> [PingSample]`
  - `func toggleDetailExpanded()`
  - `func clearSamples(for id: UUID)`
  - `func enqueueSample(id:sample:)`、`func flushPendingUpdates()`（internal，供测试与引擎回调）

- [ ] **Step 1: 添加状态与引擎回调**

```swift
@Published private(set) var samples: [UUID: [PingSample]] = [:]
@Published var detailExpanded = false
private var pendingSamples: [UUID: [PingSample]] = [:]
static let sampleLimit = 200
```

初始化引擎回调：

```swift
engine.onSample = { [weak self] id, sample in
    DispatchQueue.main.async {
        self?.enqueueSample(id: id, sample: sample)
    }
}
```

- [ ] **Step 2: 节流合并**

```swift
func enqueueSample(id: UUID, sample: PingSample) {
    pendingSamples[id, default: []].append(sample)
    scheduleFlush()
}

func flushPendingUpdates() {
    flushTimer?.invalidate()
    flushTimer = nil
    flushStats()
}

private func flushStats() {
    flushTimer = nil
    guard !pendingStats.isEmpty || !pendingSamples.isEmpty else { return }

    for (id, value) in pendingStats {
        stats[id] = value
    }
    pendingStats.removeAll()

    for (id, values) in pendingSamples {
        var list = samples[id] ?? []
        list.append(contentsOf: values)
        if list.count > Self.sampleLimit {
            list.removeFirst(list.count - Self.sampleLimit)
        }
        samples[id] = list
    }
    pendingSamples.removeAll()
}
```

- [ ] **Step 3: 清理与派生数据**

`applyTargets` 中追加：

```swift
let validIDs = Set(updated.map(\.id))
samples = samples.filter { validIDs.contains($0.key) }
pendingSamples = pendingSamples.filter { validIDs.contains($0.key) }
```

`clearResults()`：

```swift
engine.clearStats()
stats = [:]
samples = [:]
pendingSamples.removeAll()
```

新增：

```swift
var detailRow: PingTableRow? {
    guard selection.count == 1, let id = selection.first else { return nil }
    return rows.first { $0.id == id }
}

func samples(for id: UUID) -> [PingSample] {
    samples[id] ?? []
}

func toggleDetailExpanded() {
    detailExpanded.toggle()
}

func clearSamples(for id: UUID) {
    samples[id] = []
    pendingSamples[id] = []
}
```

`selection` 增加 `didSet`：

```swift
@Published var selection: Set<UUID> = [] {
    didSet {
        if selection.count != 1 {
            detailExpanded = false
        }
    }
}
```

- [ ] **Step 4: 新增 ViewModel 测试**

```swift
func testSamplesKeepOnlyLatest200() {
    let model = makeModel(["a.com"])
    let id = model.targets[0].id
    for index in 0..<205 {
        model.enqueueSample(id: id, sample: PingSample(seq: index, outcome: .reply, latencyMs: 1))
    }
    model.flushPendingUpdates()

    let samples = model.samples(for: id)
    XCTAssertEqual(samples.count, 200)
    XCTAssertEqual(samples.first?.seq, 5)
    XCTAssertEqual(samples.last?.seq, 204)
}

func testClearResultsClearsSamples() {
    let model = makeModel(["a.com"])
    let id = model.targets[0].id
    model.enqueueSample(id: id, sample: PingSample(outcome: .timeout))
    model.flushPendingUpdates()

    model.clearResults()

    XCTAssertTrue(model.samples(for: id).isEmpty)
}

func testRemovingTargetDropsSamples() {
    let model = makeModel(["a.com", "b.com"])
    let id = model.targets[0].id
    model.enqueueSample(id: id, sample: PingSample(outcome: .timeout))
    model.flushPendingUpdates()

    model.removeTargets(ids: [id])

    XCTAssertTrue(model.samples(for: id).isEmpty)
}

func testDetailRowRequiresSingleSelection() {
    let model = makeModel(["a.com", "b.com"])
    let ids = model.targets.map(\.id)

    model.selection = Set(ids)
    XCTAssertNil(model.detailRow)

    model.selection = [ids[1]]
    XCTAssertEqual(model.detailRow?.target.host, "b.com")
}

func testSelectionChangeCollapsesDetail() {
    let model = makeModel(["a.com", "b.com"])
    let ids = model.targets.map(\.id)
    model.selection = [ids[0]]
    model.detailExpanded = true

    model.selection = Set(ids)

    XCTAssertFalse(model.detailExpanded)
}
```

注意：`makeModel` 存在于多个测试类中，新测试放在已有辅助方法的类里，或新建辅助方法。

- [ ] **Step 5: 运行测试**

Run: `swift test --filter ViewModelTests`
Expected: PASS

- [ ] **Step 6: 提交**

```bash
git add Sources/PingDeck/PingDeckViewModel.swift Tests/PingDeckTests/ViewModelTests.swift
git commit -m "feat: 视图模型维护每目标探测历史"
```

---

### Task 4: 明细面板与本地化

**Files:**
- Create: `Sources/PingDeck/TargetDetailPanel.swift`
- Modify: `Sources/PingDeck/ContentView.swift:19-27`
- Modify: `Sources/PingDeck/Resources/Localizable.xcstrings`
- Regenerate: `Sources/PingDeck/Generated/L10n.swift`

**Interfaces:**
- Consumes: `model.detailRow`、`model.samples(for:)`、`model.detailExpanded`、`model.toggleDetailExpanded()`、`model.clearSamples(for:)`
- Produces: `TargetDetailPanel` SwiftUI 视图

- [ ] **Step 1: 创建 TargetDetailPanel**

```swift
import SwiftUI
import PingCore

struct TargetDetailPanel: View {
    @EnvironmentObject private var model: PingDeckViewModel
    @AppStorage("targets.detailPanelHeight") private var storedHeight: Double = 220
    @State private var dragStartHeight: Double?

    var body: some View {
        if let row = model.detailRow {
            VStack(spacing: 0) {
                header(row)
                if model.detailExpanded {
                    Divider()
                    expandedContent(row)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }

    private func header(_ row: PingTableRow) -> some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    model.toggleDetailExpanded()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: model.detailExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(row.target.host)
                        .font(.system(.callout, design: .monospaced))
                        .lineLimit(1)
                    if !row.target.note.isEmpty {
                        Text(row.target.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    StatusBadge(status: row.stats.status, message: row.stats.displayMessage)
                    Text(L10n.detailHeaderRecords(row.stats.sent))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if model.detailExpanded {
                Button(String(localized: L10n.detailClear)) {
                    model.clearSamples(for: row.id)
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }

    private func expandedContent(_ row: PingTableRow) -> some View {
        VStack(spacing: 0) {
            resizeHandle
            properties(row)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            Divider()
            sampleTable(row)
        }
        .frame(height: min(400, max(120, storedHeight)))
    }
    ...
}
```

属性摘要使用自适应网格；历史表使用 `Table`，列为时间、序号、结果、延迟、对端 IP、TTL、信息。完整实现见下文步骤 2。

- [ ] **Step 2: 实现属性、历史表与拖动句柄**

```swift
private func properties(_ row: PingTableRow) -> some View {
    let failed = max(0, row.stats.sent - row.stats.received)
    let lastFailure = model.samples(for: row.id).last { $0.outcome != .reply }?.timestamp
    return LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)],
        alignment: .leading,
        spacing: 6
    ) {
        property(L10n.detailPropertyGroup, row.target.group.isEmpty ? String(localized: L10n.groupDefaultName) : row.target.group)
        HStack(spacing: 5) {
            Text(L10n.detailPropertyColor)
                .foregroundStyle(.secondary)
            if let tag = row.target.colorTag {
                Circle().fill(tag.color).frame(width: 7, height: 7)
                Text(tag.localizedName)
            } else {
                Text(L10n.detailNone)
            }
        }
        property(L10n.detailPropertySuccessFailure, "\(row.stats.received) / \(failed)")
        property(L10n.detailPropertyLoss, row.stats.sent > 0 ? String(format: "%.1f%%", row.stats.lossRate * 100) : "-")
        property(L10n.detailPropertyAverage, latency(row.stats.averageLatency))
        property(L10n.detailPropertyMinimum, latency(row.stats.minLatency))
        property(L10n.detailPropertyMaximum, latency(row.stats.maxLatency))
        property(L10n.detailPropertyLastResponse, model.formattedTime(row.stats.lastResponseAt))
        property(L10n.detailPropertyLastFailure, model.formattedTime(lastFailure))
    }
    .font(.caption)
}

private func property(_ label: LocalizedStringResource, _ value: String) -> some View {
    HStack(spacing: 5) {
        Text(label).foregroundStyle(.secondary)
        Text(value).monospacedDigit().lineLimit(1)
    }
}

private func sampleTable(_ row: PingTableRow) -> some View {
    let samples = Array(model.samples(for: row.id).reversed())
    return Group {
        if samples.isEmpty {
            Text(L10n.detailEmpty)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Table(samples) {
                TableColumn(String(localized: L10n.detailColumnTime)) { sample in
                    Text(model.formattedTime(sample.timestamp))
                        .font(.system(size: 11, design: .monospaced))
                }
                .width(min: 130, ideal: 150)
                TableColumn(String(localized: L10n.detailColumnSeq)) { sample in
                    Text(sample.seq.map(String.init) ?? "-").monospacedDigit()
                }
                .width(min: 44, ideal: 50)
                TableColumn(String(localized: L10n.detailColumnOutcome)) { sample in
                    outcomeBadge(sample.outcome)
                }
                .width(min: 70, ideal: 80)
                TableColumn(String(localized: L10n.detailColumnLatency)) { sample in
                    Text(sample.latencyMs.map { String(format: "%.2f", $0) } ?? "-").monospacedDigit()
                }
                .width(min: 70, ideal: 80)
                TableColumn(String(localized: L10n.detailColumnPeer)) { sample in
                    Text(sample.peerAddress ?? "-")
                        .font(.system(size: 11, design: .monospaced))
                }
                .width(min: 120, ideal: 160)
                TableColumn(String(localized: L10n.detailColumnTTL)) { sample in
                    Text(sample.ttl.map(String.init) ?? "-").monospacedDigit()
                }
                .width(min: 44, ideal: 50)
                TableColumn(String(localized: L10n.detailColumnMessage)) { sample in
                    Text(sample.message.isEmpty ? "-" : sample.message)
                        .lineLimit(1)
                }
            }
            .tableStyle(.inset(alternatesRowBackgrounds: false))
        }
    }
}

private func outcomeBadge(_ outcome: PingSample.Outcome) -> some View {
    HStack(spacing: 4) {
        Circle().fill(outcomeColor(outcome)).frame(width: 6, height: 6)
        Text(outcomeName(outcome))
    }
}

private var resizeHandle: some View {
    Rectangle()
        .fill(Color.clear)
        .frame(height: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 36, height: 3)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if dragStartHeight == nil { dragStartHeight = storedHeight }
                    let base = dragStartHeight ?? storedHeight
                    storedHeight = min(400, max(120, base - value.translation.height))
                }
                .onEnded { _ in dragStartHeight = nil }
        )
}
```

- [ ] **Step 3: 插入 ContentView**

在表格视图之后、`Divider()` 与 `footerBar` 之前：

```swift
if model.detailRow != nil {
    Divider()
    TargetDetailPanel()
}
```

- [ ] **Step 4: 新增本地化 key**

在 `Localizable.xcstrings` 增加以下 key（三种语言）：

| key | zh-Hans | en | ja |
|---|---|---|---|
| `detail.header.records` | `共 %lld 次探测` | `%lld probes` | `%lld 回のプローブ` |
| `detail.clear` | `清空明细` | `Clear history` | `履歴を消去` |
| `detail.empty` | `暂无探测记录` | `No ping samples yet` | `Ping 履歴はまだありません` |
| `detail.property.group` | `分组` | `Group` | `グループ` |
| `detail.property.color` | `颜色` | `Color` | `色` |
| `detail.property.successFailure` | `成功 / 失败` | `Success / Failure` | `成功 / 失敗` |
| `detail.property.loss` | `丢包率` | `Loss` | `損失率` |
| `detail.property.average` | `平均` | `Avg` | `平均` |
| `detail.property.minimum` | `最小` | `Min` | `最小` |
| `detail.property.maximum` | `最大` | `Max` | `最大` |
| `detail.property.lastResponse` | `上次响应` | `Last response` | `最終応答` |
| `detail.property.lastFailure` | `最后失败` | `Last failure` | `最終失敗` |
| `detail.column.time` | `时间` | `Time` | `時刻` |
| `detail.column.seq` | `序号` | `Seq` | `連番` |
| `detail.column.outcome` | `结果` | `Result` | `結果` |
| `detail.column.latency` | `延迟 (ms)` | `Latency (ms)` | `遅延 (ms)` |
| `detail.column.peer` | `对端 IP` | `Peer` | `相手 IP` |
| `detail.column.ttl` | `TTL` | `TTL` | `TTL` |
| `detail.column.message` | `信息` | `Message` | `情報` |
| `detail.outcome.reply` | `成功` | `Reply` | `成功` |
| `detail.outcome.timeout` | `超时` | `Timeout` | `タイムアウト` |
| `detail.outcome.unreachable` | `不可达` | `Unreachable` | `到達不可` |
| `detail.outcome.failure` | `错误` | `Error` | `エラー` |
| `detail.none` | `无` | `None` | `なし` |

然后运行：

```bash
bash scripts/generate-localization-symbols.sh
```

- [ ] **Step 5: 构建**

Run: `swift build`
Expected: 成功，无未本地化硬编码

- [ ] **Step 6: 提交**

```bash
git add Sources/PingDeck/TargetDetailPanel.swift Sources/PingDeck/ContentView.swift Sources/PingDeck/Resources/Localizable.xcstrings Sources/PingDeck/Generated/L10n.swift
git commit -m "feat: 新增可折叠探测历史明细面板"
```

---

### Task 5: 全量验证与打包

- [ ] **Step 1: 运行全部测试**

Run: `swift test`
Expected: 全部通过

- [ ] **Step 2: 本地打包试用**

Run: `make app`
Expected: `dist/PingDeck.app` 生成

- [ ] **Step 3: 提交剩余改动（如有）**

```bash
git status --short
```

---

## Self-Review

- Spec 覆盖：样本模型、解析器、引擎回调、ViewModel 缓冲、明细面板、本地化、测试均有对应任务。
- 类型一致性：`PingSample.Outcome`、`PingEvent.reply` 四参数、`detailExpanded`、`samples(for:)` 在任务间命名一致。
- 未包含持久化、按目标参数、保存入口改动，符合非目标。
