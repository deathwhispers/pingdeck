import SwiftUI
import PingCore

/// 顶部颜色过滤胶囊栏与视图切换栏
struct ColorFilterBar: View {
    @EnvironmentObject private var model: PingDeckViewModel

    var body: some View {
        HStack(spacing: 8) {
            // "全部" 过滤胶囊
            allFilterPill

            // 各颜色标签过滤胶囊
            ForEach(TargetColorTag.allCases, id: \.self) { color in
                let count = model.colorTagCounts[color] ?? 0
                if count > 0 || model.selectedColorFilter == color {
                    colorFilterPill(color: color, count: count)
                }
            }

            Spacer()

            if model.isGroupedView {
                Button {
                    model.expandAllGroups()
                } label: {
                    Label(String(localized: L10n.expandAllGroups), systemImage: "chevron.down.2")
                }
                .buttonStyle(.plain)
                .font(.caption)
                .help(String(localized: L10n.expandAllGroups))

                Button {
                    model.collapseAllGroups()
                } label: {
                    Label(String(localized: L10n.collapseAllGroups), systemImage: "chevron.up.2")
                }
                .buttonStyle(.plain)
                .font(.caption)
                .help(String(localized: L10n.collapseAllGroups))

                Divider().frame(height: 14)
            }

            Picker("", selection: $model.isGroupedView) {
                Label(String(localized: L10n.viewModeFlat), systemImage: "rectangle.grid.1x2")
                    .tag(false)
                Label(String(localized: L10n.viewModeGrouped), systemImage: "square.stack.3d.up")
                    .tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var allFilterPill: some View {
        let isSelected = model.selectedColorFilter == nil
        return Button {
            model.selectedColorFilter = nil
        } label: {
            HStack(spacing: 4) {
                Text(L10n.filterAllTags)
                Text("\(model.targets.count)")
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.white.opacity(0.9) : Color.secondary)
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func colorFilterPill(color: TargetColorTag, count: Int) -> some View {
        let isSelected = model.selectedColorFilter == color
        return Button {
            if model.selectedColorFilter == color {
                model.selectedColorFilter = nil
            } else {
                model.selectedColorFilter = color
            }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(color.color)
                    .frame(width: 8, height: 8)
                Text("\(count)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(
                        isSelected
                            ? (color == .yellow ? Color.black.opacity(0.85) : Color.white.opacity(0.9))
                            : Color.secondary
                    )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(isSelected ? color.color : Color.secondary.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : color.color.opacity(0.3), lineWidth: 1)
            )
            .foregroundStyle(
                isSelected
                    ? (color == .yellow ? Color.black : Color.white)
                    : Color.primary
            )
        }
        .buttonStyle(.plain)
        .help(color.localizedName)
    }
}
