import XCTest
@testable import ExpenseApp

final class BudgetTests: XCTestCase {

    func test_validBudget_passesValidation() {
        let budget = Budget(amountPaise: 1000_00, startDate: Date(), endDate: Date().addingTimeInterval(86400))
        XCTAssertNoThrow(try budget.validate())
    }

    func test_zeroAmount_isRejected() {
        let budget = Budget(amountPaise: 0, startDate: Date(), endDate: Date())
        XCTAssertThrowsError(try budget.validate()) { error in
            XCTAssertEqual(error as? BudgetValidationError, .nonPositiveAmount)
        }
    }

    func test_endBeforeStart_isRejected() {
        let start = Date()
        let end = start.addingTimeInterval(-86400 * 3)
        let budget = Budget(amountPaise: 1000_00, startDate: start, endDate: end)
        XCTAssertThrowsError(try budget.validate()) { error in
            XCTAssertEqual(error as? BudgetValidationError, .endBeforeStart)
        }
    }

    func test_sameDayStartAndEnd_isValid() {
        let now = Date()
        let budget = Budget(amountPaise: 1000_00, startDate: now, endDate: now)
        XCTAssertNoThrow(try budget.validate())
    }
}
