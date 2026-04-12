//
//  AddEditContainerView.swift
//  StashScan
//
//  Sheet for adding or editing a Container inside a Zone.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddEditContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let zone: Zone
    /// Pass nil to add a new container; pass an existing container to edit it.
    var container: Container?

    @State private var name = ""
    @State private var type: ContainerType = .box
    @State private var notes = ""

    // Photo state
    @State private var displayImage: UIImage? = nil
    @State private var photoChanged = false
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var showPhotoActionSheet = false
    @State private var showPhotoLibrary = false
    @State private var showCamera = false

    private var isEditing: Bool { container != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                    Picker("Type", selection: $type) {
                        ForEach(ContainerType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes…", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Photo") {
                    if let image = displayImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .listRowInsets(EdgeInsets())
                        Button("Change Photo") {
                            showPhotoActionSheet = true
                        }
                        Button("Remove Photo", role: .destructive) {
                            displayImage = nil
                            photoChanged = true
                        }
                    } else {
                        Button {
                            showPhotoActionSheet = true
                        } label: {
                            Label("Add Photo", systemImage: "photo.badge.plus")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Container" : "New Container")
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
            .onAppear { loadExistingData() }
            .confirmationDialog("Add Photo", isPresented: $showPhotoActionSheet) {
                Button("Choose from Library") { showPhotoLibrary = true }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") { showCamera = true }
                }
                Button("Cancel", role: .cancel) {}
            }
            .photosPicker(isPresented: $showPhotoLibrary, selection: $photoItem, matching: .images)
            .sheet(isPresented: $showCamera) {
                CameraPickerView(isPresented: $showCamera) { image in
                    displayImage = image
                    photoChanged = true
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task {
                    guard let newItem else { return }
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        displayImage = image
                        photoChanged = true
                    }
                }
            }
        }
    }

    private func loadExistingData() {
        guard let container else { return }
        name = container.name
        type = container.type
        notes = container.notes
        if let path = container.photo {
            displayImage = UIImage(contentsOfFile: path)
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        var photoPath: String? = container?.photo

        if photoChanged {
            // Delete old photo file if one existed
            if let oldPath = container?.photo {
                try? FileManager.default.removeItem(atPath: oldPath)
            }
            // Save new photo if the user picked one
            if let image = displayImage {
                photoPath = savePhotoToDisk(image)
            } else {
                photoPath = nil
            }
        }

        if let container {
            container.name = trimmed
            container.type = type
            container.notes = notes
            container.photo = photoPath
            container.updatedAt = Date()
        } else {
            let locationId = zone.location?.id ?? UUID()
            let newContainer = Container(
                name: trimmed,
                type: type,
                notes: notes,
                photo: photoPath,
                locationId: locationId,
                zoneId: zone.id,
                zone: zone
            )
            modelContext.insert(newContainer)
        }
        dismiss()
    }
}

private func savePhotoToDisk(_ image: UIImage) -> String? {
    guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
    let filename = UUID().uuidString + ".jpg"
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(filename)
    try? data.write(to: url)
    return url.path
}

#Preview("Add") {
    let loc = Location(name: "Garage")
    let zone = Zone(name: "Wall Shelves", location: loc)
    return AddEditContainerView(zone: zone)
        .modelContainer(previewContainer)
}
