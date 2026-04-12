//
//  LocationDetailView.swift
//  StashScan
//
//  Shows the zones inside a location.
//

import SwiftUI
import SwiftData

struct LocationDetailView: View {
    let location: Location

    var sortedZones: [Zone] {
        location.zones.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            ForEach(sortedZones) { zone in
                NavigationLink(destination: ZoneDetailView(zone: zone)) {
                    Label(zone.name, systemImage: "square.split.2x1")
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
                    description: Text("Add zones to organise containers in this location.")
                )
            }
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
