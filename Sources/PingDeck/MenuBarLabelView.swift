import SwiftUI
import PingCore

struct MenuBarLabelView: View {
    @ObservedObject var model: PingDeckViewModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: model.problemCount > 0 ? "network.slash" : "network")
            if model.settings.menuBar.showTextLabel {
                Text(model.menuBarTitle)
            }
        }
    }
}
