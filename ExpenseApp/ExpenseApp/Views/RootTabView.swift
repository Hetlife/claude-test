import SwiftUI

struct RootTabView: View {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @State private var isPresentingAddExpense = false

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(isPresentingAddExpense: $isPresentingAddExpense)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                TransactionsView(isPresentingAddExpense: $isPresentingAddExpense)
            }
            .tabItem { Label("Transactions", systemImage: "list.bullet") }

            NavigationStack {
                BalanceView()
            }
            .tabItem { Label("Balance", systemImage: "arrow.left.arrow.right.circle.fill") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .sheet(isPresented: $isPresentingAddExpense) {
            AddExpenseView(mode: .create)
        }
        .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
            OnboardingView()
        }
    }
}
