import SwiftUI
import AppKit
import PingCore

/// 单目标探测历史明细面板：折叠时只显示摘要栏，展开后展示属性与逐条样本。
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
                    Text(L10n.detailHeaderRecords(model.samples(for: row.id).count))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
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
        .frame(height: CGFloat(min(400, max(120, storedHeight))))
    }

    private func properties(_ row: PingTableRow) -> some View {
        let failed = max(0, row.stats.sent - row.stats.received)
        let lastFailure = model.samples(for: row.id).last { $0.outcome != .reply }?.timestamp
        return LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)],
            alignment: .leading,
            spacing: 6
        ) {
            property(
                L10n.detailPropertyGroup,
                row.target.group.isEmpty ? String(localized: L10n.groupDefaultName) : row.target.group
            )
            HStack(spacing: 5) {
                Text(L10n.detailPropertyTag)
                    .foregroundStyle(.secondary)
                if let tag = row.target.colorTag {
                    Circle()
                        .fill(tag.color)
                        .frame(width: 7, height: 7)
                    Text(tag.localizedName)
                } else {
                    Text(L10n.detailNone)
                }
            }
            property(L10n.detailPropertySuccessFailure, "\(row.stats.received) / \(failed)")
            property(
                L10n.detailPropertyLoss,
                row.stats.sent > 0 ? String(format: "%.1f%%", row.stats.lossRate * 100) : "-"
            )
            property(L10n.detailPropertyAverage, latencyText(row.stats.averageLatency))
            property(L10n.detailPropertyMinimum, latencyText(row.stats.minLatency))
            property(L10n.detailPropertyMaximum, latencyText(row.stats.maxLatency))
            property(L10n.detailPropertyLastResponse, model.formattedTime(row.stats.lastResponseAt))
            property(L10n.detailPropertyLastFailure, model.formattedTime(lastFailure))
        }
        .font(.caption)
    }

    private func property(_ label: LocalizedStringResource, _ value: String) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .monospacedDigit()
                .lineLimit(1)
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
                        Text(sample.seq.map { String($0) } ?? "-")
                            .monospacedDigit()
                    }
                    .width(min: 44, ideal: 50)

                    TableColumn(String(localized: L10n.detailColumnOutcome)) { sample in
                        outcomeBadge(sample.outcome)
                    }
                    .width(min: 70, ideal: 80)

                    TableColumn(String(localized: L10n.detailColumnLatency)) { sample in
                        Text(sample.latencyMs.map { String(format: "%.2f", $0) } ?? "-")
                            .monospacedDigit()
                    }
                    .width(min: 70, ideal: 80)

                    TableColumn(String(localized: L10n.detailColumnPeer)) { sample in
                        Text(sample.peerAddress ?? "-")
                            .font(.system(size: 11, design: .monospaced))
                    }
                    .width(min: 120, ideal: 160)

                    TableColumn(String(localized: L10n.detailColumnTtl)) { sample in
                        Text(sample.ttl.map { String($0) } ?? "-")
                            .monospacedDigit()
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
            Circle()
                .fill(outcomeColor(outcome))
                .frame(width: 6, height: 6)
            Text(outcomeName(outcome))
        }
    }

    private func outcomeName(_ outcome: PingSample.Outcome) -> String {
        switch outcome {
        case .reply: return String(localized: L10n.detailOutcomeReply)
        case .timeout: return String(localized: L10n.detailOutcomeTimeout)
        case .unreachable: return String(localized: L10n.detailOutcomeUnreachable)
        case .failure: return String(localized: L10n.detailOutcomeFailure)
        }
    }

    private func outcomeColor(_ outcome: PingSample.Outcome) -> Color {
        switch outcome {
        case .reply: return .green
        case .timeout: return .orange
        case .unreachable, .failure: return .red
        }
    }

    private func latencyText(_ value: Double?) -> String {
        value.map { String(format: "%.2f", $0) } ?? "-"
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
                if hovering {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if dragStartHeight == nil {
                            dragStartHeight = storedHeight
                        }
                        let base = dragStartHeight ?? storedHeight
                        storedHeight = min(400, max(120, base - Double(value.translation.height)))
                    }
                    .onEnded { _ in
                        dragStartHeight = nil
                    }
            )
    }
}
