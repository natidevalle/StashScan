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

    var body: some View {
        NavigationStack {
            List {
                ForEach(locations) { location in
                    NavigationLink(destination: LocationDetailView(location: location)) {
                        Label(location.name, systemImage: "house")
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
                        description: Text("Add a location to start organising your stash.")
                    )
                }
            }
            .onAppear(perform: seedSampleDataIfNeeded)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Spacer()
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        // TODO: open QR/barcode scanner
                    } label: {
                        Label("Scan", systemImage: "qrcode.viewfinder")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Spacer()
                }
            }
        }
    }
    private func seedSampleDataIfNeeded() {
        guard locations.isEmpty else { return }

        let garage  = Location(name: "Garage")
        let basement = Location(name: "Basement")
        let office  = Location(name: "Home Office")
        modelContext.insert(garage)
        modelContext.insert(basement)
        modelContext.insert(office)

        let wallShelves = Zone(name: "Wall Shelves", location: garage)
        let workbench   = Zone(name: "Workbench",    location: garage)
        modelContext.insert(wallShelves)
        modelContext.insert(workbench)

        let storageArea = Zone(name: "Storage Area",   location: basement)
        let laundry     = Zone(name: "Laundry Corner", location: basement)
        modelContext.insert(storageArea)
        modelContext.insert(laundry)

        let deskDrawers = Zone(name: "Desk Drawers", location: office)
        modelContext.insert(deskDrawers)

        modelContext.insert(Container(
            name: "Tool Box", type: .box,
            notes: "Hand tools — hammer, screwdrivers, pliers",
            locationId: garage.id, zoneId: wallShelves.id, zone: wallShelves))
        modelContext.insert(Container(
            name: "Cables Bin", type: .bin,
            notes: "USB-A, HDMI, and extension cables",
            locationId: garage.id, zoneId: wallShelves.id, zone: wallShelves))
        modelContext.insert(Container(
            name: "Holiday Decorations", type: .box,
            notes: "Christmas ornaments and lights",
            locationId: basement.id, zoneId: storageArea.id, zone: storageArea))
        modelContext.insert(Container(
            name: "Office Supplies", type: .drawer,
            notes: "Pens, sticky notes, tape",
            locationId: office.id, zoneId: deskDrawers.id, zone: deskDrawers))
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
