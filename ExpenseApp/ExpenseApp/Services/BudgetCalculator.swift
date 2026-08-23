import Foundation

/// Result of comparing a `Budget` against actual spend.
struct BudgetProgress: Equatable {
    let spentPaise: Int64
    /// Positive when under budget, negative when over.
    let remainingPaise: Int64
    var isOverBudget: Bool { remainingPaise < 0 }
}

/// Pure, storage-free budget math — no SwiftUI/SwiftData dependency, same
/// shape as `BalanceCalculator` and easy to unit test. Counts every active
/// expense whose `date` falls within the budget's [startDate, endDate]
/// range, inclusive, compared at calendar-day granularity so time-of-day
/// components on either side never exclude a same-day expense.
enum BudgetCalculator {
    static func progress(for budget: Budget, records: [ExpenseRecord], calendar: Calendar = .current) -> BudgetProgress {
        let start = calendar.startOfDay(for: budget.startDate)
        let end = calendar.startOfDay(for: budget.endDate)

        let spent = records
            .filter { !$0.isDeleted }
            .filter {
                let day = calendar.startOfDay(for: $0.date)
                return day >= start && day <= end
            }
            .reduce(Int64(0)) { $0 + $1.amountPaise }

        return BudgetProgress(spentPaise: spent, remainingPaise: budget.amountPaise - spent)
    }
}
