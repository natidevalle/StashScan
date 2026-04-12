//
//  ZoneDetailView.swift
//  StashScan
//
//  Shows the containers inside a zone.
//

import SwiftUI
import SwiftData

struct ZoneDetailView: View {
    let zone: Zone

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
            }
        }
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if zone.containers.isEmpty {
                ContentUnavailableView(
                    "No Containers",
                    systemImage: "archivebox",
                    description: Text("No containers in this zone yet.")
                )
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
