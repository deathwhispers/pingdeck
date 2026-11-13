import SwiftUI
import PingCore

/// 表格列
enum TargetColumn: String, CaseIterable, Identifiable {
    case colorTag
    case target
    case group
    case status
    case last
    case average
    case minimum
    case maximum
    case loss
    case lastResponse
    case enabled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .colorTag: return String(localized: L10n.colorTagColumnTitle)
        case .target: return String(localized: L10n.tableColumnTarget)
        case .group: return String(localized: L10n.groupColumnTitle)
        case .status: return String(localized: L10n.tableColumnStatus)
        case .last: return String(localized: L10n.tableColumnLast)
        case .average: return String(localized: L10n.tableColumnAverage)
        case .minimum: return String(localized: L10n.tableColumnMin)
        case .maximum: return String(localized: L10n.tableColumnMax)
        case .loss: return String(localized: L10n.tableColumnLoss)
        case .lastResponse: return String(localized: L10n.tableColumnLastResponse)
        case .enabled: return String(localized: L10n.tableColumnEnabled)
        }
    }

    var sortField: SortSpec.Field {
        switch self {
        case .colorTag: return .colorTag
        case .target: return .target
        case .group: return .group
        case .status: return .status
        case .last: return .last
        case .average: return .average
        case .minimum: return .minimum
        case .maximum: return .maximum
        case .loss: return .loss
        case .lastResponse: return .lastResponse
        case .enabled: return .enabled
        }
    }

    var alignment: TableColumnAlignment {
        switch self {
        case .colorTag: return .center
        case .target, .status, .group: return .leading
        default: return .trailing
        }
    }

    /// 目标列固定显示，避免表格失去主标识
    var isRequired: Bool { self == .target }

    var minWidth: CGFloat {
        switch self {
        case .colorTag: return 24
        case .target: return 160
        case .group: return 70
        case .status: return 70
        case .last, .average, .minimum, .maximum: return 60
        case .loss: return 60
        case .lastResponse: return 120
        case .enabled: return 44
        }
    }

    var idealWidth: CGFloat {
        switch self {
        case .colorTag: return 32
        case .target: return 320
        case .group: return 100
        case .status: return 92
        case .last, .average, .minimum, .maximum: return 80
        case .loss: return 76
        case .lastResponse: return 150
        case .enabled: return 54
        }
    }

    var maxWidth: CGFloat {
        switch self {
        case .colorTag: return 40
        case .target: return 800
        case .group: return 200
        case .status: return 160
        case .last, .average, .minimum, .maximum: return 140
        case .loss: return 120
        case .lastResponse: return 240
        case .enabled: return 80
        }
    }
}

/// 列显隐的持久化 key
enum ColumnCustomizationStore {
    static let storageKey = "targets.columnCustomization"
}

/// 表格排序比较器：空值始终排在最后，不随升降序翻转
struct TargetRowComparator: SortComparator {
    let field: SortSpec.Field
    var order: SortOrder = .forward

    func compare(_ lhs: TargetRow, _ rhs: TargetRow) -> ComparisonResult {
        let result: ComparisonResult
        switch field {
        case .colorTag:
            result = ordered(lhs.target.colorTag?.rawValue, rhs.target.colorTag?.rawValue)
        case .target:
            result = ordered(lhs.target.host.localizedStandardCompare(rhs.target.host))
        case .group:
            result = ordered(lhs.target.group.localizedStandardCompare(rhs.target.group))
        case .status:
            result = ordered(lhs.stats.status.sortRank, rhs.stats.status.sortRank)
        case .last:
            result = ordered(lhs.stats.lastLatency, rhs.stats.lastLatency)
        case .average:
            result = ordered(lhs.stats.averageLatency, rhs.stats.averageLatency)
        case .minimum:
            result = ordered(lhs.stats.minLatency, rhs.stats.minLatency)
        case .maximum:
            result = ordered(lhs.stats.maxLatency, rhs.stats.maxLatency)
        case .loss:
            result = ordered(lhs.stats.lossRate, rhs.stats.lossRate)
        case .lastResponse:
            result = ordered(lhs.stats.lastResponseAt, rhs.stats.lastResponseAt)
        case .enabled:
            result = ordered(lhs.target.enabled ? 1 : 0, rhs.target.enabled ? 1 : 0)
        }

        if result == .orderedSame {
            return lhs.target.host.localizedStandardCompare(rhs.target.host)
        }
        return result
    }

    /// 空值固定排在最后，不随升降序翻转
    private func ordered<T: Comparable>(_ lhs: T?, _ rhs: T?) -> ComparisonResult {
        switch (lhs, rhs) {
        case (nil, nil): return .orderedSame
        case (nil, _): return .orderedDescending
        case (_, nil): return .orderedAscending
        case let (lhs?, rhs?): return ordered(lhs, rhs)
        }
    }

    private func ordered<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        if lhs == rhs { return .orderedSame }
        let result: ComparisonResult = lhs < rhs ? .orderedAscending : .orderedDescending
        return order == .forward ? result : reversed(result)
    }

    private func ordered(_ result: ComparisonResult) -> ComparisonResult {
        order == .forward ? result : reversed(result)
    }

    private func reversed(_ result: ComparisonResult) -> ComparisonResult {
        switch result {
        case .orderedAscending: return .orderedDescending
        case .orderedDescending: return .orderedAscending
        case .orderedSame: return .orderedSame
        }
    }
}

