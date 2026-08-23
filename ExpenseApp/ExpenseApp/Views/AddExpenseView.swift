import SwiftUI

enum AddExpenseMode {
    case create
    case edit(ExpenseRecord)

    var isEdit: Bool {
        if case .edit = self { return true }
        return false
    }
}

/// The most important screen in the app: a normal entry should take
/// seconds. Amount is the visual focus, the numeric keypad opens
/// immediately on create, and Save is always one tap away.
struct AddExpenseView: View {
    @EnvironmentObject private var store: ExpenseStore
    @Environment(\.dismiss) private var dismiss

    let mode: AddExpenseMode

    @State private var amountText: String
    @State private var paidBy: Payer
    @State private var paidVia: PaymentMethod
    @State private var category: ExpenseCategory
    @State private var description: String
    @State private var date: Date
    @State private var notes: String
    @FocusState private var amountFieldFocused: Bool
    @State private var showValidationError = false

    init(mode: AddExpenseMode) {
        self.mode = mode
        let defaults = UserDefaults.standard

        switch mode {
        case .create:
            let defaultPayer = Payer(rawValue: defaults.string(forKey: AppStorageKeys.currentUser) ?? "") ?? .het
            let defaultMethod = PaymentMethod(rawValue: defaults.string(forKey: AppStorageKeys.lastPaymentMethod) ?? "") ?? .online
            let defaultCategory = ExpenseCategory(rawValue: defaults.string(forKey: AppStorageKeys.lastCategory) ?? "") ?? .food
            _paidBy = State(initialValue: defaultPayer)
            _paidVia = State(initialValue: defaultMethod)
            _category = State(initialValue: defaultCategory)
            _description = State(initialValue: "")
            _date = State(initialValue: Date())
            _notes = State(initialValue: "")
            _amountText = State(initialValue: "")
        case .edit(let record):
            _paidBy = State(initialValue: record.paidBy)
            _paidVia = State(initialValue: record.paidVia)
            _category = State(initialValue: record.category)
            _description = State(initialValue: record.merchantOrDescription)
            _date = State(initialValue: record.date)
            _notes = State(initialValue: record.notes ?? "")
            _amountText = State(initialValue: Self.decimalString(fromPaise: record.amountPaise))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("₹")
                            .font(.system(size: 36, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .focused($amountFieldFocused)
                            .accessibilityLabel("Amount in rupees")
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PAID BY")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Paid by", selection: $paidBy) {
                            ForEach(Payer.allCases) { payer in
                                Text(payer.displayName).tag(payer)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("PAID VIA")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Paid via", selection: $paidVia) {
                            ForEach(PaymentMethod.allCases) { method in
                                Text(method.displayName).tag(method)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }

                Section {
                    NavigationLink {
                        CategoryPickerView(selection: $category)
                    } label: {
                        HStack {
                            Text("Category")
                            Spacer()
                            Image(systemName: category.sfSymbol)
                                .foregroundStyle(.secondary)
                            Text(category.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }

                    TextField("Description, e.g. Dinner at Westin", text: $description)
                        .accessibilityLabel("Description")

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle(mode.isEdit ? "Edit Expense" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.isEdit ? "Save" : "Add Expense") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .alert("Couldn't Save Expense", isPresented: $showValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enter an amount greater than ₹0 and a description.")
            }
            .onAppear {
                if case .create = mode {
                    amountFieldFocused = true
                }
            }
        }
    }

    private var parsedAmountPaise: Int64? {
        let normalized = amountText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "")
        guard !normalized.isEmpty, let rupees = Double(normalized), rupees > 0 else { return nil }
        let paise = (rupees * 100).rounded()
        guard paise.isFinite, paise >= 1, paise <= Double(ExpenseRecord.maxAmountPaise) else { return nil }
        return Int64(paise)
    }

    private var isValid: Bool {
        parsedAmountPaise != nil && !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        guard let paise = parsedAmountPaise,
              !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showValidationError = true
            return
        }

        let defaults = UserDefaults.standard
        defaults.set(paidVia.rawValue, forKey: AppStorageKeys.lastPaymentMethod)
        defaults.set(category.rawValue, forKey: AppStorageKeys.lastCategory)

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        let success: Bool
        switch mode {
        case .create:
            let currentUser = Payer(rawValue: defaults.string(forKey: AppStorageKeys.currentUser) ?? "")
            let deviceName = defaults.string(forKey: AppStorageKeys.deviceName)
                ?? DeviceIdentity.defaultDeviceName(for: currentUser)
            let record = ExpenseRecord(
                amountPaise: paise,
                paidBy: paidBy,
                paidVia: paidVia,
                category: category,
                merchantOrDescription: trimmedDescription,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                date: date,
                createdByDevice: deviceName
            )
            success = store.add(record)
        case .edit(let original):
            var updated = original
            updated.amountPaise = paise
            updated.paidBy = paidBy
            updated.paidVia = paidVia
            updated.category = category
            updated.merchantOrDescription = trimmedDescription
            updated.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            updated.date = date
            success = store.update(updated)
        }

        if success {
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
