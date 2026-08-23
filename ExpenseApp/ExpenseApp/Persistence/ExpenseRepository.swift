import Foundation
import SwiftData

enum ExpenseRepositoryError: Error, LocalizedError {
    case notFound(UUID)

    var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Expense \(id) was not found."
        }
    }
}

/// Persistence-facing CRUD over `ExpenseRecord`. This is the only layer that
/// knows about SwiftData; everything above it (views, services, sync) works
/// with plain `ExpenseRecord` values.
protocol ExpenseRepository {
    /// All non-deleted expenses.
    func fetchActive() throws -> [ExpenseRecord]
    /// Every expense including tombstones — used for sync and export, never
    /// for display.
    func fetchAll() throws -> [ExpenseRecord]
    func fetch(id: UUID) throws -> ExpenseRecord?
    @discardableResult
    func insert(_ record: ExpenseRecord) throws -> ExpenseRecord
    @discardableResult
    func update(_ record: ExpenseRecord) throws -> ExpenseRecord
    /// Soft delete: sets `deletedAt`/`updatedAt`, never removes the row, so
    /// the deletion can propagate as a tombstone during sync.
    func softDelete(id: UUID) throws
    /// Upserts a batch of already-resolved records (e.g. the output of
    /// `SyncEngine.merge`). Does not re-run conflict resolution.
    func applyResolved(_ records: [ExpenseRecord]) throws
}

@MainActor
final class SwiftDataExpenseRepository: ExpenseRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchActive() throws -> [ExpenseRecord] {
        let descriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
            .filter { !$0.isDeleted }
            .map { $0.toRecord() }
    }

    func fetchAll() throws -> [ExpenseRecord] {
        let descriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toRecord() }
    }

    func fetch(id: UUID) throws -> ExpenseRecord? {
        try fetchEntity(id: id)?.toRecord()
    }

    @discardableResult
    func insert(_ record: ExpenseRecord) throws -> ExpenseRecord {
        let entity = Expense(record: record)
        context.insert(entity)
        try context.save()
        return entity.toRecord()
    }

    @discardableResult
    func update(_ record: ExpenseRecord) throws -> ExpenseRecord {
        guard let entity = try fetchEntity(id: record.id) else {
            throw ExpenseRepositoryError.notFound(record.id)
        }
        var updated = record
        updated.updatedAt = Date()
        entity.apply(updated)
        try context.save()
        return entity.toRecord()
    }

    func softDelete(id: UUID) throws {
        guard let entity = try fetchEntity(id: id) else {
            throw ExpenseRepositoryError.notFound(id)
        }
        let now = Date()
        entity.deletedAt = now
        entity.updatedAt = now
        try context.save()
    }

    func applyResolved(_ records: [ExpenseRecord]) throws {
        for record in records {
            if let entity = try fetchEntity(id: record.id) {
                entity.apply(record)
            } else {
                context.insert(Expense(record: record))
            }
        }
        try context.save()
    }

    private func fetchEntity(id: UUID) throws -> Expense? {
        var descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