/// 目标表格
///
/// 使用 SwiftUI `Table`：原生列宽拖动、横向滚动、多选与表头排序。
/// 列显隐与顺序通过 `TableColumnCustomization` 管理并持久化，「目标」列固定显示。
struct TargetsTableView: View {
    @EnvironmentObject private var model: PingDeckViewModel
    @Binding var columnCustomization: TableColumnCustomization<TargetRow>

    var body: some View {
        if model.filteredRows.isEmpty {
            emptyState
        } else {
            table
        }
    }

    private var table: some View {
        Table(
            model.filteredRows,
            selection: $model.selection,
            sortOrder: sortOrder,
            columnCustomization: $columnCustomization
        ) {
            TableColumnBuilder<TargetRow, TargetRowComparator>.buildBlock(
                tableColumn(.colorTag) { row in
                    if let tag = row.target.colorTag {
                        Circle()
                            .fill(tag.color)
                            .frame(width: 8, height: 8)
                            .help(tag.localizedName)
                    }
                },
                tableColumn(.target) { row in
                    HStack(spacing: 6) {
                        Text(row.target.host)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)
                        if !row.target.note.isEmpty {
                            Text(row.target.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .help(row.stats.displayMessage.isEmpty ? row.stats.status.displayName : row.stats.displayMessage)
                },
                tableColumn(.group) { row in
                    Text(row.target.group.isEmpty ? String(localized: L10n.groupDefaultName) : row.target.group)
                        .foregroundStyle(row.target.group.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                },
                tableColumn(.status) { row in
                    StatusBadge(status: row.stats.status, message: row.stats.displayMessage)
                },
                tableColumn(.last) { row in
                    LatencyCell(value: row.stats.lastLatency)
                },
                tableColumn(.average) { row in
                    LatencyCell(value: row.stats.averageLatency)
                }
            )

            TableColumnBuilder<TargetRow, TargetRowComparator>.buildBlock(
                tableColumn(.minimum) { row in
                    LatencyCell(value: row.stats.minLatency)
                },
                tableColumn(.maximum) { row in
                    LatencyCell(value: row.stats.maxLatency)
                },
                tableColumn(.loss) { row in
                    Text(row.stats.sent > 0 ? String(format: "%.1f%%", row.stats.lossRate * 100) : "-")
                        .monospacedDigit()
                },
                tableColumn(.lastResponse) { row in
                    Text(model.formattedTime(row.stats.lastResponseAt))
                        .font(.system(size: 11, design: .monospaced))
                },
                tableColumn(.enabled) { row in
                    Toggle("", isOn: Binding(
                        get: { row.target.enabled },
                        set: { model.setEnabled(id: row.id, enabled: $0) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .help(String(localized: row.target.enabled ? L10n.tableEnabledDisableHelp : L10n.tableEnabledEnableHelp))
                }
            )
        }
        .tableStyle(.inset(alternatesRowBackgrounds: false))
    }

    private func tableColumn<Content: View>(
        _ column: TargetColumn,
        @ViewBuilder content: @escaping (TargetRow) -> Content
    ) -> some TableColumnContent<TargetRow, TargetRowComparator> {
        let frameAlignment: Alignment = {
            switch column.alignment {
            case .leading: return .leading
            case .center: return .center
            case .trailing: return .trailing
            default: return .leading
            }
        }()

        return TableColumn(column.title, sortUsing: TargetRowComparator(field: column.sortField)) { row in
            content(row)
                .frame(
                    maxWidth: .infinity,
                    alignment: frameAlignment
                )
        }
        .width(min: column.minWidth, ideal: column.idealWidth, max: column.maxWidth)
        .alignment(column.alignment)
        .customizationID(column.rawValue)
        .disabledCustomizationBehavior(column.isRequired ? .visibility : [])
    }

    private var sortOrder: Binding<[TargetRowComparator]> {
        Binding(
            get: {
                [
                    TargetRowComparator(
                        field: model.sort.field,
                        order: model.sort.ascending ? .forward : .reverse
                    )
                ]
            },
            set: { newValue in
                guard let first = newValue.first else { return }
                model.sort = SortSpec(field: first.field, ascending: first.order == .forward)
            }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "network")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text(L10n.tableEmptyTitle)
                .foregroundStyle(.secondary)
            Text(L10n.tableEmptyMessage)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatusBadge: View {
    let status: TargetStatus
    let message: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(status.displayName)
                .font(.caption)
        }
        .help(message.isEmpty ? status.displayName : message)
    }

    private var color: Color {
        switch status {
        case .alive: return .green
        case .timeout: return .orange
        case .unreachable, .error: return .red
        case .disabled: return .secondary.opacity(0.6)
        case .running, .pending, .idle: return .secondary
        }
    }
}

struct LatencyCell: View {
    let value: Double?

    var body: some View {
        Text(value.map { String(format: "%.2f", $0) } ?? "-")
            .monospacedDigit()
    }
}
