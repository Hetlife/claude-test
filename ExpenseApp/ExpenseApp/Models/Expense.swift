import Foundation
import SwiftData

/// SwiftData persistence entity. Enum-typed fields are stored as their raw
/// `String` value (rather than the enum type directly) to keep the schema
/// simple and stable across SwiftData versions; typed access is exposed via
/// computed properties. This is the *only* type that should ever be created
/// or deleted directly through a `ModelContext` — everywhere else in the app
/// works with the storage-agnostic `ExpenseRecord`.
@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var amountPaise: Int64
    var currency: String
    var paidByRaw: String
    var paidViaRaw: String
    var categoryRaw: String
    var merchantOrDescription: String
    var notes: String?
    var date: Date
    var createdAt: Date
    var updatedAt: Date
    var createdByDevice: String
    var deletedAt: Date?
    var authorizedByRaw: String?

    init(
        id: UUID,
        amountPaise: Int64,
        currency: String,
        paidBy: Payer,
        paidVia: PaymentMethod,
        category: ExpenseCategory,
        merchantOrDescription: String,
        notes: String?,
        date: Date,
        createdAt: Date,
        updatedAt: Date,
        createdByDevice: String,
        deletedAt: Date?,
        authorizedBy: Payer? = nil
    ) {
        self.id = id
        self.amountPaise = amountPaise
        self.currency = currency
        self.paidByRaw = paidBy.rawValue
        self.paidViaRaw = paidVia.rawValue
        self.categoryRaw = category.rawValue
        self.merchantOrDescription = merchantOrDescription
        self.notes = notes
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdByDevice = createdByDevice
        self.deletedAt = deletedAt
        self.authorizedByRaw = authorizedBy?.rawValue
    }

    var paidBy: Payer {
        get { Payer(rawValue: paidByRaw) ?? .het }
        set { paidByRaw = newValue.rawValue }
    }

    var paidVia: PaymentMethod {
        get { PaymentMethod(rawValue: paidViaRaw) ?? .cash }
        set { paidViaRaw = newValue.rawValue }
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var authorizedBy: Payer? {
        get { authorizedByRaw.flatMap { Payer(rawValue: $0) } }
        set { authorizedByRaw = newValue?.rawValue }
    }

    var isDeleted: Bool { deletedAt != nil }
}

extension Expense {
    convenience init(record: ExpenseRecord) {
        self.init(
            id: record.id,
            amountPaise: record.amountPaise,
            currency: record.currency,
            paidBy: record.paidBy,
            paidVia: record.paidVia,
            category: record.category,
            merchantOrDescription: record.merchantOrDescription,
            notes: record.notes,
            date: record.date,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            createdByDevice: record.createdByDevice,
            deletedAt: record.deletedAt,
            authorizedBy: record.authorizedBy
        )
    }

    /// Overwrites every field from `record`. Used when applying a sync/import
    /// merge result to an existing local entity, and when saving an edit.
    func apply(_ record: ExpenseRecord) {
        amountPaise = record.amountPaise
        currency = record.currency
        paidBy = record.paidBy
        paidVia = record.paidVia
        category = record.category
        merchantOrDescription = record.merchantOrDescription
        notes = record.notes
        date = record.date
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        createdByDevice = record.createdByDevice
        deletedAt = record.deletedAt
        authorizedBy = record.authorizedBy
    }

    func toRecord() -> ExpenseRecord {
        ExpenseRecord(
            id: id,
            amountPaise: amountPaise,
            currency: currency,
            paidBy: paidBy,
            paidVia: paidVia,
            category: category,
            merchantOrDescription: merchantOrDescription,
            notes: notes,
            date: date,
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdByDevice: createdByDevice,
            deletedAt: deletedAt,
            authorizedBy: authorizedBy
        )
    }
}
