//
//  AddEditLocationView.swift
//  StashScan
//
//  Sheet for adding or editing a Location.
//

import SwiftUI
import SwiftData

struct AddEditLocationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Pass nil to add a new location; pass an existing location to edit it.
    var location: Location?

    @State private var name = ""

    private var isEditing: Bool { location != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle(isEditing ? "Edit Location" : "New Location")
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
                name = location?.name ?? ""
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let location {
            location.name = trimmed
        } else {
            modelContext.insert(Location(name: trimmed))
        }
        dismiss()
    }
}

#Preview("Add") {
    AddEditLocationView()
        .modelContainer(previewContainer)
}
