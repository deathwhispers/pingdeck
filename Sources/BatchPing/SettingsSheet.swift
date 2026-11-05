import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject private var model: BatchPingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("设置")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("发包间隔")
                    Spacer()
                    Text(String(format: "%.1f 秒", model.settings.interval))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $model.settings.interval, in: 0.5...10, step: 0.5)
                Text("间隔越小数据越实时，CPU 与网络占用越高")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("单包超时")
                    Spacer()
                    Text(String(format: "%.1f 秒", model.settings.timeout))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $model.settings.timeout, in: 1...10, step: 0.5)
                Text("超过该时间没有收到回包，状态显示为超时")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Stepper(
                value: $model.settings.maxConcurrent,
                in: 1...64
            ) {
                HStack {
                    Text("最大并发数")
                    Spacer()
                    Text("\(model.settings.maxConcurrent)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            Text("同时运行的 ping 进程上限，建议不小于目标数量")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Stepper(
                value: $model.settings.rotationInterval,
                in: 0...300,
                step: 15
            ) {
                HStack {
                    Text("轮换周期")
                    Spacer()
                    Text(model.settings.rotationInterval == 0 ? "关闭" : "\(Int(model.settings.rotationInterval)) 秒")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            Text("目标数超过并发上限时，按该周期轮换探测，保证每个目标都被覆盖")
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack {
                Spacer()
                Button("完成") {
                    model.saveNow()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}
