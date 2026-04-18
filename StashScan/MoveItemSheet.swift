//
//  MoveItemSheet.swift
//  StashScan
//
//  Sheet for moving an Item to a different Container.
//

import SwiftUI
import SwiftData

struct MoveItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Location.name) private var locations: [Location]

    let item: Item
    let onConfirm: (Container) -> Void
    let onDismiss: () -> Void

    @State private var selectedLocation: Location?  = nil
    @State private var selectedZone: Zone?          = nil
    @State private var selectedContainer: Container? = nil

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
                        selectedZone      = nil
                        selectedContainer = nil
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
                            .onChange(of: selectedZone) { _, _ in
                                selectedContainer = nil
                            }
                        }
                    }
                }

                if let zone = selectedZone {
                    let sortedContainers = zone.containers.sorted { $0.name < $1.name }
                    Section("Container") {
                        if sortedContainers.isEmpty {
                            Text("No containers in this zone")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Container", selection: $selectedContainer) {
                                Text("Select a container…").tag(Optional<Container>.none)
                                ForEach(sortedContainers) { container in
                                    Text(container.name).tag(Optional(container))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") { confirm() }
                        .disabled(selectedContainer == nil || selectedContainer?.id == item.container?.id)
                }
            }
            .onAppear {
                selectedLocation  = item.container?.zone?.location
                selectedZone      = item.container?.zone
                selectedContainer = item.container
            }
        }
    }

    private func confirm() {
        guard let destination = selectedContainer else { return }
        onConfirm(destination)
        onDismiss()
    }
}
