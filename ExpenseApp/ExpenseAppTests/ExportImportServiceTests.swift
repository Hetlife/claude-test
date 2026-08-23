import XCTest
import SwiftData
@testable import ExpenseApp

final class ExportImportServiceTests: XCTestCase {

    private func record(
        id: UUID = UUID(),
        amountPaise: Int64 = 100_00,
        description: String = "Test",
        updatedAt: Date = Date()
    ) -> ExpenseRecord {
        ExpenseRecord(
            id: id,
            amountPaise: amountPaise,
            paidBy: .het,
            paidVia: .cash,
            category: .food,
            merchantOrDescription: description,
            updatedAt: updatedAt,
            createdByDevice: "Het's iPhone"
        )
    }

    func test_exportThenParse_roundTrips() throws {
        let records = [record(description: "A"), record(description: "B")]
        let data = try ExportImportService.exportData(records: records)
        let parsed = try ExportImportService.parseImportFile(data: data)

        XCTAssertEqual(parsed.schemaVersion, ExportImportService.currentSchemaVersion)
        XCTAssertEqual(parsed.expenses.count, 2)
    }

    func test_exportFileName_matchesExpectedPattern() {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 5
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)!

        let name = ExportImportService.exportFileName(date: date)
        XCTAssertEqual(name, "expenses_2026-03-05.json")
    }

    func test_malformedJSON_throwsMalformedFile() {
        let garbage = Data("{ this is not valid json".utf8)
        XCTAssertThrowsError(try ExportImportService.parseImportFile(data: garbage)) { error in
            XCTAssertEqual(error as? ExportImportError, .malformedFile)
        }
    }

    func test_wrongSchemaVersion_isRejected() throws {
        let export = ExpenseExport(schemaVersion: 999, exportedAt: Date(), expenses: [])
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(export)

        XCTAssertThrowsError(try ExportImportService.parseImportFile(data: data)) { error in
            XCTAssertEqual(error as? ExportImportError, .unsupportedSchemaVersion(999))
        }
    }

    @MainActor
    func test_importDuplicateUUID_updatesRatherThanDuplicates() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let repository = SwiftDataExpenseRepository(context: ModelContext(container))

        let id = UUID()
        let original = record(id: id, amountPaise: 100_00, updatedAt: Date(timeIntervalSince1970: 1000))
        try repository.insert(original)

        let updated = record(id: id, amountPaise: 500_00, updatedAt: Date(timeIntervalSince1970: 2000))
        let exportData = try ExportImportService.exportData(records: [updated])

        let result = try ExportImportService.importAndMerge(data: exportData, into: repository)

        XCTAssertEqual(result.changed.count, 1)
        let all = try repository.fetchAll()
        XCTAssertEqual(all.count, 1, "importing the same UUID again must not create a duplicate row")
        XCTAssertEqual(all.first?.amountPaise, 500_00)
    }

    @MainActor
    func test_importDoesNotOverwriteNewerLocalEdits() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let repository = SwiftDataExpenseRepository(context: ModelContext(container))

        let id = UUID()
        let newerLocal = record(id: id, amountPaise: 700_00, updatedAt: Date(timeIntervalSince1970: 5000))
        try repository.insert(newerLocal)

        let staleImport = record(id: id, amountPaise: 1_00, updatedAt: Date(timeIntervalSince1970: 1000))
        let exportData = try ExportImportService.exportData(records: [staleImport])

        try ExportImportService.importAndMerge(data: exportData, into: repository)

        let all = try repository.fetchAll()
        XCTAssertEqual(all.first?.amountPaise, 700_00, "a stale imported record must never overwrite a newer local edit")
    }

    @MainActor
    func test_importInvalidRecord_isRejectedAndDoesNotCorruptExistingData() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let repository = SwiftDataExpenseRepository(context: ModelContext(container))

        let existing = record(description: "Keep me")
        try repository.insert(existing)

        let invalid = record(amountPaise: -100, description: "Bad")
        let exportData = try ExportImportService.exportData(records: [invalid])

        let result = try ExportImportService.importAndMerge(data: exportData, into: repository)

        XCTAssertEqual(result.rejected.count, 1)
        let all = try repository.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.merchantOrDescription, "Keep me")
    }
}
