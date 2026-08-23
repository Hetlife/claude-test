import SwiftUI

/// "Device Sync" — foreground, manual, local-network sync between the two
/// iPhones. No background sync is offered or implied anywhere in this UI.
struct SyncView: View {
    @EnvironmentObject private var syncManager: PeerSyncManager
    @State private var isSearching = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(statusText)
                        .font(.headline)
                }
                .padding(.vertical, 2)

                if let lastSync = syncManager.lastSyncDate {
                    Text("Last synced \(lastSync.formatted(date: .omitted, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("Both iPhones must have the app open and be on the same Wi-Fi network. Sync happens directly between your iPhones over the local network — no internet server is involved.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if syncManager.isConnected {
                connectedSection
            } else {
                nearbyDevicesSection
            }
        }
        .navigationTitle("Device Sync")
        .alert(
            "Connect with \(syncManager.pendingInvitation?.peer.displayName ?? "this device")?",
            isPresented: pendingInvitationBinding
        ) {
            Button("Connect") { syncManager.respondToPendingInvitation(accept: true) }
            Button("Decline", role: .cancel) { syncManager.respondToPendingInvitation(accept: false) }
        } message: {
            Text("This will let \(syncManager.pendingInvitation?.peer.displayName ?? "the other device") exchange expenses directly with this iPhone over your local Wi-Fi network.")
        }
        .onDisappear {
            if isSearching {
                syncManager.stopHostingAndBrowsing()
                isSearching = false
            }
        }
        .onChange(of: syncManager.syncStatus) { _, newValue in
            switch newValue {
            case .success:
                Haptics.success()
            case .failure:
                Haptics.error()
            case .idle, .syncing:
                break
            }
        }
    }

    @ViewBuilder
    private var connectedSection: some View {
        Section {
            Button {
                syncManager.syncNow()
            } label: {
                HStack {
                    Spacer()
                    if syncManager.syncStatus == .syncing {
                        ProgressView()
                        Text("Syncing…")
                    } else {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                    Spacer()
                }
            }
            .disabled(syncManager.syncStatus == .syncing)

            Button(role: .destructive) {
                syncManager.disconnect()
            } label: {
                Text("Disconnect")
            }
        }

        switch syncManager.syncStatus {
        case .success(let sent, let received):
            Section("Last Sync") {
                LabeledContent("Records sent", value: "\(sent)")
                LabeledContent("Records received", value: "\(received)")
            }
        case .failure(let message):
            Section {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        case .idle, .syncing:
            EmptyView()
        }
    }

    @ViewBuilder
    private var nearbyDevicesSection: some View {
        Section("Nearby Devices") {
            if syncManager.discoveredPeers.isEmpty {
                HStack {
                    if isSearching {
                        ProgressView()
                    }
                    Text(isSearching ? "Looking for nearby iPhones…" : "Not searching")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(syncManager.discoveredPeers, id: \.self) { peer in
                    Button {
                        syncManager.invite(peer: peer)
                    } label: {
                        HStack {
                            Text(peer.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if syncManager.connectionState == .connecting {
                                ProgressView()
                            }
                        }
                    }
                }
            }
        }

        Section {
            Button {
                isSearching.toggle()
                if isSearching {
                    syncManager.startHostingAndBrowsing()
                } else {
                    syncManager.stopHostingAndBrowsing()
                }
            } label: {
                Text(isSearching ? "Stop Searching" : "Find Nearby Device")
            }
        }
    }

    private var pendingInvitationBinding: Binding<Bool> {
        Binding(
            get: { syncManager.pendingInvitation != nil },
            set: { if !$0 { syncManager.pendingInvitation = nil } }
        )
    }

    private var statusColor: Color {
        switch syncManager.connectionState {
        case .connected: return .green
        case .connecting: return .yellow
        case .notConnected: return .gray
        }
    }

    private var statusText: String {
        switch syncManager.connectionState {
        case .connected(let name): return "Connected to \(name)"
        case .connecting: return "Connecting…"
        case .notConnected: return "Not Connected"
        }
    }
}
