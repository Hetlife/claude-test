import Foundation

/// A stable per-install identifier and human-readable name for this device,
/// used to stamp `createdByDevice` on new expenses and to identify peers
/// during sync. Deliberately not `UIDevice.identifierForVendor` alone —
/// that can change if the app is reinstalled, and we want a name the user
/// can edit in Settings.
enum DeviceIdentity {
    private static let deviceIdKey = "deviceId"
    static let defaultDeviceNameKey = "deviceName"

    static var deviceId: String {
        if let existing = UserDefaults.standard.string(forKey: deviceIdKey) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: deviceIdKey)
        return newId
    }

    /// Falls back to a name derived from the chosen user identity when the
    /// person hasn't set a custom device name yet.
    static func defaultDeviceName(for user: Payer?) -> String {
        guard let user else { return "This iPhone" }
        return "\(user.displayName)'s iPhone"
    }
}
