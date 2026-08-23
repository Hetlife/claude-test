import SwiftUI

/// Full-screen category picker presented from Add/Edit Expense. Kept as a
/// simple list — v1 has a fixed category set, no management UI.
struct CategoryPickerView: View {
    @Binding var selection: ExpenseCategory
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(ExpenseCategory.allCases) { category in
            Button {
                selection = category
                dismiss()
            } label: {
                HStack {
                    Image(systemName: category.sfSymbol)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    Text(category.displayName)
                        .foregroundStyle(.primary)
                    Spacer()
                    if category == selection {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .accessibilityAddTraits(category == selection ? [.isSelected] : [])
        }
        .navigationTitle("Category")
        .navigationBarTitleDisplayMode(.inline)
    }
}
