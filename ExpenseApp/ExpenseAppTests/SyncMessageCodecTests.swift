import XCTest
@testable import ExpenseApp

final class SyncMessageCodecTests: XCTestCase {

    private func record(description: String = "Test") -> ExpenseRecord {
        ExpenseRecord(
            amountPaise: 100_00,
            paidBy: .het,
            paidVia: .cash,
            category: .food,
            merchantOrDescription: description,
            createdByDevice: "Het's iPhone"
        )
    }

    func test_helloMessage_roundTrips() throws {
        let message = SyncMessage.hello(.init(deviceId: "abc", deviceName: "Het's iPhone", activeRecordCount: 5))
        let data = try SyncMessageCodec.encode(message)
        let decoded = try SyncMessageCodec.decode(data)

        XCTAssertEqual(decoded.kind, .hello)
        XCTAssertEqual(decoded.hello?.deviceName, "Het's iPhone")
        XCTAssertEqual(decoded.hello?.activeRecordCount, 5)
    }

    func test_expenseBatchMessage_roundTrips() throws {
        let records = [record(description: "A"), record(description: "B")]
        let message = SyncMessage.expenseBatch(.init(batchIndex: 0, totalBatches: 1, records: records))
        let data = try SyncMessageCodec.encode(message)
        let decoded = try SyncMessageCodec.decode(data)

        XCTAssertEqual(decoded.expenseBatch?.records.count, 2)
        XCTAssertEqual(decoded.expenseBatch?.records.first?.merchantOrDescription, "A")
    }

    func test_malformedData_throwsRatherThanCrashing() {
        let garbage = Data("not json".utf8)
        XCTAssertThrowsError(try SyncMessageCodec.decode(garbage))
    }

    func test_unsupportedProtocolVersion_isRejected() throws {
        var message = SyncMessage.hello(.init(deviceId: "abc", deviceName: "X", activeRecordCount: 0))
        message.version = 999
        let data = try JSONEncoder().encode(message)

        XCTAssertThrowsError(try SyncMessageCodec.decode(data)) { error in
            XCTAssertEqual(error as? SyncTransportError, .unsupportedProtocolVersion(999))
        }
    }

    func test_batchMessages_splitsLargeSetsIntoMultipleBatches() {
        let records = (0..<450).map { record(description: "Expense \($0)") }
        let messages = SyncMessageCodec.batchMessages(for: records)

        XCTAssertEqual(messages.count, 3) // 200 + 200 + 50
        XCTAssertEqual(messages.reduce(0) { $0 + ($1.expenseBatch?.records.count ?? 0) }, 450)
        XCTAssertEqual(messages.last?.expenseBatch?.totalBatches, 3)
    }

    func test_batchMessages_emptyInput_producesSingleEmptyBatch() {
        let messages = SyncMessageCodec.batchMessages(for: [])
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages.first?.expenseBatch?.records.count, 0)
    }
}
