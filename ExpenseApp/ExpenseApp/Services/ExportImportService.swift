import Foundation

/// The on-disk JSON shape for a backup/export file.
struct ExpenseExport: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let expenses: [ExpenseRecord]
}

enum ExportImportError: Error, LocalizedError, Equatable {
    case malformedFile
    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case .malformedFile:
            return "This file doesn't look like a valid expense backup."
        case .unsupportedSchemaVersion(let version):
            return "This backup was made with a newer app version (schema \(version)) and can't be imported here."
        }
    }
}

/// JSON export/import, doubling as the app's manual backup mechanism.
/// Import is never a blind overwrite: it feeds the imported records through
/// the same `SyncEngine.merge` used for peer-to-peer sync, so an import
/// behaves exactly like syncing with a "phantom peer" — newer local data
/// always wins, duplicate UUIDs never create duplicate rows, and existing
/// data is preserved.
enum ExportImportService {
    static let currentSchemaVersion = 1

    static func exportFileName(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return "expenses_\(formatter.string(from: date)).json"
    }

    static func exportData(records: [ExpenseRecord], exportedAt: Date = Date()) throws -> Data {
        let export = ExpenseExport(schemaVersion: currentSchemaVersion, exportedAt: exportedAt, expenses: records)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(export)
    }

    /// Decodes and schema-validates a file without writing anything.
    static func parseImportFile(data: Data) throws -> ExpenseExport {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export: ExpenseExport
        do {
            export = try decoder.decode(ExpenseExport.self, from: data)
        } catch {
            throw ExportImportError.malformedFile
        }
        guard export.schemaVersion == currentSchemaVersion else {
            throw ExportImportError.unsupportedSchemaVersion(export.schemaVersion)
        }
        return export
    }

    /// Parses, validates, and safely merges an imported file into the
    /// repository. Returns the merge result so the caller can show the user
    /// how many records were added/updated versus rejected as invalid.
    @MainActor
    static func importAndMerge(data: Data, into repository: ExpenseRepository) throws -> SyncEngine.MergeResult {
        let export = try parseImportFile(data: data)
        let local = try repository.fetchAll()
        let result = SyncEngine.merge(local: local, remote: export.expenses)
        try repository.applyResolved(result.changed)
        return result
    }
}
