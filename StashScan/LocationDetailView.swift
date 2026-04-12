//
//  LocationDetailView.swift
//  StashScan
//
//  Shows the zones inside a location, with full zone CRUD.
//

import SwiftUI
import SwiftData

struct LocationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let location: Location

    @State private var showAddZone = false
    @State private var zoneToEdit: Zone? = nil
    @State private var zoneToDelete: Zone? = nil
    @State private var showZoneDeleteConfirm = false
    @State private var showEditLocation = false
    @State private var showDeleteLocation = false

    var sortedZones: [Zone] {
        location.zones.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            ForEach(sortedZones) { zone in
                NavigationLink(destination: ZoneDetailView(zone: zone)) {
                    Label(zone.name, systemImage: "square.split.2x1")
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        zoneToDelete = zone
                        showZoneDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        zoneToEdit = zone
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if location.zones.isEmpty {
                ContentUnavailableView(
                    "No Zones",
                    systemImage: "square.dashed",
                    description: Text("Tap + to add the first zone.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddZone = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showEditLocation = true
                    } label: {
                        Label("Edit Location Name", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteLocation = true
                    } label: {
                        Label("Delete Location", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddZone) {
            AddEditZoneView(location: location)
        }
        .sheet(item: $zoneToEdit) { zone in
            AddEditZoneView(location: location, zone: zone)
        }
        .sheet(isPresented: $showEditLocation) {
            AddEditLocationView(location: location)
        }
        // Zone delete confirmation
        .confirmationDialog(
            "Delete \"\(zoneToDelete?.name ?? "")\"?",
            isPresented: $showZoneDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let zone = zoneToDelete {
                    zone.delete(from: modelContext)
                }
                zoneToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                zoneToDelete = nil
            }
        } message: {
            if let zone = zoneToDelete {
                Text(zoneDeleteMessage(for: zone))
            }
        }
        // Location delete confirmation
        .confirmationDialog(
            "Delete \"\(location.name)\"?",
            isPresented: $showDeleteLocation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                location.delete(from: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let zoneCount = location.zones.count
            let containerCount = location.zones.reduce(0) { $0 + $1.containers.count }
            if containerCount > 0 {
                Text("This will delete \(zoneCount) zone\(zoneCount == 1 ? "" : "s") and \(containerCount) container\(containerCount == 1 ? "" : "s") and all their contents.")
            } else if zoneCount > 0 {
                Text("This will delete \(zoneCount) zone\(zoneCount == 1 ? "" : "s").")
            } else {
                Text("This location is empty.")
            }
        }
    }

    private func zoneDeleteMessage(for zone: Zone) -> String {
        let containerCount = zone.containers.count
        if containerCount > 0 {
            return "This will delete \(containerCount) container\(containerCount == 1 ? "" : "s") and all their contents."
        } else {
            return "This zone is empty."
        }
    }
}

#Preview {
    NavigationStack {
        LocationDetailView(location: {
            let loc = Location(name: "Garage")
            let z1 = Zone(name: "Wall Shelves", location: loc)
            let z2 = Zone(name: "Workbench", location: loc)
            _ = z1; _ = z2
            return loc
        }())
    }
    .modelContainer(previewContainer)
}
