import Foundation

/// Versioned, `Codable` wire protocol exchanged between the two phones over
/// a `MultipeerConnectivity` session. Kept as one envelope type with a
/// `kind` discriminator and one optional payload per kind (rather than a
/// Swift enum with associated values) so the JSON shape is explicit and
/// stable, independent of Swift's enum-Codable synthesis.
struct SyncMessage: Codable {
    enum Kind: String, Codable, Equatable {
        case hello
        case syncRequest
        case expenseBatch
        case syncComplete
        case error
    }

    struct HelloPayload: Codable, Equatable {
        let deviceId: String
        let deviceName: String
        let activeRecordCount: Int
    }

    struct SyncRequestPayload: Codable, Equatable {
        let deviceId: String
    }

    struct ExpenseBatchPayload: Codable, Equatable {
        let batchIndex: Int
        let totalBatches: Int
        let records: [ExpenseRecord]
    }

    struct SyncCompletePayload: Codable, Equatable {
        let sentCount: Int
        let receivedCount: Int
    }

    struct ErrorPayload: Codable, Equatable {
        let message: String
    }

    static let protocolVersion = 1

    var version: Int = SyncMessage.protocolVersion
    var kind: Kind
    var hello: HelloPayload?
    var syncRequest: SyncRequestPayload?
    var expenseBatch: ExpenseBatchPayload?
    var syncComplete: SyncCompletePayload?
    var error: ErrorPayload?

    static func hello(_ payload: HelloPayload) -> SyncMessage {
        SyncMessage(kind: .hello, hello: payload)
    }

    static func syncRequest(_ payload: SyncRequestPayload) -> SyncMessage {
        SyncMessage(kind: .syncRequest, syncRequest: payload)
    }

    static func expenseBatch(_ payload: ExpenseBatchPayload) -> SyncMessage {
        SyncMessage(kind: .expenseBatch, expenseBatch: payload)
    }

    static func syncComplete(_ payload: SyncCompletePayload) -> SyncMessage {
        SyncMessage(kind: .syncComplete, syncComplete: payload)
    }

    static func error(_ message: String) -> SyncMessage {
        SyncMessage(kind: .error, error: ErrorPayload(message: message))
    }
}

enum SyncMessageCodec {
    /// Maximum single-message payload size the app will attempt to send in
    /// one `MCSession` write — batches are split to stay under this so a
    /// large ledger can't produce an oversized payload the peer rejects.
    static let maxRecordsPerBatch = 200

    static func encode(_ message: SyncMessage) throws -> Data {
        try JSONEncoder.syncEncoder.encode(message)
    }

    static func decode(_ data: Data) throws -> SyncMessage {
        let message = try JSONDecoder.syncDecoder.decode(SyncMessage.self, from: data)
        guard message.version == SyncMessage.protocolVersion else {
            throw SyncTransportError.unsupportedProtocolVersion(message.version)
        }
        return message
    }

    /// Splits a full record set into ordered batch messages.
    static func batchMessages(for records: [ExpenseRecord]) -> [SyncMessage] {
        if records.isEmpty {
            return [.expenseBatch(.init(batchIndex: 0, totalBatches: 1, records: []))]
        }
        let chunks = stride(from: 0, to: records.count, by: maxRecordsPerBatch).map {
            Array(records[$0..<min($0 + maxRecordsPerBatch, records.count)])
        }
        let total = chunks.count
        return chunks.enumerated().map { index, chunk in
            .expenseBatch(.init(batchIndex: index, totalBatches: total, records: chunk))
        }
    }
}

enum SyncTransportError: Error, LocalizedError, Equatable {
    case unsupportedProtocolVersion(Int)
    case malformedMessage
    case oversizedPayload

    var errorDescription: String? {
        switch self {
        case .unsupportedProtocolVersion(let version):
            return "Received a sync message using an unsupported protocol version (\(version))."
        case .malformedMessage:
            return "Received a sync message that couldn't be understood."
        case .oversizedPayload:
            return "Received a sync message that was too large to process."
        }
    }
}

private extension JSONEncoder {
    static let syncEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

private extension JSONDecoder {
    static let syncDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
