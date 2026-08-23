import Foundation

/// The two people who use this app. Either device can record an expense
/// paid by either person — the app never assumes the phone's owner is the payer.
enum Payer: String, Codable, CaseIterable, Identifiable, Hashable {
    case het = "Het"
    case sarthak = "Sarthak"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var other: Payer {
        switch self {
        case .het: return .sarthak
        case .sarthak: return .het
        }
    }
}
