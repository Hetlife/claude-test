import Foundation

/// v1 fixed category list per spec. Kept as a simple enum — no
/// user-defined category management in v1.
enum ExpenseCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case food = "Food"
    case transport = "Transport"
    case hotel = "Hotel"
    case shopping = "Shopping"
    case groceries = "Groceries"
    case entertainment = "Entertainment"
    case alcohol = "Alcohol"
    case tobacco = "Tobacco"
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
        case .alcohol: return "wineglass.fill"
        case .tobacco: return "smoke.fill"
        case .tickets: return "ticket.fill"
        case .business: return "briefcase.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}
