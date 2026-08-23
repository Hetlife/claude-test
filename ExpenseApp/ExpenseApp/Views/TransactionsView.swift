import SwiftUI

/// Chronological, searchable, filterable expense list — newest first,
/// grouped by day.
struct TransactionsView: View {
    @EnvironmentObject private var store: ExpenseStore
    @Binding var isPresentingAddExpense: Bool

    @State private var searchText = ""
    @State private var payerFilter: Payer?
    @State private var methodFilter: PaymentMethod?
    @State private var categoryFilter: ExpenseCategory?
    @State private var pendingDeleteId: UUID?
    @State private var editingExpense: ExpenseRecord?

    private var hasActiveFilter: Bool {
        payerFilter != nil || methodFilter != nil || categoryFilter != nil || !searchText.isEmpty
    }

    private var filtered: [ExpenseRecord] {
        store.activeExpenses.filter { expense in
            if let payerFilter, expense.paidBy != payerFilter { return false }
            if let methodFilter, expense.paidVia != methodFilter { return false }
            if let categoryFilter, expense.category != categoryFilter { return false }
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !query.isEmpty {
                let lowered = query.lowercased()
                let matchesDescription = expense.merchantOrDescription.lowercased().contains(lowered)
                let matchesNotes = expense.notes?.lowercased().contains(lowered) ?? false
                if !matchesDescription && !matchesNotes { return false }
            }
            return true
        }
    }

    private var groupedByDay: [(day: Date, expenses: [ExpenseRecord])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in
            (day: day, expenses: groups[day]!.sorted { $0.date == $1.date ? $0.createdAt > $1.createdAt : $0.date > $1.date })
        }
    }

    var body: some View {
        List {
            if filtered.isEmpty {
                EmptyStateView(
                    systemImage: hasActiveFilter ? "magnifyingglass" : "tray",
                    title: hasActiveFilter ? "Nothing here yet." : "Nothing here yet.",
                    message: hasActiveFilter ? "Try a different search or filter." : "Add your first expense."
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedByDay, id: \.day) { group in
                    Section(sectionTitle(for: group.day)) {
                        ForEach(group.expenses) { expense in
                            NavigationLink {
                                ExpenseDetailView(expense: expense)
                            } label: {
                                TransactionRowView(expense: expense)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    pendingDeleteId = expense.id
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    editingExpense = expense
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search description or notes")
        .navigationTitle("Transactions")
        .safeAreaInset(edge: .top) { filterChips }
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
        .confirmationDialog(
            "Delete this expense?",
            isPresented: deleteConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button("Delete Expense", role: .destructive) {
                if let id = pendingDeleteId {
                    Haptics.warning()
                    store.delete(id: id)
                }
                pendingDeleteId = nil
            }
            Button("Cancel", role: .cancel) { pendingDeleteId = nil }
        }
        .sheet(item: $editingExpense) { expense in
            AddExpenseView(mode: .edit(expense))
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(get: { pendingDeleteId != nil }, set: { if !$0 { pendingDeleteId = nil } })
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: payerFilter == nil && methodFilter == nil) {
                    payerFilter = nil
                    methodFilter = nil
                }
                FilterChip(title: "Het", isSelected: payerFilter == .het) {
                    payerFilter = (payerFilter == .het) ? nil : .het
                }
                FilterChip(title: "Sarthak", isSelected: payerFilter == .sarthak) {
                    payerFilter = (payerFilter == .sarthak) ? nil : .sarthak
                }
                FilterChip(title: "Cash", isSelected: methodFilter == .cash) {
                    methodFilter = (methodFilter == .cash) ? nil : .cash
                }
                FilterChip(title: "Online", isSelected: methodFilter == .online) {
                    methodFilter = (methodFilter == .online) ? nil : .online
                }

                Menu {
                    Button("All Categories") { categoryFilter = nil }
                    Divider()
                    ForEach(ExpenseCategory.allCases) { category in
                        Button {
                            categoryFilter = category
                        } label: {
                            Label(category.displayName, systemImage: category.sfSymbol)
                        }
                    }
                } label: {
                    FilterChip(
                        title: categoryFilter?.displayName ?? "Category",
                        isSelected: categoryFilter != nil,
                        systemImage: "slider.horizontal.3"
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private func sectionTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: day)
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var systemImage: String?
    var action: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) { label }
        } else {
            label
        }
    }

    private var label: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
        }
        .font(.subheadline.weight(isSelected ? .semibold : .regular))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor : Color(.tertiarySystemFill))
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .clipShape(Capsule())
    }
}
