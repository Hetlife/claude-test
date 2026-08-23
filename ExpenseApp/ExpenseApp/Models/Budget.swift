import Foundation

/// A single shared spending goal: an amount over a specific date range
/// (e.g. "₹10,000 this month" or "₹5,000, June 1–15 for a trip"). There is
/// one active budget at a time — setting a new one replaces it. Counts
/// combined spend from both people, not per-person.
struct Budget: Codable, Equatable {
    var id: UUID
    var name: String
    var amountPaise: Int64
    var startDate: Date
    var endDate: Date
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        amountPaise: Int64,
        startDate: Date,
        endDate: Date,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.amountPaise = amountPaise
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum BudgetValidationError: Error, LocalizedError, Equatable {
    case nonPositiveAmount
    case endBeforeStart

    var errorDescription: String? {
        switch self {
        case .nonPositiveAmount:
            return "Budget amount must be greater than ₹0."
        case .endBeforeStart:
            return "End date must be on or after the start date."
        }
    }
}

extension Budget {
    func validate() throws {
        guard amountPaise > 0 else { throw BudgetValidationError.nonPositiveAmount }
        let calendar = Calendar.current
        guard calendar.startOfDay(for: endDate) >= calendar.startOfDay(for: startDate) else {
            throw BudgetValidationError.endBeforeStart
        }
    }
}
