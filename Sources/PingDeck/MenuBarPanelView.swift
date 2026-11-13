import SwiftUI
import AppKit
import PingCore

struct MenuBarPanelView: View {
    @ObservedObject var model: PingDeckViewModel
    var onOpenMainWindow: () -> Void
    var onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            overviewCard
            Divider()
            problemListSection
            Divider()
            actionsBar
        }
        .padding(12)
        .frame(width: 320)
    }

    // MARK: - Overview Card

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.menuBarOverviewTitle)
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.menuBarOnlineRate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(onlineRateText)
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(L10n.menuBarAvgLatency)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(avgLatencyText)
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                }
            }

            HStack(spacing: 6) {
                StatusPill(color: .green, text: String(localized: L10n.statusBarAlive(model.aliveCount)))
                StatusPill(color: .red, text: String(localized: L10n.statusBarProblems(model.problemCount)))
                StatusPill(color: .secondary, text: String(localized: L10n.statusBarQueued(model.queuedTargetCount)))
                Spacer(minLength: 0)
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var onlineRateText: String {
        let enabled = model.enabledTargetCount
        guard enabled > 0 else { return "-" }
        let rate = (Double(model.aliveCount) / Double(enabled)) * 100.0
        return String(format: "%.1f%%", rate)
    }

    private var avgLatencyText: String {
        guard let avg = model.averageAliveLatency else { return "-" }
        return String(format: "%.1f ms", avg)
    }

    // MARK: - Problem List

    private var problemListSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if model.recentProblemRows.isEmpty {
                HStack(spacing: 6) {
                    Text("🎉")
                    Text(L10n.menuBarAllNormal)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                HStack {
                    Text(L10n.menuBarRecentProblems)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                VStack(spacing: 4) {
                    ForEach(model.recentProblemRows) { row in
                        ProblemRowItemView(row: row, action: onOpenMainWindow)
                    }
                }

                Button(action: onOpenMainWindow) {
                    HStack(spacing: 4) {
                        Text(L10n.menuBarViewAllProblems)
                        Text("(\(model.problemCount))")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions Bar

    private var actionsBar: some View {
        VStack(spacing: 2) {
            MenuBarActionButton(
                title: L10n.menuBarOpenMainWindow,
                systemImage: "macwindow",
                action: onOpenMainWindow
            )

            MenuBarActionButton(
                title: model.isRunning ? L10n.menuBarPausePing : L10n.menuBarResumePing,
                systemImage: model.isRunning ? "pause.fill" : "play.fill",
                action: { model.toggleRun() }
            )

            MenuBarActionButton(
                title: L10n.menuSettings,
                systemImage: "gearshape",
                action: onOpenSettings
            )

            Divider()
                .padding(.vertical, 4)

            MenuBarActionButton(
                title: L10n.menuBarQuit,
                systemImage: "power",
                action: { NSApp.terminate(nil) }
            )
        }
    }
}

// MARK: - Subviews

private struct StatusPill: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption2.weight(.medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct ProblemRowItemView: View {
    let row: PingTableRow
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor(row.stats.status))
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(row.target.host)
                            .font(.system(.callout, design: .monospaced, weight: .medium))
                            .lineLimit(1)
                        if !row.target.note.isEmpty {
                            Text("(\(row.target.note))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Text(row.stats.displayMessage.isEmpty ? row.stats.status.displayName : row.stats.displayMessage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isHovered ? Color.primary.opacity(0.06) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("\(row.target.host)\(row.target.note.isEmpty ? "" : " (\(row.target.note))") - \(row.stats.displayMessage.isEmpty ? row.stats.status.displayName : row.stats.displayMessage)")
        .onHover { isHovered = $0 }
    }

    private func statusColor(_ status: TargetStatus) -> Color {
        switch status {
        case .alive: return .green
        case .timeout: return .orange
        case .unreachable, .error: return .red
        case .disabled: return .secondary.opacity(0.6)
        case .running, .pending, .idle: return .secondary
        }
    }
}

private struct MenuBarActionButton: View {
    let title: LocalizedStringResource
    let systemImage: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .frame(width: 16)
                Text(title)
                Spacer()
            }
            .font(.callout)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
