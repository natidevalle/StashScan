//
//  MoveContainerView.swift
//  StashScan
//
//  Sheet for moving a Container to a different Zone or Location.
//

import SwiftUI
import SwiftData

struct MoveContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Location.name) private var locations: [Location]

    let container: Container

    @State private var selectedLocation: Location? = nil
    @State private var selectedZone: Zone? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    Picker("Location", selection: $selectedLocation) {
                        Text("Select a location…").tag(Optional<Location>.none)
                        ForEach(locations) { loc in
                            Text(loc.name).tag(Optional(loc))
                        }
                    }
                    .onChange(of: selectedLocation) { _, _ in
                        selectedZone = nil
                    }
                }

                if let location = selectedLocation {
                    let sortedZones = location.zones.sorted { $0.name < $1.name }
                    Section("Zone") {
                        if sortedZones.isEmpty {
                            Text("No zones in this location")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Zone", selection: $selectedZone) {
                                Text("Select a zone…").tag(Optional<Zone>.none)
                                ForEach(sortedZones) { zone in
                                    Text(zone.name).tag(Optional(zone))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move Container")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Move") { move() }
                        .disabled(selectedZone == nil || selectedZone?.id == container.zone?.id)
                }
            }
            .onAppear {
                selectedLocation = container.zone?.location
                selectedZone = container.zone
            }
        }
    }

    private func move() {
        guard let newZone = selectedZone,
              let newLocation = newZone.location else { return }
        container.zone = newZone
        container.zoneId = newZone.id
        container.locationId = newLocation.id
        container.updatedAt = Date()
        dismiss()
    }
}
