import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: ExpenseStore
    @AppStorage(AppStorageKeys.currentUser) private var currentUserRaw: String = Payer.het.rawValue
    @AppStorage(AppStorageKeys.deviceName) private var deviceName: String = ""

    @State private var exportDocument: ExpenseBackupDocument?
    @State private var isPresentingExporter = false
    @State private var isPresentingImporter = false

    @State private var importResultMessage: String?
    @State private var showImportResult = false
    @State private var importErrorMessage: String?
    @State private var showImportError = false

    private var currentUser: Payer { Payer(rawValue: currentUserRaw) ?? .het }

    var body: some View {
        Form {
            Section("Personal") {
                Picker("Your name", selection: $currentUserRaw) {
                    ForEach(Payer.allCases) { payer in
                        Text(payer.displayName).tag(payer.rawValue)
                    }
                }

                TextField(
                    "Device name",
                    text: $deviceName,
                    prompt: Text(DeviceIdentity.defaultDeviceName(for: currentUser))
                )
            }

            Section("Sync") {
                NavigationLink("Device Sync") {
                    SyncView()
                }
            }

            Section("Data") {
                Button {
                    prepareExport()
                } label: {
                    Label("Export Expenses", systemImage: "square.and.arrow.up")
                }

                Button {
                    isPresentingImporter = true
                } label: {
                    Label("Import Expenses", systemImage: "square.and.arrow.down")
                }
            }

            Section("About") {
                LabeledContent("Version", value: appVersionString)
                Text("No accounts, no cloud, no tracking. Your expenses live only on this iPhone and the one you sync with directly.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .fileExporter(
            isPresented: $isPresentingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: ExportImportService.exportFileName()
        ) { _ in
            exportDocument = nil
        }
        .fileImporter(isPresented: $isPresentingImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                importFile(at: url)
            case .failure:
                importErrorMessage = "Couldn't open that file."
                showImportError = true
            }
        }
        .alert("Import Complete", isPresented: $showImportResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importResultMessage ?? "")
        }
        .alert("Import Failed", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage ?? "That file couldn't be imported. Your existing expenses are unchanged.")
        }
    }

    private func prepareExport() {
        let records = store.fetchAllIncludingDeleted()
        do {
            let data = try ExportImportService.exportData(records: records)
            exportDocument = ExpenseBackupDocument(data: data)
            isPresentingExporter = true
        } catch {
            importErrorMessage = "Couldn't create the export file."
            showImportError = true
        }
    }

    private func importFile(at url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let result = try ExportImportService.importAndMerge(data: data, into: store.repository)
            store.refresh()
            Haptics.success()

            var message = "Added or updated \(result.changed.count) expense\(result.changed.count == 1 ? "" : "s")."
            if !result.rejected.isEmpty {
                message += " Skipped \(result.rejected.count) invalid record\(result.rejected.count == 1 ? "" : "s")."
            }
            importResultMessage = message
            showImportResult = true
        } catch {
            importErrorMessage = (error as? LocalizedError)?.errorDescription
                ?? "That file couldn't be imported. Your existing expenses are unchanged."
            showImportError = true
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
