import Foundation

/// Plain, storage-agnostic representation of an expense. This is the type
/// that `BalanceCalculator`, `SyncEngine`, and `ExportImportService` operate
/// on — none of them import SwiftData or SwiftUI. `ExpenseRepository` is the
/// only place that converts between this and the persisted `Expense` model.
struct ExpenseRecord: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var amountPaise: Int64
    var currency: String
    var paidBy: Payer
    var paidVia: PaymentMethod
    var category: ExpenseCategory
    var merchantOrDescription: String
    var notes: String?
    var date: Date
    var createdAt: Date
    var updatedAt: Date
    var createdByDevice: String
    var deletedAt: Date?
    /// Who authorized this expense — only meaningful when `paidBy == .company`;
    /// always `nil` for a personal (Het/Sarthak) expense. Should be `.het` or
    /// `.sarthak`, never `.company` itself.
    var authorizedBy: Payer?

    var isDeleted: Bool { deletedAt != nil }

    init(
        id: UUID = UUID(),
        amountPaise: Int64,
        currency: String = "INR",
        paidBy: Payer,
        paidVia: PaymentMethod,
        category: ExpenseCategory,
        merchantOrDescription: String,
        notes: String? = nil,
        date: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        createdByDevice: String,
        deletedAt: Date? = nil,
        authorizedBy: Payer? = nil
    ) {
        self.id = id
        self.amountPaise = amountPaise
        self.currency = currency
        self.paidBy = paidBy
        self.paidVia = paidVia
        self.category = category
        self.merchantOrDescription = merchantOrDescription
        self.notes = notes
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdByDevice = createdByDevice
        self.deletedAt = deletedAt
        self.authorizedBy = authorizedBy
    }
}

/// Validation errors surfaced during import or malformed sync payloads.
enum ExpenseRecordValidationError: Error, LocalizedError, Equatable {
    case nonPositiveAmount
    case amountTooLarge
    case emptyDescription
    case invalidCurrency
    case invalidDate
    case invalidAuthorizedBy

    var errorDescription: String? {
        switch self {
        case .nonPositiveAmount:
            return "Amount must be greater than ₹0."
        case .amountTooLarge:
            return "Amount is unreasonably large."
        case .emptyDescription:
            return "Description cannot be empty."
        case .invalidCurrency:
            return "Currency must be INR."
        case .invalidDate:
            return "Expense has an invalid date."
        case .invalidAuthorizedBy:
            return "A company expense must be authorized by Het or Sarthak."
        }
    }
}

extension ExpenseRecord {
    /// Upper bound purely as a sanity guard against corrupt/malicious import
    /// data — ₹10 crore (1,000,000,000.00 INR) per single expense.
    static let maxAmountPaise: Int64 = 100_000_000_00

    func validate() throws {
        guard amountPaise > 0 else { throw ExpenseRecordValidationError.nonPositiveAmount }
        guard amountPaise <= Self.maxAmountPaise else { throw ExpenseRecordValidationError.amountTooLarge }
        guard !merchantOrDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ExpenseRecordValidationError.emptyDescription
        }
        guard currency == "INR" else { throw ExpenseRecordValidationError.invalidCurrency }
        let dates = [date.timeIntervalSince1970, createdAt.timeIntervalSince1970, updatedAt.timeIntervalSince1970]
        guard dates.allSatisfy({ $0.isFinite }) else { throw ExpenseRecordValidationError.invalidDate }
        if let deletedAt {
            guard deletedAt.timeIntervalSince1970.isFinite else { throw ExpenseRecordValidationError.invalidDate }
        }
        if let authorizedBy, authorizedBy == .company {
            throw ExpenseRecordValidationError.invalidAuthorizedBy
        }
    }
}
