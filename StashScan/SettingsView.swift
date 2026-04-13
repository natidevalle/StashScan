//
//  SettingsView.swift
//  StashScan
//
//  Placeholder settings screen.
//

import SwiftUI

struct SettingsView: View {
    @State private var comingSoonFeature: ComingSoonFeature?

    enum ComingSoonFeature: String, Identifiable {
        case exportSheets = "Export to Google Sheets"
        case exportCSV    = "Export to CSV"
        case importCSV    = "Import from CSV"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .exportSheets: return "tablecells"
            case .exportCSV:    return "arrow.up.doc"
            case .importCSV:    return "arrow.down.doc"
            }
        }

        var description: String {
            switch self {
            case .exportSheets:
                return "Export your inventory directly to a Google Sheets spreadsheet. This feature is coming in a future update."
            case .exportCSV:
                return "Download a CSV file of your entire inventory for use in Excel or other apps. This feature is coming in a future update."
            case .importCSV:
                return "Bulk-import items into StashScan from a CSV file. This feature is coming in a future update."
            }
        }
    }

    var body: some View {
        List {
            Section("Export & Backup") {
                exportRow(.exportSheets)
                exportRow(.exportCSV)
                exportRow(.importCSV)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $comingSoonFeature) { feature in
            ComingSoonSheet(feature: feature)
        }
    }

    @ViewBuilder
    private func exportRow(_ feature: ComingSoonFeature) -> some View {
        Button {
            comingSoonFeature = feature
        } label: {
            Label(feature.rawValue, systemImage: feature.icon)
                .foregroundStyle(.primary)
        }
    }
}

private struct ComingSoonSheet: View {
    let feature: SettingsView.ComingSoonFeature
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: feature.icon)
                    .font(.system(size: 52))
                    .foregroundStyle(.tint)

                Text(feature.rawValue)
                    .font(.title2.bold())

                Text(feature.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
