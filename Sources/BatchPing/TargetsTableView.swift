import SwiftUI
import AppKit
import PingCore

struct TargetsTableView: View {
    @EnvironmentObject private var model: BatchPingViewModel

    private let colEnable: CGFloat = 36
    private let colStatus: CGFloat = 92
    private let colValue: CGFloat = 80
    private let colLoss: CGFloat = 76
    private let colLast: CGFloat = 150

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if model.rows.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.rows) { row in
                            rowView(row)
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: colEnable)
            Text("目标")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
            Text("状态")
                .frame(width: colStatus, alignment: .leading)
            Text("最新(ms)")
                .frame(width: colValue, alignment: .trailing)
            Text("平均(ms)")
                .frame(width: colValue, alignment: .trailing)
            Text("最小(ms)")
                .frame(width: colValue, alignment: .trailing)
            Text("最大(ms)")
                .frame(width: colValue, alignment: .trailing)
            Text("丢包率")
                .frame(width: colLoss, alignment: .trailing)
            Text("最后响应时间")
                .frame(width: colLast, alignment: .trailing)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func rowView(_ row: TargetRow) -> some View {
        HStack(spacing: 0) {
            Toggle("", isOn: Binding(
                get: { row.target.enabled },
                set: { model.setEnabled(id: row.id, enabled: $0) }
            ))
            .labelsHidden()
            .help(row.target.enabled ? "点击停用该目标" : "点击启用该目标")
            .frame(width: colEnable)

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
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(model.selection.contains(row.id) ? Color.accentColor.opacity(0.18) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { handleTap(row) }
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

    private func handleTap(_ row: TargetRow) {
        if NSEvent.modifierFlags.contains(.command) {
            if model.selection.contains(row.id) {
                model.selection.remove(row.id)
            } else {
                model.selection.insert(row.id)
            }
        } else {
            model.selection = [row.id]
        }
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
