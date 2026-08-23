import Foundation

/// Who paid for an expense. Het and Sarthak are the two people who use
/// this app; Company is a third account for business expenses paid
/// directly by the company rather than personally by either of them —
/// it never contributes to the personal 50/50 balance between Het and
/// Sarthak (see `BalanceCalculator`), and always carries an `authorizedBy`
/// on the expense (see `ExpenseRecord`).
enum Payer: String, Codable, CaseIterable, Identifiable, Hashable {
    case het = "Het"
    case sarthak = "Sarthak"
    case company = "Company"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var isPerson: Bool { self != .company }

    /// The two people, for contexts where "Company" isn't a valid choice —
    /// picking your own identity, or who authorized a company expense.
    static let people: [Payer] = [.het, .sarthak]
}
