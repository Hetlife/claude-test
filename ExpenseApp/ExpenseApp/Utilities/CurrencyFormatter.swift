import Foundation

/// Formats integer paise amounts as INR currency strings. Currency is fixed
/// to INR in v1, so this always renders the ₹ symbol regardless of the
/// device's region setting.
enum CurrencyFormatter {
    static func string(fromPaise paise: Int64) -> String {
        let isWhole = paise % 100 == 0
        let rupees = Double(paise) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = isWhole ? 0 : 2
        formatter.minimumFractionDigits = isWhole ? 0 : 2
        return formatter.string(from: NSNumber(value: rupees)) ?? "₹\(rupees)"
    }

    /// A VoiceOver-friendly reading of the amount, always spelling out the
    /// decimal so paise are never silently dropped.
    static func accessibleString(fromPaise paise: Int64) -> String {
        let rupees = Double(paise) / 100.0
        return String(format: "%.2f rupees", rupees)
    }
}
