import SwiftUI
import PingCore

/// 分组折叠目标视图
struct GroupedTargetsTableView: View {
    @EnvironmentObject private var model: PingDeckViewModel

    var body: some View {
        if model.groupedSections.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(model.groupedSections) { section in
                        GroupSectionCard(section: section)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
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

/// 分组卡片组件
struct GroupSectionCard: View {
    @EnvironmentObject private var model: PingDeckViewModel
    let section: TargetGroupSection

    private var isAllSelected: Bool {
        let ids = Set(section.rows.map(\.id))
        return !ids.isEmpty && ids.isSubset(of: model.selection)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if !section.isCollapsed {
                Divider()
                rowsContent
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: section.isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 12)

                Text(section.groupName.isEmpty ? String(localized: L10n.groupDefaultName) : section.groupName)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            // 统计胶囊
            HStack(spacing: 6) {
                // 🟢 alive
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("\(section.aliveCount)")
                        .font(.caption)
                        .monospacedDigit()
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.green.opacity(0.12)))

                // 🔴 problem
                if section.problemCount > 0 {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("\(section.problemCount)")
                            .font(.caption)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.red.opacity(0.15)))
                }

                // 总数
                Text("\(section.totalCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.secondary.opacity(0.1)))
            }

            Spacer()

            // 快捷全选/取消全选按钮
            Button {
                let ids = Set(section.rows.map(\.id))
                if isAllSelected {
                    model.selection.subtract(ids)
                } else {
                    model.selection.formUnion(ids)
                }
            } label: {
                Image(systemName: isAllSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isAllSelected ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.18)) {
                model.toggleGroupCollapse(section.groupName)
            }
        }
    }

    private var rowsContent: some View {
        VStack(spacing: 0) {
            ForEach(section.rows) { row in
                GroupedRowView(row: row)
                if row.id != section.rows.last?.id {
                    Divider()
                        .padding(.leading, 36)
                }
            }
        }
    }
}

/// 组内单行展示
struct GroupedRowView: View {
    @EnvironmentObject private var model: PingDeckViewModel
    let row: TargetRow

    private var isSelected: Bool {
        model.selection.contains(row.id)
    }

    var body: some View {
        HStack(spacing: 10) {
            // 选择框
            Button {
                if isSelected {
                    model.selection.remove(row.id)
                } else {
                    model.selection.insert(row.id)
                }
            } label: {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)

            // 颜色圆点
            if let tag = row.target.colorTag {
                Circle()
                    .fill(tag.color)
                    .frame(width: 8, height: 8)
                    .help(tag.localizedName)
            } else {
                Spacer().frame(width: 8)
            }

            // 主机与备注
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
            .frame(minWidth: 150, alignment: .leading)

            Spacer()

            // 状态
            StatusBadge(status: row.stats.status, message: row.stats.displayMessage)
                .frame(width: 90, alignment: .leading)

            // 最近延迟
            LatencyCell(value: row.stats.lastLatency)
                .frame(width: 70, alignment: .trailing)

            // 丢包率
            Text(row.stats.sent > 0 ? String(format: "%.1f%%", row.stats.lossRate * 100) : "-")
                .font(.callout)
                .monospacedDigit()
                .frame(width: 60, alignment: .trailing)

            // 启用开关
            Toggle("", isOn: Binding(
                get: { row.target.enabled },
                set: { model.setEnabled(id: row.id, enabled: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .frame(width: 50)
            .help(String(localized: row.target.enabled ? L10n.tableEnabledDisableHelp : L10n.tableEnabledEnableHelp))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if NSEvent.modifierFlags.contains(.command) {
                if isSelected {
                    model.selection.remove(row.id)
                } else {
                    model.selection.insert(row.id)
                }
            } else {
                model.selection = [row.id]
            }
        }
    }
}
