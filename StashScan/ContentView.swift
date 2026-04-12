//
//  ContentView.swift
//  StashScan
//
//  Home screen: hierarchical list of Locations with Search and Scan entry points.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Location.name) private var locations: [Location]

    @State private var searchText = ""
    @State private var showAddLocation = false
    @State private var locationToEdit: Location? = nil
    @State private var locationToDelete: Location? = nil
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(locations) { location in
                    NavigationLink(destination: LocationDetailView(location: location)) {
                        Label(location.name, systemImage: "house")
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            locationToDelete = location
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            locationToEdit = location
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationTitle("StashScan")
            .searchable(text: $searchText, prompt: "Search items, containers…")
            .overlay {
                if locations.isEmpty {
                    ContentUnavailableView(
                        "No Locations",
                        systemImage: "house.slash",
                        description: Text("Tap + to add your first location.")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddLocation = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                }
                ToolbarItem(placement: .bottomBar) { Spacer() }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        // TODO: open QR/barcode scanner
                    } label: {
                        Label("Scan", systemImage: "qrcode.viewfinder")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .bottomBar) { Spacer() }
            }
            .sheet(isPresented: $showAddLocation) {
                AddEditLocationView()
            }
            .sheet(item: $locationToEdit) { location in
                AddEditLocationView(location: location)
            }
            .confirmationDialog(
                "Delete \"\(locationToDelete?.name ?? "")\"?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let loc = locationToDelete {
                        loc.delete(from: modelContext)
                    }
                    locationToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    locationToDelete = nil
                }
            } message: {
                if let loc = locationToDelete {
                    Text(deleteMessage(for: loc))
                }
            }
        }
    }

    private func deleteMessage(for location: Location) -> String {
        let zoneCount = location.zones.count
        let containerCount = location.zones.reduce(0) { $0 + $1.containers.count }
        if containerCount > 0 {
            return "This will delete \(zoneCount) zone\(zoneCount == 1 ? "" : "s") and \(containerCount) container\(containerCount == 1 ? "" : "s") and all their contents."
        } else if zoneCount > 0 {
            return "This will delete \(zoneCount) zone\(zoneCount == 1 ? "" : "s")."
        } else {
            return "This location is empty."
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
