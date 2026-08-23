import SwiftUI

struct ExpenseDetailView: View {
    @EnvironmentObject private var store: ExpenseStore
    @Environment(\.dismiss) private var dismiss

    let expense: ExpenseRecord

    @State private var isPresentingEdit = false
    @State private var isPresentingDeleteConfirmation = false

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    /// Always read the freshest copy from the store so an edit made in this
    /// session is reflected immediately.
    private var current: ExpenseRecord {
        store.activeExpenses.first(where: { $0.id == expense.id }) ?? expense
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 4) {
                    Image(systemName: current.category.sfSymbol)
                        .font(.title)
                        .foregroundStyle(Color.accentColor)
                    Text(CurrencyFormatter.string(fromPaise: current.amountPaise))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text(current.merchantOrDescription)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            }

            Section {
                LabeledContent("Category", value: current.category.displayName)
                LabeledContent("Paid by", value: current.paidBy.displayName)
                LabeledContent("Paid via", value: current.paidVia.displayName)
                LabeledContent("Date", value: Self.dateFormatter.string(from: current.date))
            }

            if let notes = current.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }

            Section {
                Button {
                    isPresentingEdit = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    isPresentingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            Section {
                LabeledContent("Added by", value: current.createdByDevice)
                LabeledContent("Last updated", value: Self.dateFormatter.string(from: current.updatedAt))
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .navigationTitle("Expense")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingEdit) {
            AddExpenseView(mode: .edit(current))
        }
        .confirmationDialog(
            "Delete this expense?",
            isPresented: $isPresentingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Expense", role: .destructive) {
                Haptics.warning()
                store.delete(id: current.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone on this device, and the deletion will sync to the other iPhone.")
        }
    }
}
