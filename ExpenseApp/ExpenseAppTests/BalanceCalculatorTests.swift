import XCTest
@testable import ExpenseApp

final class BalanceCalculatorTests: XCTestCase {

    private func record(
        amountPaise: Int64,
        paidBy: Payer,
        deleted: Bool = false
    ) -> ExpenseRecord {
        ExpenseRecord(
            amountPaise: amountPaise,
            paidBy: paidBy,
            paidVia: .online,
            category: .food,
            merchantOrDescription: "Test",
            createdByDevice: "Test Device",
            deletedAt: deleted ? Date() : nil
        )
    }

    func test_hetPaysThousand_sarthakOwesFiveHundred() {
        let records = [record(amountPaise: 1000_00, paidBy: .het)]
        let summary = BalanceCalculator.summary(for: records)

        XCTAssertEqual(summary.owedBy, .sarthak)
        XCTAssertEqual(summary.owedTo, .het)
        XCTAssertEqual(summary.owedAmountPaise, 500_00)
        XCTAssertFalse(summary.isSettled)
    }

    func test_sarthakPaysThousand_hetOwesFiveHundred() {
        let records = [record(amountPaise: 1000_00, paidBy: .sarthak)]
        let summary = BalanceCalculator.summary(for: records)

        XCTAssertEqual(summary.owedBy, .het)
        XCTAssertEqual(summary.owedTo, .sarthak)
        XCTAssertEqual(summary.owedAmountPaise, 500_00)
    }

    func test_bothPayEqualAmounts_settled() {
        let records = [
            record(amountPaise: 1000_00, paidBy: .het),
            record(amountPaise: 1000_00, paidBy: .sarthak)
        ]
        let summary = BalanceCalculator.summary(for: records)

        XCTAssertTrue(summary.isSettled)
        XCTAssertNil(summary.owedBy)
        XCTAssertNil(summary.owedTo)
        XCTAssertEqual(summary.owedAmountPaise, 0)
    }

    func test_mixedTransactions() {
        let records = [
            record(amountPaise: 700_00, paidBy: .het),
            record(amountPaise: 300_00, paidBy: .sarthak),
            record(amountPaise: 200_00, paidBy: .sarthak)
        ]
        // Het paid 700, Sarthak paid 500, total 1200, fair share 600 each.
        // Het paid 100 more than fair share -> Sarthak owes Het 100.
        let summary = BalanceCalculator.summary(for: records)

        XCTAssertEqual(summary.hetPaidPaise, 700_00)
        XCTAssertEqual(summary.sarthakPaidPaise, 500_00)
        XCTAssertEqual(summary.totalSpentPaise, 1200_00)
        XCTAssertEqual(summary.fairSharePaise, 600_00)
        XCTAssertEqual(summary.owedBy, .sarthak)
        XCTAssertEqual(summary.owedAmountPaise, 100_00)
    }

    func test_oddTotalInPaise_roundsDeterministically() {
        // Het paid 101 paise, Sarthak paid 100 paise. Total 201, fair share
        // 100 (integer division floors). Het's delta = 1, Sarthak's = 0, so
        // Sarthak owes Het exactly 1 paise.
        let records = [
            record(amountPaise: 101, paidBy: .het),
            record(amountPaise: 100, paidBy: .sarthak)
        ]
        let summary = BalanceCalculator.summary(for: records)

        XCTAssertEqual(summary.owedBy, .sarthak)
        XCTAssertEqual(summary.owedTo, .het)
        XCTAssertEqual(summary.owedAmountPaise, 1)
    }

    func test_deletedExpensesExcludedFromBalance() {
        let records = [
            record(amountPaise: 1000_00, paidBy: .het),
            record(amountPaise: 5000_00, paidBy: .sarthak, deleted: true)
        ]
        let summary = BalanceCalculator.summary(for: records)

        // The deleted Sarthak expense must not count.
        XCTAssertEqual(summary.totalSpentPaise, 1000_00)
        XCTAssertEqual(summary.owedBy, .sarthak)
        XCTAssertEqual(summary.owedAmountPaise, 500_00)
    }

    func test_noExpenses_settledWithZeroTotals() {
        let summary = BalanceCalculator.summary(for: [])

        XCTAssertTrue(summary.isSettled)
        XCTAssertEqual(summary.totalSpentPaise, 0)
        XCTAssertEqual(summary.fairSharePaise, 0)
    }

    func test_largeAmounts_doNotOverflow() {
        let records = [
            record(amountPaise: 50_000_000_00, paidBy: .het),
            record(amountPaise: 50_000_000_00, paidBy: .sarthak)
        ]
        let summary = BalanceCalculator.summary(for: records)

        XCTAssertTrue(summary.isSettled)
        XCTAssertEqual(summary.totalSpentPaise, 100_000_000_00)
    }

    func test_companyPaidExpense_excludedFromFiftyFiftySplit() {
        let records = [
            record(amountPaise: 1000_00, paidBy: .het),
            record(amountPaise: 1000_00, paidBy: .sarthak),
            record(amountPaise: 9999_00, paidBy: .company)
        ]
        let summary = BalanceCalculator.summary(for: records)

        // The company amount must not affect who owes whom, or the total.
        XCTAssertTrue(summary.isSettled)
        XCTAssertEqual(summary.totalSpentPaise, 2000_00)
        XCTAssertEqual(summary.companyPaidPaise, 9999_00)
    }

    func test_onlyCompanyExpenses_settledWithZeroPersonalTotal() {
        let records = [record(amountPaise: 5000_00, paidBy: .company)]
        let summary = BalanceCalculator.summary(for: records)

        XCTAssertTrue(summary.isSettled)
        XCTAssertEqual(summary.totalSpentPaise, 0)
        XCTAssertEqual(summary.companyPaidPaise, 5000_00)
    }

    func test_deletedCompanyExpense_excludedFromCompanyTotal() {
        let records = [record(amountPaise: 5000_00, paidBy: .company, deleted: true)]
        let summary = BalanceCalculator.summary(for: records)

        XCTAssertEqual(summary.companyPaidPaise, 0)
    }
}
