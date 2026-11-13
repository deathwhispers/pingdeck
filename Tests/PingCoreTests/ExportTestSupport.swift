import PingCore

enum TestExportLabels {
    static let chinese = ExportLabels(
        columnTitles: [
            "目标", "备注", "分组", "标签", "状态", "最新延迟(ms)", "平均延迟(ms)",
            "最小延迟(ms)", "最大延迟(ms)", "丢包率(%)", "最后响应时间",
        ],
        statusName: { status in
            switch status {
            case .idle: return "未开始"
            case .pending: return "排队中"
            case .running: return "探测中"
            case .alive: return "正常"
            case .timeout: return "超时"
            case .unreachable: return "不可达"
            case .disabled: return "已停用"
            case .error: return "错误"
            }
        },
        summary: { "目标 \($0.targets) · 正常 \($0.alive) · 异常 \($0.problems) · 累计发包 \($0.totalSent)" },
        markdownTitle: "PingDeck 导出结果",
        exportedAtLabel: "导出时间"
    )

    static let english = ExportLabels(
        columnTitles: [
            "Target", "Note", "Group", "Tag", "Status", "Last (ms)", "Average (ms)",
            "Min (ms)", "Max (ms)", "Loss (%)", "Last Response",
        ],
        statusName: { status in
            switch status {
            case .idle: return "Idle"
            case .pending: return "Queued"
            case .running: return "Probing"
            case .alive: return "Alive"
            case .timeout: return "Timeout"
            case .unreachable: return "Unreachable"
            case .disabled: return "Disabled"
            case .error: return "Error"
            }
        },
        summary: { "Targets \($0.targets) · Alive \($0.alive) · Problems \($0.problems) · Sent \($0.totalSent)" },
        markdownTitle: "PingDeck Export",
        exportedAtLabel: "Exported at"
    )
}
