import SwiftUI

/// Shown once on first launch to set the "current user" smart default.
/// This never restricts entering an expense for the other person — it only
/// pre-selects the payer and device name.
struct OnboardingView: View {
    @AppStorage(AppStorageKeys.currentUser) private var currentUserRaw: String = ""
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding: Bool = false
    @State private var selection: Payer = .het

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "indianrupeesign.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Welcome")
                    .font(.largeTitle.bold())
                Text("A private, shared expense ledger for Het and Sarthak.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("WHO IS USING THIS IPHONE?")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Your name", selection: $selection) {
                    ForEach(Payer.allCases) { payer in
                        Text(payer.displayName).tag(payer)
                    }
                }
                .pickerStyle(.segmented)

                Text("You can still add expenses for the other person any time — this just sets your defaults.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                currentUserRaw = selection.rawValue
                hasCompletedOnboarding = true
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .interactiveDismissDisabled()
    }
}
