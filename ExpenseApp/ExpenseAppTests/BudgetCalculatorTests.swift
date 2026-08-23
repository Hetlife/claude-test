import XCTest
@testable import ExpenseApp

final class BudgetCalculatorTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func record(amountPaise: Int64, date: Date, deleted: Bool = false) -> ExpenseRecord {
        ExpenseRecord(
            amountPaise: amountPaise,
            paidBy: .het,
            paidVia: .cash,
            category: .food,
            merchantOrDescription: "Test",
            date: date,
            createdByDevice: "Test Device",
            deletedAt: deleted ? Date() : nil
        )
    }

    func test_spendWithinRange_reducesRemaining() {
        let budget = Budget(amountPaise: 5000_00, startDate: date(2026, 6, 1), endDate: date(2026, 6, 30))
        let records = [
            record(amountPaise: 1000_00, date: date(2026, 6, 5)),
            record(amountPaise: 2000_00, date: date(2026, 6, 20))
        ]
        let progress = BudgetCalculator.progress(for: budget, records: records, calendar: calendar)

        XCTAssertEqual(progress.spentPaise, 3000_00)
        XCTAssertEqual(progress.remainingPaise, 2000_00)
        XCTAssertFalse(progress.isOverBudget)
    }

    func test_spendOutsideRange_isExcluded() {
        let budget = Budget(amountPaise: 5000_00, startDate: date(2026, 6, 1), endDate: date(2026, 6, 30))
        let records = [
            record(amountPaise: 1000_00, date: date(2026, 5, 31)),
            record(amountPaise: 9999_00, date: date(2026, 7, 1))
        ]
        let progress = BudgetCalculator.progress(for: budget, records: records, calendar: calendar)

        XCTAssertEqual(progress.spentPaise, 0)
        XCTAssertEqual(progress.remainingPaise, 5000_00)
    }

    func test_boundaryDates_areInclusive() {
        let budget = Budget(amountPaise: 5000_00, startDate: date(2026, 6, 1), endDate: date(2026, 6, 30))
        let records = [
            record(amountPaise: 100_00, date: date(2026, 6, 1)),
            record(amountPaise: 200_00, date: date(2026, 6, 30))
        ]
        let progress = BudgetCalculator.progress(for: budget, records: records, calendar: calendar)

        XCTAssertEqual(progress.spentPaise, 300_00)
    }

    func test_overspend_isNegativeRemainingAndFlagged() {
        let budget = Budget(amountPaise: 1000_00, startDate: date(2026, 6, 1), endDate: date(2026, 6, 30))
        let records = [record(amountPaise: 3000_00, date: date(2026, 6, 10))]
        let progress = BudgetCalculator.progress(for: budget, records: records, calendar: calendar)

        XCTAssertEqual(progress.remainingPaise, -2000_00)
        XCTAssertTrue(progress.isOverBudget)
    }

    func test_deletedExpenses_areExcluded() {
        let budget = Budget(amountPaise: 5000_00, startDate: date(2026, 6, 1), endDate: date(2026, 6, 30))
        let records = [record(amountPaise: 4000_00, date: date(2026, 6, 10), deleted: true)]
        let progress = BudgetCalculator.progress(for: budget, records: records, calendar: calendar)

        XCTAssertEqual(progress.spentPaise, 0)
        XCTAssertEqual(progress.remainingPaise, 5000_00)
    }

    func test_noExpenses_remainingEqualsFullAmount() {
        let budget = Budget(amountPaise: 5000_00, startDate: date(2026, 6, 1), endDate: date(2026, 6, 30))
        let progress = BudgetCalculator.progress(for: budget, records: [], calendar: calendar)

        XCTAssertEqual(progress.spentPaise, 0)
        XCTAssertEqual(progress.remainingPaise, 5000_00)
        XCTAssertFalse(progress.isOverBudget)
    }

    func test_singleDayBudget_onlyCountsThatDay() {
        let budget = Budget(amountPaise: 1000_00, startDate: date(2026, 6, 15), endDate: date(2026, 6, 15))
        let records = [
            record(amountPaise: 100_00, date: date(2026, 6, 15)),
            record(amountPaise: 500_00, date: date(2026, 6, 14)),
            record(amountPaise: 500_00, date: date(2026, 6, 16))
        ]
        let progress = BudgetCalculator.progress(for: budget, records: records, calendar: calendar)

        XCTAssertEqual(progress.spentPaise, 100_00)
    }
}
