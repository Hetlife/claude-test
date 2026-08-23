import SwiftUI

enum HomePeriod: String, CaseIterable, Identifiable, Hashable {
    case thisMonth = "This Month"
    case allTime = "All Time"

    var id: String { rawValue }
}

/// Answers three questions immediately: how much have we spent, who has
/// paid more, and what happened recently.
struct HomeView: View {
    @EnvironmentObject private var store: ExpenseStore
    @EnvironmentObject private var budgetStore: BudgetStore
    @Binding var isPresentingAddExpense: Bool
    @State private var period: HomePeriod = .thisMonth
    @State private var isPresentingBudgetEditor = false

    private var periodExpenses: [ExpenseRecord] {
        switch period {
        case .allTime:
            return store.activeExpenses
        case .thisMonth:
            let calendar = Calendar.current
            let now = Date()
            return store.activeExpenses.filter {
                calendar.isDate($0.date, equalTo: now, toGranularity: .month)
                && calendar.isDate($0.date, equalTo: now, toGranularity: .year)
            }
        }
    }

    private var summary: BalanceSummary { BalanceCalculator.summary(for: periodExpenses) }

    private var recent: [ExpenseRecord] {
        Array(store.activeExpenses.sorted { $0.date > $1.date }.prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Picker("Period", selection: $period) {
                    ForEach(HomePeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                VStack(spacing: 4) {
                    Text(CurrencyFormatter.string(fromPaise: summary.totalSpentPaise))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .accessibilityLabel("Total spent \(CurrencyFormatter.accessibleString(fromPaise: summary.totalSpentPaise))")
                    Text("Total spent")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 2) {
                        HStack(spacing: 20) {
                            Text("Het paid \(CurrencyFormatter.string(fromPaise: summary.hetPaidPaise))")
                            Text("Sarthak paid \(CurrencyFormatter.string(fromPaise: summary.sarthakPaidPaise))")
                        }
                        if summary.companyPaidPaise > 0 {
                            Text("Company paid \(CurrencyFormatter.string(fromPaise: summary.companyPaidPaise))")
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                }

                BudgetCardView(
                    budget: budgetStore.budget,
                    progress: budgetStore.budget.map { BudgetCalculator.progress(for: $0, records: store.activeExpenses) },
                    onTap: { isPresentingBudgetEditor = true }
                )
                .padding(.horizontal)

                BalanceCardView(summary: summary)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent")
                            .font(.headline)
                        Spacer()
                        if !store.activeExpenses.isEmpty {
                            NavigationLink {
                                TransactionsView(isPresentingAddExpense: $isPresentingAddExpense)
                            } label: {
                                Text("See All")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.horizontal)

                    if recent.isEmpty {
                        EmptyStateView(
                            systemImage: "tray",
                            title: "No expenses yet",
                            message: "Add your first expense."
                        )
                        .padding(.top, 16)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(recent) { expense in
                                NavigationLink {
                                    ExpenseDetailView(expense: expense)
                                } label: {
                                    TransactionRowView(expense: expense)
                                }
                                .buttonStyle(.plain)

                                if expense.id != recent.last?.id {
                                    Divider().padding(.leading, 60)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                }

                Button {
                    isPresentingAddExpense = true
                } label: {
                    Label("Add Expense", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.top, 4)
            }
            .padding(.vertical)
        }
        .navigationTitle("Expenses")
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddExpense = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Expense")
            }
        }
        .sheet(isPresented: $isPresentingBudgetEditor) {
            BudgetEditorView(existingBudget: budgetStore.budget)
        }
    }
}
