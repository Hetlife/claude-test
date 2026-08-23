import Foundation

/// The app-wide observable source of truth for the UI layer. Wraps
/// `ExpenseRepository` and republishes `ExpenseRecord` values so views never
/// talk to SwiftData directly. State is refreshed explicitly after each
/// mutation (insert/update/delete/sync/import) rather than via a live
/// query — simple and entirely adequate for two users on two devices.
@MainActor
final class ExpenseStore: ObservableObject {
    @Published private(set) var activeExpenses: [ExpenseRecord] = []
    @Published var lastErrorMessage: String?

    let repository: ExpenseRepository

    init(repository: ExpenseRepository) {
        self.repository = repository
        refresh()
    }

    func refresh() {
        do {
            activeExpenses = try repository.fetchActive()
        } catch {
            lastErrorMessage = "Couldn't load your expenses."
        }
    }

    @discardableResult
    func add(_ record: ExpenseRecord) -> Bool {
        do {
            try record.validate()
            try repository.insert(record)
            refresh()
            return true
        } catch {
            lastErrorMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't save the expense."
            return false
        }
    }

    @discardableResult
    func update(_ record: ExpenseRecord) -> Bool {
        do {
            try record.validate()
            try repository.update(record)
            refresh()
            return true
        } catch {
            lastErrorMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't save the changes."
            return false
        }
    }

    func delete(id: UUID) {
        do {
            try repository.softDelete(id: id)
            refresh()
        } catch {
            lastErrorMessage = "Couldn't delete the expense."
        }
    }

    func fetchAllIncludingDeleted() -> [ExpenseRecord] {
        (try? repository.fetchAll()) ?? []
    }
}
