//
//  ZoneDetailView.swift
//  StashScan
//
//  Shows the containers inside a zone.
//

import SwiftUI
import SwiftData

struct ZoneDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let zone: Zone

    @Query private var containers: [Container]

    @State private var showAddContainer = false
    @State private var containerToDelete: Container? = nil
    @State private var showContainerDeleteConfirm = false

    init(zone: Zone) {
        self.zone = zone
        let id = zone.id
        _containers = Query(
            filter: #Predicate<Container> { $0.zoneId == id },
            sort: \Container.name
        )
    }

    var body: some View {
        List {
            ForEach(containers) { container in
                NavigationLink(value: container) {
                    HStack(spacing: 12) {
                        ListIcon(symbol: "archivebox")
                        Text(container.name)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
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
        .navigationBarBackButtonHidden(true)
        .overlay {
            if containers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 48))
                        .foregroundColor(Color(.tertiaryLabel))
                    Text("No Containers")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Tap + to add the first container.")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .regular))
                        Text(zone.location?.name ?? "Back")
                            .font(.body)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .fixedSize()
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    //.background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddContainer = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color(.label))
                }
            }
        }
        .sheet(isPresented: $showAddContainer) {
            AddEditContainerView(zone: zone)
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
