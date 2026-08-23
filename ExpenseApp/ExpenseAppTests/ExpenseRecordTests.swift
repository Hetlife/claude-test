import XCTest
@testable import ExpenseApp

final class ExpenseRecordTests: XCTestCase {

    private func record(amountPaise: Int64 = 100_00, description: String = "Test") -> ExpenseRecord {
        ExpenseRecord(
            amountPaise: amountPaise,
            paidBy: .het,
            paidVia: .cash,
            category: .food,
            merchantOrDescription: description,
            createdByDevice: "Het's iPhone"
        )
    }

    func test_validRecord_passesValidation() {
        XCTAssertNoThrow(try record().validate())
    }

    func test_zeroAmount_isRejected() {
        XCTAssertThrowsError(try record(amountPaise: 0).validate()) { error in
            XCTAssertEqual(error as? ExpenseRecordValidationError, .nonPositiveAmount)
        }
    }

    func test_negativeAmount_isRejected() {
        XCTAssertThrowsError(try record(amountPaise: -1).validate()) { error in
            XCTAssertEqual(error as? ExpenseRecordValidationError, .nonPositiveAmount)
        }
    }

    func test_absurdlyLargeAmount_isRejected() {
        XCTAssertThrowsError(try record(amountPaise: ExpenseRecord.maxAmountPaise + 1).validate()) { error in
            XCTAssertEqual(error as? ExpenseRecordValidationError, .amountTooLarge)
        }
    }

    func test_amountAtMaxBoundary_isAccepted() {
        XCTAssertNoThrow(try record(amountPaise: ExpenseRecord.maxAmountPaise).validate())
    }

    func test_emptyDescription_isRejected() {
        XCTAssertThrowsError(try record(description: "   ").validate()) { error in
            XCTAssertEqual(error as? ExpenseRecordValidationError, .emptyDescription)
        }
    }

    func test_nonINRCurrency_isRejected() {
        var expense = record()
        expense.currency = "USD"
        XCTAssertThrowsError(try expense.validate()) { error in
            XCTAssertEqual(error as? ExpenseRecordValidationError, .invalidCurrency)
        }
    }

    func test_nonFiniteDate_isRejected() {
        var expense = record()
        expense.date = Date(timeIntervalSince1970: .nan)
        XCTAssertThrowsError(try expense.validate()) { error in
            XCTAssertEqual(error as? ExpenseRecordValidationError, .invalidDate)
        }
    }

    func test_isDeleted_reflectsDeletedAt() {
        var expense = record()
        XCTAssertFalse(expense.isDeleted)
        expense.deletedAt = Date()
        XCTAssertTrue(expense.isDeleted)
    }
}
