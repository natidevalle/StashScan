//
//  SettingsView.swift
//  StashScan
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("lastExportDate") private var lastExportTimestamp: Double = 0

    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var showDocumentPicker = false
    @State private var importResult: ImportResult?
    @State private var showImportResult = false
    @State private var alertMessage: String?

    private var lastExportDate: Date? {
        lastExportTimestamp > 0 ? Date(timeIntervalSince1970: lastExportTimestamp) : nil
    }

    var body: some View {
        List {
            Section {
                exportRow
                importRow
            } header: {
                Text("EXPORT & BACKUP")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .regular))
                        Text("Locations")
                            .font(.body)
                    }
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.json]
        ) { result in
            handleImport(result: result)
        }
        .alert("Import Complete", isPresented: $showImportResult, presenting: importResult) { _ in
            Button("OK", role: .cancel) {}
        } message: { result in
            Text(importSummary(result))
        }
        .alert("Error", isPresented: .init(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    // MARK: - Rows

    private var exportRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                performExport()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.up.doc")
                        .font(.system(size: 22))
                        .foregroundColor(Color.dsAccent)
                        .frame(width: 28)
                    Text("Export backup")
                        .font(.callout)
                        .foregroundColor(Color.dsAccent)
                    Spacer()
                }
            }
            if let date = lastExportDate {
                Text("Last export: \(date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.leading, 40)
            }
        }
        .padding(.vertical, 8)
    }

    private var importRow: some View {
        Button {
            showDocumentPicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 22))
                    .foregroundColor(Color.dsAccent)
                    .frame(width: 28)
                Text("Import backup")
                    .font(.callout)
                    .foregroundColor(Color.dsAccent)
                Spacer()
            }
        }
    }

    // MARK: - Actions

    private func performExport() {
        do {
            let url = try BackupManager.shared.export(context: modelContext)
            lastExportTimestamp = Date().timeIntervalSince1970
            shareURL = url
            showShareSheet = true
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func handleImport(result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let imported = try BackupManager.shared.importBackup(from: url, context: modelContext)
            importResult = imported
            showImportResult = true
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func importSummary(_ result: ImportResult) -> String {
        func plural(_ n: Int, _ word: String) -> String { "\(n) \(word)\(n == 1 ? "" : "s")" }
        let counts = [
            plural(result.locations, "location"),
            plural(result.zones, "zone"),
            plural(result.containers, "container"),
            plural(result.items, "item")
        ].joined(separator: ", ")
        return "Imported \(counts).\n\nPhotos are not restored — re-add them manually from each container."
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
