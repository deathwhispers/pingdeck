import AppKit

/// 屏幕刘海与灵动岛浮窗几何计算模型
public struct NotchGeometry: Equatable, Sendable {
    /// 屏幕是否存在物理硬件刘海
    public let hasPhysicalNotch: Bool
    /// 物理刘海或虚拟药丸感应区在屏幕坐标系中的矩形
    public let notchRect: CGRect
    /// 展开状态下面板的目标尺寸
    public let expandedSize: CGSize
    /// 静息折叠态浮窗在屏幕坐标系中的位置与尺寸
    public let collapsedPanelFrame: CGRect
    /// 展开状态浮窗在屏幕坐标系中的位置与尺寸
    public let expandedPanelFrame: CGRect

    public init(
        hasPhysicalNotch: Bool,
        notchRect: CGRect,
        expandedSize: CGSize,
        collapsedPanelFrame: CGRect,
        expandedPanelFrame: CGRect
    ) {
        self.hasPhysicalNotch = hasPhysicalNotch
        self.notchRect = notchRect
        self.expandedSize = expandedSize
        self.collapsedPanelFrame = collapsedPanelFrame
        self.expandedPanelFrame = expandedPanelFrame
    }

    /// 根据屏幕尺寸、顶部安全边距及左右辅助区域计算灵动岛几何布局
    public static func calculate(
        screenFrame: CGRect,
        safeAreaTopInset: CGFloat,
        auxiliaryTopLeft: CGRect?,
        auxiliaryTopRight: CGRect?,
        expandedHeight: CGFloat = 230,
        expandedWidth: CGFloat = 420,
        showEars: Bool = false
    ) -> NotchGeometry {
        let hasPhysicalNotch: Bool
        let notchX: CGFloat
        let notchY: CGFloat
        let notchWidth: CGFloat
        let notchHeight: CGFloat

        if let leftArea = auxiliaryTopLeft,
           let rightArea = auxiliaryTopRight,
           safeAreaTopInset > 0 {
            hasPhysicalNotch = true
            notchX = leftArea.maxX
            notchWidth = rightArea.minX - leftArea.maxX
            notchHeight = max(leftArea.height, rightArea.height, safeAreaTopInset)
            notchY = screenFrame.maxY - notchHeight
        } else {
            hasPhysicalNotch = false
            notchWidth = 160
            notchHeight = 32
            notchX = screenFrame.midX - notchWidth / 2
            notchY = screenFrame.maxY - notchHeight
        }

        let resolvedExpandedWidth = max(expandedWidth, notchWidth)
        let resolvedExpandedHeight = max(expandedHeight, notchHeight)
        let expandedSize = CGSize(width: resolvedExpandedWidth, height: resolvedExpandedHeight)

        let notchCenter = notchX + notchWidth / 2
        let collapsedPanelFrame = CGRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight)
        let expandedPanelFrame = CGRect(
            x: notchCenter - expandedSize.width / 2,
            y: screenFrame.maxY - expandedSize.height,
            width: expandedSize.width,
            height: expandedSize.height
        )

        return NotchGeometry(
            hasPhysicalNotch: hasPhysicalNotch,
            notchRect: collapsedPanelFrame,
            expandedSize: expandedSize,
            collapsedPanelFrame: collapsedPanelFrame,
            expandedPanelFrame: expandedPanelFrame
        )
    }

    /// 根据 `NSScreen` 实例自适应计算灵动岛几何布局
    public static func calculate(
        for screen: NSScreen,
        expandedHeight: CGFloat = 230,
        expandedWidth: CGFloat = 420,
        showEars: Bool = false
    ) -> NotchGeometry {
        calculate(
            screenFrame: screen.frame,
            safeAreaTopInset: screen.safeAreaInsets.top,
            auxiliaryTopLeft: screen.auxiliaryTopLeftArea,
            auxiliaryTopRight: screen.auxiliaryTopRightArea,
            expandedHeight: expandedHeight,
            expandedWidth: expandedWidth,
            showEars: showEars
        )
    }
}
