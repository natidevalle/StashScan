//
//  AddEditZoneView.swift
//  StashScan
//
//  Sheet for adding or editing a Zone inside a Location.
//

import SwiftUI
import SwiftData

struct AddEditZoneView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let location: Location
    /// Pass nil to add a new zone; pass an existing zone to edit it.
    var zone: Zone?

    @State private var name = ""

    private var isEditing: Bool { zone != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                }
                Section {
                    LabeledContent("Location", value: location.name)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(isEditing ? "Edit Zone" : "New Zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = zone?.name ?? ""
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let zone {
            zone.name = trimmed
        } else {
            let newZone = Zone(name: trimmed, location: location)
            modelContext.insert(newZone)
        }
        dismiss()
    }
}

#Preview("Add") {
    let loc = Location(name: "Garage")
    return AddEditZoneView(location: loc)
        .modelContainer(previewContainer)
}
