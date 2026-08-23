import SwiftUI

/// Compact balance summary card used on Home. `BalanceView` is the full,
/// explained version of the same numbers.
struct BalanceCardView: View {
    let summary: BalanceSummary

    var body: some View {
        VStack(spacing: 6) {
            if summary.isSettled {
                Label("All settled", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Color.green)
            } else if let owedBy = summary.owedBy, let owedTo = summary.owedTo {
                Text("\(owedBy.displayName) owes \(owedTo.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.string(fromPaise: summary.owedAmountPaise))
                    .font(.title2.bold())
                    .foregroundStyle(owedBy == .het ? Color.red : Color.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}
