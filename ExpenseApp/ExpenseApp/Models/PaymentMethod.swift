import Foundation

/// How an expense was paid. "Online" covers any digital payment
/// (UPI, card, wallet, netbanking) — v1 does not distinguish further.
enum PaymentMethod: String, Codable, CaseIterable, Identifiable, Hashable {
    case cash = "Cash"
    case online = "Online"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .cash: return "banknote"
        case .online: return "creditcard"
        }
    }
}
