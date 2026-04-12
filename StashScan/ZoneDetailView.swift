//
//  ZoneDetailView.swift
//  StashScan
//
//  Shows the containers inside a zone, with add/delete actions.
//

import SwiftUI
import SwiftData

struct ZoneDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let zone: Zone

    @State private var showAddContainer = false
    @State private var containerToDelete: Container? = nil
    @State private var showContainerDeleteConfirm = false
    @State private var showEditZone = false
    @State private var showDeleteZone = false

    var sortedContainers: [Container] {
        zone.containers.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            ForEach(sortedContainers) { container in
                NavigationLink(destination: ContainerDetailView(container: container)) {
                    HStack(spacing: 12) {
                        Image(systemName: iconName(for: container.type))
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(container.name)
                            Text(container.type.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        containerToDelete = container
                        showContainerDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if zone.containers.isEmpty {
                ContentUnavailableView(
                    "No Containers",
                    systemImage: "archivebox",
                    description: Text("Tap + to add the first container.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddContainer = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showEditZone = true
                    } label: {
                        Label("Edit Zone Name", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteZone = true
                    } label: {
                        Label("Delete Zone", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddContainer) {
            AddEditContainerView(zone: zone)
        }
        .sheet(isPresented: $showEditZone) {
            if let location = zone.location {
                AddEditZoneView(location: location, zone: zone)
            }
        }
        .confirmationDialog(
            "Delete \"\(containerToDelete?.name ?? "")\"?",
            isPresented: $showContainerDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let c = containerToDelete {
                    c.delete(from: modelContext)
                }
                containerToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                containerToDelete = nil
            }
        } message: {
            if let c = containerToDelete {
                let count = c.items.count
                if count > 0 {
                    Text("This will delete \(count) item\(count == 1 ? "" : "s") inside this container.")
                } else {
                    Text("This container is empty.")
                }
            }
        }
        .confirmationDialog(
            "Delete \"\(zone.name)\"?",
            isPresented: $showDeleteZone,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                zone.delete(from: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let containerCount = zone.containers.count
            if containerCount > 0 {
                Text("This will delete \(containerCount) container\(containerCount == 1 ? "" : "s") and all their contents.")
            } else {
                Text("This zone is empty.")
            }
        }
    }

    private func iconName(for type: ContainerType) -> String {
        switch type {
        case .box:    return "shippingbox"
        case .bag:    return "bag"
        case .bin:    return "trash"
        case .drawer: return "square.stack"
        case .shelf:  return "books.vertical"
        case .other:  return "archivebox"
        }
    }
}

#Preview {
    NavigationStack {
        ZoneDetailView(zone: {
            let loc = Location(name: "Garage")
            let zone = Zone(name: "Wall Shelves", location: loc)
            let c = Container(name: "Tool Box", type: .box, locationId: loc.id, zoneId: zone.id, zone: zone)
            _ = c
            return zone
        }())
    }
    .modelContainer(previewContainer)
}
