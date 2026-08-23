import SwiftUI
import SwiftData

@main
struct ExpenseAppApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var store: ExpenseStore
    @StateObject private var syncManager: PeerSyncManager
    @StateObject private var budgetStore = BudgetStore()

    init() {
        let container = PersistenceController.makeAppContainer()
        modelContainer = container

        let repository = SwiftDataExpenseRepository(context: ModelContext(container))
        let store = ExpenseStore(repository: repository)
        _store = StateObject(wrappedValue: store)

        let defaults = UserDefaults.standard
        let currentUser = Payer(rawValue: defaults.string(forKey: AppStorageKeys.currentUser) ?? "")
        let deviceName = defaults.string(forKey: AppStorageKeys.deviceName).flatMap { $0.isEmpty ? nil : $0 }
            ?? DeviceIdentity.defaultDeviceName(for: currentUser)
        _syncManager = StateObject(wrappedValue: PeerSyncManager(deviceName: deviceName, repository: repository))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(syncManager)
                .environmentObject(budgetStore)
                .onChange(of: syncManager.syncStatus) { _, newValue in
                    if case .success = newValue {
                        store.refresh()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
