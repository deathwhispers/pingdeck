import SwiftUI
import PingCore

extension TargetColorTag {
    public var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .gray: return .gray
        }
    }

    public var localizedName: String {
        switch self {
        case .red: return String(localized: L10n.colorRed)
        case .orange: return String(localized: L10n.colorOrange)
        case .yellow: return String(localized: L10n.colorYellow)
        case .green: return String(localized: L10n.colorGreen)
        case .blue: return String(localized: L10n.colorBlue)
        case .purple: return String(localized: L10n.colorPurple)
        case .gray: return String(localized: L10n.colorGray)
        }
    }
}
