import AppKit
import SwiftUI

/// 给 SwiftUI `Table` 安装行双击事件。
///
/// SwiftUI 没有提供行级双击回调，单元格上的 `TapGesture(count: 2)` 在 macOS
/// 的 `Table` 里并不可靠。这里把 `NSTableView.doubleAction` 接到单元格内的
/// 宿主视图上，双击时用 `clickedRow` 映射回数据行。
struct TableDoubleClickBridge: NSViewRepresentable {
    let onDoubleClick: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDoubleClick: onDoubleClick)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.install(from: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onDoubleClick = onDoubleClick
        context.coordinator.install(from: nsView)
    }

    final class Coordinator: NSObject {
        var onDoubleClick: (Int) -> Void
        /// 用关联对象把 coordinator 绑定到 NSTableView 的生命周期，避免回调目标被释放
        private static var associationKey: UInt8 = 0
        private weak var tableView: NSTableView?

        init(onDoubleClick: @escaping (Int) -> Void) {
            self.onDoubleClick = onDoubleClick
        }

        func install(from view: NSView, attempt: Int = 0) {
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let view else { return }
                guard let table = Self.findTableView(from: view) else {
                    if attempt < 3 {
                        self.install(from: view, attempt: attempt + 1)
                    }
                    return
                }
                self.tableView = table
                objc_setAssociatedObject(
                    table,
                    &Self.associationKey,
                    self,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
                table.target = self
                table.doubleAction = #selector(self.handleDoubleClick(_:))
            }
        }

        @objc private func handleDoubleClick(_ sender: NSTableView) {
            let row = sender.clickedRow
            guard row >= 0 else { return }
            onDoubleClick(row)
        }

        private static func findTableView(from view: NSView) -> NSTableView? {
            var current: NSView? = view
            while let candidate = current {
                if let table = candidate as? NSTableView {
                    return table
                }
                current = candidate.superview
            }

            // 个别 SwiftUI 版本里单元格视图不在表格的祖先链上，按位置在窗口内回退查找
            guard let root = view.window?.contentView else { return nil }
            let point = view.convert(NSPoint(x: view.bounds.midX, y: view.bounds.midY), to: nil)
            return findTableView(containing: point, in: root)
        }

        private static func findTableView(containing point: NSPoint, in root: NSView) -> NSTableView? {
            if let table = root as? NSTableView,
               table.convert(table.bounds, to: nil).contains(point) {
                return table
            }
            for subview in root.subviews {
                if let found = findTableView(containing: point, in: subview) {
                    return found
                }
            }
            return nil
        }
    }
}
