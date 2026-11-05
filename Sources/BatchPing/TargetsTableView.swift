import SwiftUI
import PingCore

/// 目标表格
///
/// 行容器用 `List(selection:)`，由 AppKit 提供原生的多选语义：
/// 点击单选、⌘ 点击加选、⇧ 点击选区间，都不再自己判断修饰键。
/// 「启用」开关放在最后一列并用 switch 样式，避免和「选中」混淆。
struct TargetsTableView: View {
    @EnvironmentObject private var model: BatchPingViewModel

    private let colStatus: CGFloat = 92
    private let colValue: CGFloat = 80
    private let colLoss: CGFloat = 76
    private let colLast: CGFloat = 150
    private let colEnable: CGFloat = 54

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if model.rows.isEmpty {
                emptyState
            } else {
                List(selection: $model.selection) {
                    ForEach(model.rows) { row in
                        rowView(row)
                            .tag(row.id)
                    }
                }
                .listStyle(.plain)
                .environment(\.defaultMinListRowHeight, 26)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Button {
                model.toggleSort(.target)
            } label: {
                HStack(spacing: 2) {
                    Text("目标")
                    if model.sort.field == .target {
                        sortIndicator
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 6)
            .help("点击按「\(SortSpec.Field.target.title)」排序")

            headerCell("状态", field: nil, width: colStatus, alignment: .leading)
            headerCell("最新(ms)", field: .last, width: colValue)
            headerCell("平均(ms)", field: .average, width: colValue)
            headerCell("最小(ms)", field: .minimum, width: colValue)
            headerCell("最大(ms)", field: .maximum, width: colValue)
            headerCell("丢包率", field: .loss, width: colLoss)
            headerCell("最后响应时间", field: .lastResponse, width: colLast)
            Text("启用")
                .frame(width: colEnable, alignment: .trailing)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func headerCell(_ title: String, field: SortSpec.Field?, width: CGFloat, alignment: Alignment = .trailing) -> some View {
        Button {
            if let field {
                model.toggleSort(field)
            }
        } label: {
            HStack(spacing: 2) {
                Text(title)
                if let field, model.sort.field == field {
                    sortIndicator
                }
            }
            .frame(width: width, alignment: alignment)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(field == nil)
        .help(field == nil ? title : "点击按「\(field?.title ?? title)」排序")
    }

    private var sortIndicator: some View {
        Image(systemName: model.sort.ascending ? "chevron.up" : "chevron.down")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.secondary)
    }

    private func rowView(_ row: TargetRow) -> some View {
        HStack(spacing: 0) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 6)

            StatusBadge(status: row.stats.status, message: row.stats.message)
                .frame(width: colStatus, alignment: .leading)

            LatencyCell(value: row.stats.lastLatency)
                .frame(width: colValue, alignment: .trailing)
            LatencyCell(value: row.stats.averageLatency)
                .frame(width: colValue, alignment: .trailing)
            LatencyCell(value: row.stats.minLatency)
                .frame(width: colValue, alignment: .trailing)
            LatencyCell(value: row.stats.maxLatency)
                .frame(width: colValue, alignment: .trailing)

            Text(row.stats.sent > 0 ? String(format: "%.1f%%", row.stats.lossRate * 100) : "-")
                .monospacedDigit()
                .frame(width: colLoss, alignment: .trailing)

            Text(model.formattedTime(row.stats.lastResponseAt))
                .font(.system(size: 11, design: .monospaced))
                .frame(width: colLast, alignment: .trailing)

            Toggle("", isOn: Binding(
                get: { row.target.enabled },
                set: { model.setEnabled(id: row.id, enabled: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .help(row.target.enabled ? "点击停用该目标" : "点击启用该目标")
            .frame(width: colEnable, alignment: .trailing)
        }
        .padding(.vertical, 2)
        .help(row.stats.message.isEmpty ? row.stats.status.displayName : row.stats.message)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "network")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text("还没有 Ping 目标")
                .foregroundStyle(.secondary)
            Text("点击左上角「添加」加入 IP 或域名")
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
