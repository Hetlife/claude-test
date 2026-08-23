import SwiftUI

/// The exceptionally clear balance screen: who owes whom, and why.
struct BalanceView: View {
    @EnvironmentObject private var store: ExpenseStore

    private var summary: BalanceSummary { BalanceCalculator.summary(for: store.activeExpenses) }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if store.activeExpenses.isEmpty {
                    EmptyStateView(
                        systemImage: "checkmark.circle",
                        title: "You're all settled.",
                        message: "Add an expense to start tracking the balance."
                    )
                    .padding(.top, 60)
                } else {
                    VStack(spacing: 8) {
                        if summary.isSettled {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.green)
                            Text("All settled")
                                .font(.largeTitle.bold())
                        } else if let owedBy = summary.owedBy, let owedTo = summary.owedTo {
                            Text("\(owedBy.displayName) owes \(owedTo.displayName)")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text(CurrencyFormatter.string(fromPaise: summary.owedAmountPaise))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(owedBy == .het ? Color.red : Color.green)
                        }

                        Text("Based on 50/50 sharing of all current expenses.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    .accessibilityElement(children: .combine)

                    VStack(spacing: 0) {
                        StatRow(title: "Total spent", value: CurrencyFormatter.string(fromPaise: summary.totalSpentPaise))
                        Divider().padding(.leading)
                        StatRow(title: "Het paid", value: CurrencyFormatter.string(fromPaise: summary.hetPaidPaise))
                        Divider().padding(.leading)
                        StatRow(title: "Sarthak paid", value: CurrencyFormatter.string(fromPaise: summary.sarthakPaidPaise))
                        Divider().padding(.leading)
                        StatRow(title: "Fair share (each)", value: CurrencyFormatter.string(fromPaise: summary.fairSharePaise))
                        if summary.companyPaidPaise > 0 {
                            Divider().padding(.leading)
                            StatRow(title: "Company paid (not split)", value: CurrencyFormatter.string(fromPaise: summary.companyPaidPaise))
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Balance")
        .background(Color(.systemGroupedBackground))
    }
}

private struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
