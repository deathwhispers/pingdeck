import AppKit
import SwiftUI
import PingCore

/// 灵动岛 SwiftUI 展开视图，提供黑晶流线风格卡片、核心指标、异常速览与快捷控制
@MainActor
public struct NotchIslandView: View {
    @ObservedObject var controller: NotchWindowController
    @ObservedObject var model: PingDeckViewModel

    @MainActor
    init(controller: NotchWindowController, model: PingDeckViewModel) {
        self.controller = controller
        self.model = model
    }

    @MainActor
    init(model: PingDeckViewModel) {
        self.controller = .shared
        self.model = model
    }

    public var body: some View {
        ZStack {
            if controller.isExpanded {
                expandedCard
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            } else {
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: controller.isExpanded)
    }

    // MARK: - Expanded Card Container

    private var expandedCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView

            if model.settings.notchIsland.showMetrics {
                metricsSection
            }

            if model.settings.notchIsland.showRecentProblems {
                Divider()
                    .overlay(Color.white.opacity(0.12))
                recentProblemsSection
            }

            if model.settings.notchIsland.showQuickControls {
                Divider()
                    .overlay(Color.white.opacity(0.12))
                quickControlsSection
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("PingDeck")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                if model.isRunning {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                }
            }

            Spacer()

            Button(action: {
                controller.togglePin()
            }) {
                Image(systemName: controller.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(controller.isPinned ? Color.orange : Color.white.opacity(0.75))
                    .padding(5)
                    .background(controller.isPinned ? Color.orange.opacity(0.2) : Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help(controller.isPinned ? String(localized: L10n.notchIslandUnpinHelp) : String(localized: L10n.notchIslandPinHelp))
        }
    }

    // MARK: - Module 1: Metrics

    private var metricsSection: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(L10n.menuBarOnlineRate)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(onlineRateText)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(L10n.menuBarAvgLatency)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(avgLatencyText)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
            }

            HStack(spacing: 6) {
                StatusPill(color: .green, text: String(localized: L10n.statusBarAlive(model.aliveCount)))
                StatusPill(color: .red, text: String(localized: L10n.statusBarProblems(model.problemCount)))
                StatusPill(color: .secondary, text: String(localized: L10n.statusBarQueued(model.queuedTargetCount)))
                Spacer(minLength: 0)
            }
        }
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

    // MARK: - Module 2: Recent Problems

    private var recentProblemsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if model.recentProblemRows.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.green)
                    Text(L10n.notchIslandAllNormal)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 2)
            } else {
                ForEach(Array(model.recentProblemRows.prefix(3))) { row in
                    NotchProblemRowItemView(row: row) {
                        openMainWindow(selecting: row.id)
                    }
                }
            }
        }
    }

    // MARK: - Module 3: Quick Controls

    private var quickControlsSection: some View {
        HStack(spacing: 8) {
            NotchIslandActionButton(
                title: L10n.menuBarOpenMainWindow,
                systemImage: "macwindow"
            ) {
                openMainWindow()
            }

            NotchIslandActionButton(
                title: model.isRunning ? L10n.menuBarPausePing : L10n.menuBarResumePing,
                systemImage: model.isRunning ? "pause.fill" : "play.fill"
            ) {
                model.toggleRun()
            }

            NotchIslandActionButton(
                title: L10n.menuSettings,
                systemImage: "gearshape"
            ) {
                openSettings()
            }
        }
    }

    // MARK: - Actions

    private func openMainWindow(selecting id: UUID? = nil) {
        if let id {
            model.selection = [id]
        }
        let window = WindowCloseInterceptor.shared.mainWindow ?? NSApp.windows.first(where: { !$0.isStatusBarWindow && !($0 is NSPanel) })
        if let window {
            window.makeKeyAndOrderFront(nil)
            if #available(macOS 14.0, *) {
                NSApp.activate()
            } else {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    private func openSettings() {
        openMainWindow()
        model.openSettingsSheet()
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
                .frame(width: 5, height: 5)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(color.opacity(0.2))
        .clipShape(Capsule())
    }
}

private struct NotchProblemRowItemView: View {
    let row: PingTableRow
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor(row.stats.status))
                    .frame(width: 6, height: 6)

                Text(row.target.host)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if !row.target.note.isEmpty {
                    Text("(\(row.target.note))")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Text(row.stats.displayMessage.isEmpty ? row.stats.status.displayName : row.stats.displayMessage)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
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

private struct NotchIslandActionButton: View {
    let title: LocalizedStringResource
    let systemImage: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(isHovered ? 1.0 : 0.85))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .padding(.horizontal, 4)
            .background(isHovered ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
