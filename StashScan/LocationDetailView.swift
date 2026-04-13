//
//  LocationDetailView.swift
//  StashScan
//
//  Shows the zones inside a location.
//

import SwiftUI
import SwiftData

struct LocationDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let location: Location

    @Query private var zones: [Zone]

    @State private var showAddZone = false
    @State private var zoneToDelete: Zone? = nil
    @State private var showZoneDeleteConfirm = false

    init(location: Location) {
        self.location = location
        let id = location.id
        _zones = Query(
            filter: #Predicate<Zone> { $0.location?.id == id },
            sort: \Zone.name
        )
    }

    var body: some View {
        List {
            ForEach(zones) { zone in
                NavigationLink(value: zone) {
                    HStack(spacing: 12) {
                        ListIcon(symbol: "square.split.2x1.fill")
                        Text(zone.name)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        zoneToDelete = zone
                        showZoneDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if zones.isEmpty {
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
        }
        .sheet(isPresented: $showAddZone) {
            AddEditZoneView(location: location)
        }
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
