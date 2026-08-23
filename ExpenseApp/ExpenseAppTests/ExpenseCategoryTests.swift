import XCTest
@testable import ExpenseApp

final class ExpenseCategoryTests: XCTestCase {

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func test_currentCategories_decodeAsThemselves() throws {
        let data = Data("\"Food\"".utf8)
        let category = try decoder.decode(ExpenseCategory.self, from: data)
        XCTAssertEqual(category, .food)
    }

    func test_legacyAlcohol_decodesAsCSC() throws {
        let data = Data("\"Alcohol\"".utf8)
        let category = try decoder.decode(ExpenseCategory.self, from: data)
        XCTAssertEqual(category, .csc)
    }

    func test_legacyTobacco_decodesAsCSC() throws {
        let data = Data("\"Tobacco\"".utf8)
        let category = try decoder.decode(ExpenseCategory.self, from: data)
        XCTAssertEqual(category, .csc)
    }

    func test_unknownCategory_decodesAsOther() throws {
        let data = Data("\"SomethingNew\"".utf8)
        let category = try decoder.decode(ExpenseCategory.self, from: data)
        XCTAssertEqual(category, .other)
    }

    func test_csc_encodesAsCSCNotAlcoholOrTobacco() throws {
        let data = try encoder.encode(ExpenseCategory.csc)
        let string = String(data: data, encoding: .utf8)
        XCTAssertEqual(string, "\"CSC\"")
    }

    func test_cscDisplayName_doesNotRevealAlcoholOrTobacco() {
        XCTAssertEqual(ExpenseCategory.csc.displayName, "CSC")
    }
}
