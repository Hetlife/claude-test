import SwiftUI

/// Compact transaction row: category icon, description, payer/method
/// metadata, right-aligned amount. No IDs or raw metadata shown.
struct TransactionRowView: View {
    let expense: ExpenseRecord

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.sfSymbol)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.merchantOrDescription)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(expense.paidBy.displayName) · \(expense.paidVia.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.string(fromPaise: expense.amountPaise))
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(Self.dateFormatter.string(from: expense.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(expense.merchantOrDescription), \(expense.category.displayName), "
            + "paid by \(expense.paidBy.displayName), \(expense.paidVia.displayName), "
            + "\(CurrencyFormatter.accessibleString(fromPaise: expense.amountPaise)), "
            + Self.dateFormatter.string(from: expense.date)
        )
    }
}
