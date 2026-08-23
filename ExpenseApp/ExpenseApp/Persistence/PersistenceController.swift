import Foundation
import SwiftData

/// Owns the app's single `ModelContainer`. All expense data lives only on
/// the local device — no CloudKit container, no remote store.
enum PersistenceController {
    static let schema = Schema([Expense.self])

    /// The container used by the running app, persisted to disk.
    static func makeAppContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create persistent ModelContainer: \(error)")
        }
    }

    /// An in-memory container for unit tests and SwiftUI previews — never
    /// touches disk, always starts empty.
    static func makeInMemoryContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }
}
