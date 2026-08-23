import Foundation

/// Result of a 50/50 balance calculation over a set of expenses.
struct BalanceSummary: Equatable {
    let totalSpentPaise: Int64
    let hetPaidPaise: Int64
    let sarthakPaidPaise: Int64
    /// Spend paid directly by the Company account. Purely informational —
    /// it never enters the 50/50 split between Het and Sarthak below.
    let companyPaidPaise: Int64
    /// `total / 2`, integer paise, floored.
    let fairSharePaise: Int64
    /// Magnitude of the outstanding balance. Zero when settled.
    let owedAmountPaise: Int64
    /// Who owes money. `nil` when settled.
    let owedBy: Payer?
    /// Who is owed money. `nil` when settled.
    let owedTo: Payer?

    var isSettled: Bool { owedAmountPaise == 0 }
}

/// Pure 50/50 shared-expense balance engine. Has no dependency on SwiftUI or
/// SwiftData — it is a plain function over `[ExpenseRecord]`, so it can be
/// unit tested in complete isolation and reused by both `BalanceView` and
/// `HomeView`.
///
/// Rule (per product spec):
///   fair share per person = total spend / 2
///   if Het paid more than fair share -> Sarthak owes Het the difference
///   if Sarthak paid more than fair share -> Het owes Sarthak the difference
///   otherwise -> settled
enum BalanceCalculator {
    static func summary(for records: [ExpenseRecord]) -> BalanceSummary {
        let active = records.filter { !$0.isDeleted }

        let hetPaid = active
            .filter { $0.paidBy == .het }
            .reduce(Int64(0)) { $0 + $1.amountPaise }
        let sarthakPaid = active
            .filter { $0.paidBy == .sarthak }
            .reduce(Int64(0)) { $0 + $1.amountPaise }
        let companyPaid = active
            .filter { $0.paidBy == .company }
            .reduce(Int64(0)) { $0 + $1.amountPaise }
        let total = hetPaid + sarthakPaid
        let fairShare = total / 2

        let hetDelta = hetPaid - fairShare
        let sarthakDelta = sarthakPaid - fairShare

        let owedBy: Payer?
        let owedTo: Payer?
        let owedAmount: Int64

        if hetDelta > 0 {
            owedBy = .sarthak
            owedTo = .het
            owedAmount = hetDelta
        } else if sarthakDelta > 0 {
            owedBy = .het
            owedTo = .sarthak
            owedAmount = sarthakDelta
        } else {
            owedBy = nil
            owedTo = nil
            owedAmount = 0
        }

        return BalanceSummary(
            totalSpentPaise: total,
            hetPaidPaise: hetPaid,
            sarthakPaidPaise: sarthakPaid,
            companyPaidPaise: companyPaid,
            fairSharePaise: fairShare,
            owedAmountPaise: owedAmount,
            owedBy: owedBy,
            owedTo: owedTo
        )
    }
}
