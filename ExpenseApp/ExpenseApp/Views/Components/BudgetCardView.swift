import SwiftUI

/// The Home screen hero: the first number you see when the app opens.
/// Shows budget remaining (with the total budget as a small caption) when
/// a budget is set; falls back to total spent — the original Home
/// headline — when it isn't. Either way it always shows who paid what,
/// and a tap opens the budget editor (or "Set Budget" when there isn't one).
struct BudgetCardView: View {
    let budget: Budget?
    let progress: BudgetProgress?
    let summary: BalanceSummary
    let onTap: () -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(spacing: 4) {
            if let budget, let progress {
                Text(label(for: budget))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(CurrencyFormatter.string(fromPaise: abs(progress.remainingPaise)))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(progress.isOverBudget ? Color.red : Color.green)
                    .accessibilityLabel(
                        (progress.isOverBudget ? "Over budget by " : "Budget remaining ")
                        + CurrencyFormatter.accessibleString(fromPaise: abs(progress.remainingPaise))
                    )

                Text(progress.isOverBudget ? "over budget" : "left of \(CurrencyFormatter.string(fromPaise: budget.amountPaise)) budget")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProgressView(value: min(1, max(0, Double(progress.spentPaise) / Double(max(budget.amountPaise, 1)))))
                    .tint(progress.isOverBudget ? Color.red : Color.accentColor)
                    .padding(.horizontal, 40)
                    .padding(.top, 6)
            } else {
                Text(CurrencyFormatter.string(fromPaise: summary.totalSpentPaise))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .accessibilityLabel("Total spent \(CurrencyFormatter.accessibleString(fromPaise: summary.totalSpentPaise))")
                Text("Total spent")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            paidSplitLine
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 6)

            Button(budget == nil ? "Set Budget" : "Edit Budget", action: onTap)
                .font(.footnote.weight(.semibold))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var paidSplitLine: some View {
        VStack(spacing: 2) {
            HStack(spacing: 20) {
                Text("Het paid \(CurrencyFormatter.string(fromPaise: summary.hetPaidPaise))")
                Text("Sarthak paid \(CurrencyFormatter.string(fromPaise: summary.sarthakPaidPaise))")
            }
            if summary.companyPaidPaise > 0 {
                Text("Company paid \(CurrencyFormatter.string(fromPaise: summary.companyPaidPaise))")
            }
        }
    }

    private func label(for budget: Budget) -> String {
        let range = "\(Self.dateFormatter.string(from: budget.startDate)) – \(Self.dateFormatter.string(from: budget.endDate))"
        return budget.name.isEmpty ? range : "\(budget.name) · \(range)"
    }
}
