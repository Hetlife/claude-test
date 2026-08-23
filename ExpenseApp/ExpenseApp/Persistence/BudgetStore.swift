import Foundation

/// Persists the single active `Budget` as JSON in `UserDefaults` — a
/// dedicated SwiftData table would be overkill for one editable record.
/// Mirrors `ExpenseStore`'s shape (an `ObservableObject` the UI reads from)
/// so views never touch `UserDefaults` directly.
@MainActor
final class BudgetStore: ObservableObject {
    @Published private(set) var budget: Budget?

    private static let key = "expenseapp.budget"

    init() {
        budget = Self.load()
    }

    @discardableResult
    func set(_ budget: Budget) -> Bool {
        do {
            try budget.validate()
            self.budget = budget
            Self.save(budget)
            return true
        } catch {
            return false
        }
    }

    func clear() {
        budget = nil
        UserDefaults.standard.removeObject(forKey: Self.key)
    }

    private static func load() -> Budget? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Budget.self, from: data)
    }

    private static func save(_ budget: Budget) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(budget) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
