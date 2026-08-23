import XCTest
@testable import ExpenseApp

final class SyncEngineTests: XCTestCase {

    private func record(
        id: UUID = UUID(),
        amountPaise: Int64 = 100_00,
        paidBy: Payer = .het,
        description: String = "Test",
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        device: String = "Het's iPhone"
    ) -> ExpenseRecord {
        ExpenseRecord(
            id: id,
            amountPaise: amountPaise,
            paidBy: paidBy,
            paidVia: .cash,
            category: .food,
            merchantOrDescription: description,
            updatedAt: updatedAt,
            createdByDevice: device,
            deletedAt: deletedAt
        )
    }

    // A. Het creates -> Sarthak receives it as new.
    func test_newRemoteRecord_isAdded() {
        let newExpense = record(description: "Dinner")
        let result = SyncEngine.merge(local: [], remote: [newExpense])

        XCTAssertEqual(result.merged.count, 1)
        XCTAssertEqual(result.changed.count, 1)
        XCTAssertEqual(result.merged.first?.id, newExpense.id)
    }

    // C. Both create different expenses offline -> merge produces the union.
    func test_bothCreateDifferentExpenses_unionIsProduced() {
        let hetExpense = record(description: "Het's coffee")
        let sarthakExpense = record(description: "Sarthak's lunch")

        let result = SyncEngine.merge(local: [hetExpense], remote: [sarthakExpense])

        XCTAssertEqual(Set(result.merged.map(\.id)), Set([hetExpense.id, sarthakExpense.id]))
        XCTAssertEqual(result.changed.map(\.id), [sarthakExpense.id])
    }

    // D. Same UUID edited on both phones -> latest updatedAt wins.
    func test_sameRecordEditedOnBothPhones_latestUpdatedAtWins() {
        let id = UUID()
        let older = record(id: id, amountPaise: 100_00, updatedAt: Date(timeIntervalSince1970: 1000))
        let newer = record(id: id, amountPaise: 250_00, updatedAt: Date(timeIntervalSince1970: 2000))

        let result = SyncEngine.merge(local: [older], remote: [newer])

        XCTAssertEqual(result.merged.count, 1)
        XCTAssertEqual(result.merged.first?.amountPaise, 250_00)
        XCTAssertEqual(result.changed.first?.amountPaise, 250_00)
    }

    func test_staleRemoteUpdate_isIgnored() {
        let id = UUID()
        let newerLocal = record(id: id, amountPaise: 250_00, updatedAt: Date(timeIntervalSince1970: 2000))
        let olderRemote = record(id: id, amountPaise: 999_00, updatedAt: Date(timeIntervalSince1970: 1000))

        let result = SyncEngine.merge(local: [newerLocal], remote: [olderRemote])

        XCTAssertEqual(result.merged.first?.amountPaise, 250_00)
        XCTAssertTrue(result.changed.isEmpty)
    }

    func test_tieOnUpdatedAt_localRecordWins() {
        let id = UUID()
        let sameInstant = Date(timeIntervalSince1970: 5000)
        let local = record(id: id, amountPaise: 111_00, updatedAt: sameInstant)
        let remote = record(id: id, amountPaise: 222_00, updatedAt: sameInstant)

        let result = SyncEngine.merge(local: [local], remote: [remote])

        XCTAssertEqual(result.merged.first?.amountPaise, 111_00)
        XCTAssertTrue(result.changed.isEmpty)
    }

    // E. Delete on one phone -> tombstone propagates and stays deleted.
    func test_deletionPropagatesAsTombstone() {
        let id = UUID()
        let active = record(id: id, updatedAt: Date(timeIntervalSince1970: 1000), deletedAt: nil)
        let tombstoned = record(id: id, updatedAt: Date(timeIntervalSince1970: 2000), deletedAt: Date(timeIntervalSince1970: 2000))

        let result = SyncEngine.merge(local: [active], remote: [tombstoned])

        XCTAssertTrue(result.merged.first?.isDeleted ?? false)
    }

    func test_tombstoneDoesNotReappearOnOlderReSync() {
        let id = UUID()
        let tombstoned = record(id: id, updatedAt: Date(timeIntervalSince1970: 2000), deletedAt: Date(timeIntervalSince1970: 2000))
        let staleUndeleted = record(id: id, updatedAt: Date(timeIntervalSince1970: 1500), deletedAt: nil)

        let result = SyncEngine.merge(local: [tombstoned], remote: [staleUndeleted])

        XCTAssertTrue(result.merged.first?.isDeleted ?? false, "an older un-deleted copy must not resurrect a tombstone")
    }

    // F. Sync twice -> no duplicates, second sync is a no-op.
    func test_repeatedSyncWithSameData_isIdempotentAndProducesNoDuplicates() {
        let expenses = [record(description: "A"), record(description: "B"), record(description: "C")]
        let first = SyncEngine.merge(local: expenses, remote: expenses)
        XCTAssertEqual(first.merged.count, 3)
        XCTAssertTrue(first.changed.isEmpty, "re-merging identical data should not report any changes")

        let second = SyncEngine.merge(local: first.merged, remote: expenses)
        XCTAssertEqual(second.merged.count, 3)
        XCTAssertTrue(second.changed.isEmpty)
    }

    func test_invalidRemoteRecords_areRejectedNotMerged() {
        let bad = record(amountPaise: -500)
        let good = record(amountPaise: 100_00)

        let result = SyncEngine.merge(local: [], remote: [bad, good])

        XCTAssertEqual(result.merged.count, 1)
        XCTAssertEqual(result.merged.first?.id, good.id)
        XCTAssertEqual(result.rejected.count, 1)
        XCTAssertEqual(result.rejected.first?.id, bad.id)
    }

    func test_emptyRemoteBatch_isNoOp() {
        let existing = [record(description: "Already here")]
        let result = SyncEngine.merge(local: existing, remote: [])

        XCTAssertEqual(result.merged.count, 1)
        XCTAssertTrue(result.changed.isEmpty)
        XCTAssertTrue(result.rejected.isEmpty)
    }
}
