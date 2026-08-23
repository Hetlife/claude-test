import Foundation

/// Pure, storage-free merge algorithm shared by peer-to-peer sync and JSON
/// import. Given the local record set and an incoming remote set, it
/// resolves every UUID to a single winning record using "latest `updatedAt`
/// wins"; ties keep the local record (deterministic, per spec — avoids
/// flip-flopping if both phones happen to save at the same instant).
///
/// This function has no side effects and touches no persistence or network
/// APIs, so it is fully unit-testable and is exactly what makes repeated
/// syncs idempotent and duplicate-free: every record is keyed by UUID, never
/// appended.
enum SyncEngine {
    struct MergeResult: Equatable {
        /// The complete merged set (local ∪ remote, conflicts resolved).
        let merged: [ExpenseRecord]
        /// The subset of `merged` whose value differs from what was already
        /// in `local` — i.e. what the caller needs to write back to storage.
        let changed: [ExpenseRecord]
        /// Incoming remote records that failed validation and were dropped
        /// rather than merged.
        let rejected: [ExpenseRecord]
    }

    static func merge(local: [ExpenseRecord], remote: [ExpenseRecord]) -> MergeResult {
        var byId: [UUID: ExpenseRecord] = [:]
        for record in local {
            byId[record.id] = record
        }

        var changed: [UUID: ExpenseRecord] = [:]
        var rejected: [ExpenseRecord] = []

        for incoming in remote {
            do {
                try incoming.validate()
            } catch {
                rejected.append(incoming)
                continue
            }

            if let existing = byId[incoming.id] {
                if incoming.updatedAt > existing.updatedAt {
                    byId[incoming.id] = incoming
                    changed[incoming.id] = incoming
                }
                // Equal or older updatedAt: local record wins, nothing to do.
            } else {
                byId[incoming.id] = incoming
                changed[incoming.id] = incoming
            }
        }

        return MergeResult(
            merged: Array(byId.values),
            changed: Array(changed.values),
            rejected: rejected
        )
    }
}
