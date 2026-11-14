import AppKit
import SwiftUI
import PingCore

/// 仅给左、底、右三边绘制描边，顶部平直贴顶无描边，避免在刘海上方出现多余白线
struct NotchIslandUStroke: Shape {
    let hasPhysicalNotch: Bool
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        if !hasPhysicalNotch {
            return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: rect)
        }
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius))
        path.addArc(
            tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY),
            radius: cornerRadius
        )
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY))
        path.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius),
            radius: cornerRadius
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

/// 灵动岛 SwiftUI 视图：平时与物理刘海尺寸和底部弧度 100% 严丝合缝，点击或悬停时丝滑向外延展展开
@MainActor
public struct NotchIslandView: View {
    @ObservedObject var controller: NotchWindowController
    @ObservedObject var model: PingDeckViewModel

    private var geometry: NotchGeometry {
        controller.currentGeometry()
    }

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

    private var shapeSpring: Animation {
        if controller.isExpanded {
            // 展开动画：阻尼 0.82，温润舒展，带有 Apple 官方高级液态弹性
            return .spring(response: 0.40, dampingFraction: 0.82, blendDuration: 0.15)
        } else {
            // 收起动画：阻尼 0.88，干脆敏捷，磁吸式快速缩回物理刘海
            return .spring(response: 0.28, dampingFraction: 0.88, blendDuration: 0.10)
        }
    }

    public var body: some View {
        let isExpanded = controller.isExpanded
        let notchWidth = geometry.notchRect.width
        let notchHeight = geometry.notchRect.height
        let currentWidth = isExpanded ? geometry.expandedSize.width : notchWidth
        let currentHeight = isExpanded ? geometry.expandedSize.height : notchHeight
        let bottomRadius: CGFloat = isExpanded ? 22 : 10

        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                // 纯黑物理外壳：顶边贴齐边框，底边带平滑圆角
                UnevenRoundedRectangle(
                    topLeadingRadius: geometry.hasPhysicalNotch ? 0 : (isExpanded ? 22 : 12),
                    bottomLeadingRadius: bottomRadius,
                    bottomTrailingRadius: bottomRadius,
                    topTrailingRadius: geometry.hasPhysicalNotch ? 0 : (isExpanded ? 22 : 12),
                    style: .continuous
                )
                .fill(Color.black)
                .overlay(
                    NotchIslandUStroke(
                        hasPhysicalNotch: geometry.hasPhysicalNotch,
                        cornerRadius: bottomRadius
                    )
                    .stroke(isExpanded ? Color.white.opacity(0.18) : Color.clear, lineWidth: 1)
                )

                // 展开内容层：微延迟渐现，等外壳舒展开后再呈现，彻底消除文字被硬性裁切的生硬感
                if isExpanded {
                    expandedContent
                        .frame(width: geometry.expandedSize.width, height: geometry.expandedSize.height, alignment: .topLeading)
                        .opacity(isExpanded ? 1.0 : 0.0)
                        .scaleEffect(isExpanded ? 1.0 : 0.95, anchor: .top)
                        .animation(
                            isExpanded
                                ? .easeOut(duration: 0.24).delay(0.06)
                                : .easeIn(duration: 0.14),
                            value: isExpanded
                        )
                }
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: geometry.hasPhysicalNotch ? 0 : (isExpanded ? 22 : 12),
                    bottomLeadingRadius: bottomRadius,
                    bottomTrailingRadius: bottomRadius,
                    topTrailingRadius: geometry.hasPhysicalNotch ? 0 : (isExpanded ? 22 : 12),
                    style: .continuous
                )
            )
            .frame(width: currentWidth, height: currentHeight, alignment: .top)
            .shadow(
                color: isExpanded ? Color.black.opacity(0.62) : Color.clear,
                radius: isExpanded ? 22 : 0,
                x: 0,
                y: isExpanded ? 12 : 0
            )

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(shapeSpring, value: isExpanded)
        .preferredColorScheme(.dark)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
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
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .padding(.top, geometry.hasPhysicalNotch ? 4 : 10)
    }

    // MARK: - Header (首行：左侧 Logo，中间刘海避让，右侧图钉)

    private var headerView: some View {
        HStack(alignment: .center) {
            // 左侧：PingDeck 标识与在线绿点
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

            // 物理刘海屏幕下避让居中硬件摄像头，不放置任何文字
            if geometry.hasPhysicalNotch {
                Spacer()
                    .frame(width: max(0, geometry.notchRect.width - 120))
            }

            Spacer()

            // 右侧：图钉固定按钮
            Button(action: {
                controller.togglePin()
            }) {
                Image(systemName: controller.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(controller.isPinned ? Color.orange : Color.white.opacity(0.8))
                    .padding(5)
                    .background(controller.isPinned ? Color.orange.opacity(0.2) : Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help(controller.isPinned ? String(localized: L10n.notchIslandUnpinHelp) : String(localized: L10n.notchIslandPinHelp))
        }
        .frame(height: geometry.hasPhysicalNotch ? max(geometry.notchRect.height, 32) : 28)
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
