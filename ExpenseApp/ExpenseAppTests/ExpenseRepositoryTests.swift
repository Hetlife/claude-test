import XCTest
import SwiftData
@testable import ExpenseApp

@MainActor
final class ExpenseRepositoryTests: XCTestCase {

    private func makeRepository() -> (SwiftDataExpenseRepository, ModelContainer) {
        let container = PersistenceController.makeInMemoryContainer()
        let repository = SwiftDataExpenseRepository(context: ModelContext(container))
        return (repository, container)
    }

    private func record(description: String = "Dinner", amountPaise: Int64 = 1200_00) -> ExpenseRecord {
        ExpenseRecord(
            amountPaise: amountPaise,
            paidBy: .het,
            paidVia: .online,
            category: .food,
            merchantOrDescription: description,
            createdByDevice: "Het's iPhone"
        )
    }

    func test_insertThenFetchActive_returnsTheRecord() throws {
        let (repo, _) = makeRepository()
        let inserted = try repo.insert(record())

        let active = try repo.fetchActive()
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.id, inserted.id)
        XCTAssertEqual(active.first?.merchantOrDescription, "Dinner")
    }

    func test_update_changesFieldsAndBumpsUpdatedAt() throws {
        let (repo, _) = makeRepository()
        let inserted = try repo.insert(record(amountPaise: 100_00))
        let originalUpdatedAt = inserted.updatedAt

        var edited = inserted
        edited.amountPaise = 999_00
        edited.merchantOrDescription = "Edited"
        Thread.sleep(forTimeInterval: 0.01)
        let result = try repo.update(edited)

        XCTAssertEqual(result.amountPaise, 999_00)
        XCTAssertEqual(result.merchantOrDescription, "Edited")
        XCTAssertGreaterThan(result.updatedAt, originalUpdatedAt)
    }

    func test_softDelete_hidesFromActiveButKeepsTombstone() throws {
        let (repo, _) = makeRepository()
        let inserted = try repo.insert(record())

        try repo.softDelete(id: inserted.id)

        let active = try repo.fetchActive()
        XCTAssertTrue(active.isEmpty)

        let all = try repo.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertTrue(all.first?.isDeleted ?? false)
    }

    func test_deleteNonexistentRecord_throwsNotFound() {
        let (repo, _) = makeRepository()
        XCTAssertThrowsError(try repo.softDelete(id: UUID()))
    }

    func test_persistenceAcrossRepositoryInstances_sameContainer() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let repoA = SwiftDataExpenseRepository(context: ModelContext(container))
        let inserted = try repoA.insert(record(description: "Persisted"))

        // A second repository backed by a fresh context on the *same*
        // container should see data committed by the first, simulating an
        // app relaunch against the same on-disk store.
        let repoB = SwiftDataExpenseRepository(context: ModelContext(container))
        let fetched = try repoB.fetch(id: inserted.id)

        XCTAssertEqual(fetched?.merchantOrDescription, "Persisted")
    }

    func test_applyResolved_upsertsNewAndExisting() throws {
        let (repo, _) = makeRepository()
        let existing = try repo.insert(record(description: "Existing"))

        var updatedExisting = existing
        updatedExisting.amountPaise = 42_00
        updatedExisting.updatedAt = Date()
        let brandNew = record(description: "Brand new")

        try repo.applyResolved([updatedExisting, brandNew])

        let all = try repo.fetchAll()
        XCTAssertEqual(all.count, 2)
        XCTAssertTrue(all.contains { $0.merchantOrDescription == "Brand new" })
        XCTAssertTrue(all.contains { $0.amountPaise == 42_00 })
    }

    func test_fetchActive_sortedNewestFirst() throws {
        let (repo, _) = makeRepository()
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var older = record(description: "Older")
        older.date = yesterday
        var newer = record(description: "Newer")
        newer.date = today

        try repo.insert(older)
        try repo.insert(newer)

        let active = try repo.fetchActive()
        XCTAssertEqual(active.first?.merchantOrDescription, "Newer")
    }
}
