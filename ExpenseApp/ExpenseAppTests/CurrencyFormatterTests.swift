import XCTest
@testable import ExpenseApp

final class CurrencyFormatterTests: XCTestCase {

    func test_wholeRupeeAmount_hasNoDecimals() {
        let string = CurrencyFormatter.string(fromPaise: 1200_00)
        XCTAssertTrue(string.contains("1,200"))
        XCTAssertFalse(string.contains("."))
    }

    func test_fractionalAmount_showsTwoDecimals() {
        let string = CurrencyFormatter.string(fromPaise: 1234_50)
        XCTAssertTrue(string.contains("1,234.50"))
    }

    func test_zeroAmount_formatsWithoutCrashing() {
        let string = CurrencyFormatter.string(fromPaise: 0)
        XCTAssertTrue(string.contains("0"))
    }

    func test_accessibleString_alwaysShowsTwoDecimals() {
        XCTAssertEqual(CurrencyFormatter.accessibleString(fromPaise: 500_00), "500.00 rupees")
        XCTAssertEqual(CurrencyFormatter.accessibleString(fromPaise: 1), "0.01 rupees")
    }
}
