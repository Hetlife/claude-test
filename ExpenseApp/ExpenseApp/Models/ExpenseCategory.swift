import Foundation

/// v1 fixed category list per spec. Kept as a simple enum — no
/// user-defined category management in v1.
///
/// "CSC" intentionally covers what used to be separate Alcohol/Tobacco
/// categories — the label and icon are deliberately neutral so the
/// category list doesn't spell out what was bought. `init(from:)` still
/// accepts the old "Alcohol"/"Tobacco" raw values from any earlier export
/// so old backups keep importing cleanly.
enum ExpenseCategory: String, CaseIterable, Identifiable, Hashable {
    case food = "Food"
    case transport = "Transport"
    case hotel = "Hotel"
    case shopping = "Shopping"
    case groceries = "Groceries"
    case entertainment = "Entertainment"
    case csc = "CSC"
    case tickets = "Tickets"
    case business = "Business"
    case other = "Other"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .hotel: return "bed.double.fill"
        case .shopping: return "cart.fill"
        case .groceries: return "basket.fill"
        case .entertainment: return "film.fill"
        case .csc: return "shippingbox.fill"
        case .tickets: return "ticket.fill"
        case .business: return "briefcase.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

extension ExpenseCategory: Codable {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "Alcohol", "Tobacco":
            self = .csc
        default:
            self = ExpenseCategory(rawValue: raw) ?? .other
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
