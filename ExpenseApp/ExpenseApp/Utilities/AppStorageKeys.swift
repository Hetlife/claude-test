import Foundation

/// Centralized `UserDefaults`/`@AppStorage` key names, so every read/write
/// site (views, `DeviceIdentity`, previews) agrees on the exact string.
enum AppStorageKeys {
    static let currentUser = "currentUser"
    static let deviceName = "deviceName"
    static let lastPaymentMethod = "lastPaymentMethod"
    static let lastCategory = "lastCategory"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
}
