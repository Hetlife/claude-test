import SwiftUI

/// Home screen budget summary — shown right when the app opens, per the
/// product request. Tapping it (or "Set Budget"/"Edit") opens the editor.
struct BudgetCardView: View {
    let budget: Budget?
    let progress: BudgetProgress?
    let onTap: () -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let budget, let progress {
                HStack {
                    Text(label(for: budget))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Button("Edit", action: onTap)
                        .font(.caption.weight(.semibold))
                }

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(CurrencyFormatter.string(fromPaise: abs(progress.remainingPaise)))
                            .font(.title2.bold())
                            .foregroundStyle(progress.isOverBudget ? Color.red : Color.green)
                        Text(progress.isOverBudget ? "over budget" : "left")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Spent")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(CurrencyFormatter.string(fromPaise: progress.spentPaise))
                            .font(.subheadline.weight(.semibold))
                    }
                }

                ProgressView(value: min(1, max(0, Double(progress.spentPaise) / Double(max(budget.amountPaise, 1)))))
                    .tint(progress.isOverBudget ? Color.red : Color.accentColor)
            } else {
                HStack {
                    Text("No budget set")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Set Budget", action: onTap)
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private func label(for budget: Budget) -> String {
        let range = "\(Self.dateFormatter.string(from: budget.startDate)) – \(Self.dateFormatter.string(from: budget.endDate))"
        return budget.name.isEmpty ? range : "\(budget.name) · \(range)"
    }
}
