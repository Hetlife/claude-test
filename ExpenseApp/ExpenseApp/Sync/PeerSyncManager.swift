import Foundation
import MultipeerConnectivity

/// Drives direct, foreground, local-network sync between the two iPhones
/// using MultipeerConnectivity. There is no server involved: discovery,
/// pairing, and data exchange all happen device-to-device over Wi-Fi.
///
/// Connection must be confirmed manually on both sides (`incomingInvitation`
/// surfaces the prompt to the UI). Once connected, `syncNow()` sends this
/// device's full expense set (active + tombstoned) to the peer; incoming
/// batches are merged via the pure `SyncEngine` and written back through
/// `ExpenseRepository`.
@MainActor
final class PeerSyncManager: NSObject, ObservableObject {

    enum ConnectionState: Equatable {
        case notConnected
        case connecting
        case connected(peerName: String)
    }

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success(sent: Int, received: Int)
        case failure(String)
    }

    struct PendingInvitation {
        let peer: MCPeerID
        let respond: (Bool) -> Void
    }

    @Published private(set) var connectionState: ConnectionState = .notConnected
    @Published private(set) var discoveredPeers: [MCPeerID] = []
    @Published private(set) var syncStatus: SyncStatus = .idle
    @Published private(set) var lastSyncDate: Date?
    @Published var pendingInvitation: PendingInvitation?

    /// Bonjour service type: lowercase letters, digits, hyphens only, max 15
    /// characters. "expenseapp-sync" is exactly 15.
    private static let serviceType = "expenseapp-sync"

    private let repository: ExpenseRepository
    private let myPeerId: MCPeerID
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!

    private var connectedPeer: MCPeerID?
    private var pendingBatches: [Int: [ExpenseRecord]] = [:]
    private var expectedTotalBatches: Int?
    private var sentCountThisSync = 0
    private var receivedCountThisSync = 0

    init(deviceName: String, repository: ExpenseRepository) {
        self.repository = repository
        self.myPeerId = MCPeerID(displayName: deviceName)
        super.init()

        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: Self.serviceType)
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: Self.serviceType)

        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }

    // MARK: - Discovery & pairing

    func startHostingAndBrowsing() {
        advertiser.startAdvertisingPeer()
        discoveredPeers = []
        browser.startBrowsingForPeers()
    }

    func stopHostingAndBrowsing() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }

    func invite(peer: MCPeerID) {
        connectionState = .connecting
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 20)
    }

    func respondToPendingInvitation(accept: Bool) {
        guard let invitation = pendingInvitation else { return }
        invitation.respond(accept)
        pendingInvitation = nil
    }

    func disconnect() {
        session.disconnect()
        connectedPeer = nil
        connectionState = .notConnected
        syncStatus = .idle
    }

    // MARK: - Sync

    func syncNow() {
        guard let peer = connectedPeer else {
            syncStatus = .failure("Not connected to a device. Find and connect to the other iPhone first.")
            return
        }

        syncStatus = .syncing
        sentCountThisSync = 0
        receivedCountThisSync = 0
        pendingBatches = [:]
        expectedTotalBatches = nil

        do {
            let local = try repository.fetchAll()
            let hello = SyncMessage.hello(.init(
                deviceId: DeviceIdentity.deviceId,
                deviceName: myPeerId.displayName,
                activeRecordCount: local.filter { !$0.isDeleted }.count
            ))
            try send(hello, to: peer)

            let batches = SyncMessageCodec.batchMessages(for: local)
            for batch in batches {
                try send(batch, to: peer)
                sentCountThisSync += batch.expenseBatch?.records.count ?? 0
            }
        } catch {
            syncStatus = .failure("Sync couldn't finish. Your local expenses are safe. Try again.")
        }
    }

    private func send(_ message: SyncMessage, to peer: MCPeerID) throws {
        let data = try SyncMessageCodec.encode(message)
        try session.send(data, toPeers: [peer], with: .reliable)
    }

    private func handleReceivedData(_ data: Data, from peer: MCPeerID) {
        let message: SyncMessage
        do {
            message = try SyncMessageCodec.decode(data)
        } catch {
            syncStatus = .failure("Sync couldn't finish. Your local expenses are safe. Try again.")
            return
        }

        switch message.kind {
        case .hello:
            break
        case .syncRequest:
            break
        case .expenseBatch:
            guard let payload = message.expenseBatch else { return }
            pendingBatches[payload.batchIndex] = payload.records
            expectedTotalBatches = payload.totalBatches
            receivedCountThisSync += payload.records.count

            if pendingBatches.count >= payload.totalBatches {
                applyReceivedBatchesAndFinish(peer: peer)
            }
        case .syncComplete:
            if syncStatus == .syncing {
                finishSync()
            }
        case .error:
            syncStatus = .failure(message.error?.message ?? "The other device reported a sync error.")
        }
    }

    private func applyReceivedBatchesAndFinish(peer: MCPeerID) {
        let allRemote = pendingBatches.sorted { $0.key < $1.key }.flatMap { $0.value }
        do {
            let local = try repository.fetchAll()
            let result = SyncEngine.merge(local: local, remote: allRemote)
            try repository.applyResolved(result.changed)
            try? send(.syncComplete(.init(sentCount: sentCountThisSync, receivedCount: receivedCountThisSync)), to: peer)
            finishSync()
        } catch {
            syncStatus = .failure("Sync couldn't finish. Your local expenses are safe. Try again.")
        }
    }

    private func finishSync() {
        lastSyncDate = Date()
        syncStatus = .success(sent: sentCountThisSync, received: receivedCountThisSync)
        pendingBatches = [:]
        expectedTotalBatches = nil
    }
}

// MARK: - MCSessionDelegate

extension PeerSyncManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.connectedPeer = peerID
                self.connectionState = .connected(peerName: peerID.displayName)
            case .connecting:
                self.connectionState = .connecting
            case .notConnected:
                if self.connectedPeer == peerID {
                    self.connectedPeer = nil
                }
                self.connectionState = .notConnected
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.handleReceivedData(data, from: peerID)
        }
    }

    nonisolated func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        // Not used — sync exchanges Codable messages only.
    }

    nonisolated func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        // Not used.
    }

    nonisolated func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {
        // Not used.
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension PeerSyncManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor in
            self.pendingInvitation = PendingInvitation(peer: peerID) { accept in
                invitationHandler(accept, accept ? self.session : nil)
            }
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension PeerSyncManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            if !self.discoveredPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.discoveredPeers.removeAll { $0 == peerID }
        }
    }
}
