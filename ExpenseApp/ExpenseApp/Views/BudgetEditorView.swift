import SwiftUI

/// Set or edit the single active budget: an amount over a specific date
/// range. Presented as a sheet from the Home budget card or Settings.
struct BudgetEditorView: View {
    @EnvironmentObject private var budgetStore: BudgetStore
    @Environment(\.dismiss) private var dismiss

    private let existingBudget: Budget?

    @State private var amountText: String
    @State private var name: String
    @State private var startDate: Date
    @State private var endDate: Date
    @FocusState private var amountFieldFocused: Bool
    @State private var showValidationError = false
    @State private var isPresentingDeleteConfirmation = false

    init(existingBudget: Budget?) {
        self.existingBudget = existingBudget
        let calendar = Calendar.current
        let now = Date()

        if let existing = existingBudget {
            _amountText = State(initialValue: Self.decimalString(fromPaise: existing.amountPaise))
            _name = State(initialValue: existing.name)
            _startDate = State(initialValue: existing.startDate)
            _endDate = State(initialValue: existing.endDate)
        } else {
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? now
            _amountText = State(initialValue: "")
            _name = State(initialValue: "")
            _startDate = State(initialValue: startOfMonth)
            _endDate = State(initialValue: endOfMonth)
        }
    }

    private var isEditingExisting: Bool { existingBudget != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("₹")
                            .font(.system(size: 30, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .focused($amountFieldFocused)
                            .accessibilityLabel("Budget amount in rupees")
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                Section {
                    TextField("Name (optional), e.g. This Month, Jaipur Trip", text: $name)
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                if isEditingExisting {
                    Section {
                        Button(role: .destructive) {
                            isPresentingDeleteConfirmation = true
                        } label: {
                            Text("Remove Budget")
                        }
                    }
                }
            }
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .alert("Couldn't Save Budget", isPresented: $showValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enter an amount greater than ₹0 and make sure the end date isn't before the start date.")
            }
            .confirmationDialog(
                "Remove this budget?",
                isPresented: $isPresentingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove Budget", role: .destructive) {
                    budgetStore.clear()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your expenses are not affected.")
            }
            .onAppear {
                if !isEditingExisting { amountFieldFocused = true }
            }
        }
    }

    private var parsedAmountPaise: Int64? {
        let normalized = amountText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "")
        guard !normalized.isEmpty, let rupees = Double(normalized), rupees > 0 else { return nil }
        let paise = (rupees * 100).rounded()
        guard paise.isFinite, paise >= 1 else { return nil }
        return Int64(paise)
    }

    private var isValid: Bool {
        guard let paise = parsedAmountPaise, paise > 0 else { return false }
        return Calendar.current.startOfDay(for: endDate) >= Calendar.current.startOfDay(for: startDate)
    }

    private func save() {
        guard let paise = parsedAmountPaise else {
            showValidationError = true
            return
        }
        var budget = existingBudget ?? Budget(amountPaise: paise, startDate: startDate, endDate: endDate)
        budget.amountPaise = paise
        budget.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        budget.startDate = startDate
        budget.endDate = endDate
        budget.updatedAt = Date()

        if budgetStore.set(budget) {
            Haptics.success()
            dismiss()
        } else {
            showValidationError = true
        }
    }

    private static func decimalString(fromPaise paise: Int64) -> String {
        let rupees = Double(paise) / 100.0
        if paise % 100 == 0 {
            return String(Int64(rupees))
        }
        return String(format: "%.2f", rupees)
    }
}
