//
//  ContainerDetailView.swift
//  StashScan
//
//  Full detail screen for a container: path, type, photo, items, actions.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ContainerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let container: Container

    // Sheet / alert presentation
    @State private var showEditContainer = false
    @State private var showMoveContainer = false
    @State private var showDeleteConfirm = false
    @State private var showFullScreenPhoto = false

    // Photo picking
    @State private var showPhotoActionSheet = false
    @State private var showPhotoLibrary = false
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem? = nil

    // Inline item add
    @State private var isAddingItem = false
    @State private var newItemName = ""
    @State private var newItemQuantity = ""
    @FocusState private var addItemFocused: Bool

    private var sortedItems: [Item] {
        container.items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var locationPath: String {
        let locationName = container.zone?.location?.name ?? "Unknown Location"
        let zoneName = container.zone?.name ?? "Unknown Zone"
        return "\(locationName)  ›  \(zoneName)"
    }

    var body: some View {
        List {
            // ── Location path ──────────────────────────────────────────
            Section {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.secondary)
                    Text(locationPath)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // ── Details ────────────────────────────────────────────────
            Section("Details") {
                HStack {
                    Text("Type")
                    Spacer()
                    Text(container.type.rawValue)
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.tint.opacity(0.12))
                        .foregroundStyle(.tint)
                        .clipShape(Capsule())
                }
                if !container.notes.isEmpty {
                    Text(container.notes)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Updated") {
                    Text(container.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }
            }

            // ── QR Code ────────────────────────────────────────────────
            Section("QR Code") {
                HStack {
                    Spacer()
                    QRCodeView(uuid: container.qrCode)
                        .frame(width: 180, height: 180)
                    Spacer()
                }
                .padding(.vertical, 8)
            }

            // ── Photo ──────────────────────────────────────────────────
            Section("Photo") {
                if let photoPath = container.photo,
                   let image = UIImage(contentsOfFile: photoPath) {
                    Button {
                        showFullScreenPhoto = true
                    } label: {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    Button("Change Photo") {
                        showPhotoActionSheet = true
                    }
                    Button("Remove Photo", role: .destructive) {
                        removePhoto()
                    }
                } else {
                    Button {
                        showPhotoActionSheet = true
                    } label: {
                        Label("Add Photo", systemImage: "photo.badge.plus")
                    }
                }
            }

            // ── Items ──────────────────────────────────────────────────
            Section {
                ForEach(sortedItems) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        if let qty = item.quantity {
                            Text("×\(qty)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
                .onDelete { offsets in
                    deleteItems(at: offsets)
                }

                if isAddingItem {
                    // Row 1: name + optional qty fields
                    HStack(spacing: 12) {
                        TextField("Item name", text: $newItemName)
                            .focused($addItemFocused)
                            .onSubmit { commitItem() }
                        Divider().frame(height: 18)
                        TextField("Qty", text: $newItemQuantity)
                            .keyboardType(.numberPad)
                            .frame(width: 48)
                            .multilineTextAlignment(.trailing)
                    }
                    // Row 2: cancel + add buttons
                    // .buttonStyle(.borderless) is required — without it a List row with
                    // multiple Buttons lets the row absorb the tap before either button sees it.
                    HStack {
                        Button("Cancel") {
                            isAddingItem = false
                            newItemName = ""
                            newItemQuantity = ""
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        Spacer()
                        Button("Add") { commitItem() }
                            .buttonStyle(.borderless)
                            .bold()
                            .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .font(.subheadline)
                }

                if !isAddingItem {
                    Button {
                        isAddingItem = true
                    } label: {
                        Label("Add Item", systemImage: "plus.circle.fill")
                    }
                }
            } header: {
                let count = container.items.count
                Text(count == 0 ? "Items" : "Items (\(count))")
            }

            // ── Actions ────────────────────────────────────────────────
            Section {
                Button {
                    showMoveContainer = true
                } label: {
                    Label("Move Container", systemImage: "arrow.up.right.square")
                }
                Button {
                    // TODO: Phase 5 — BLE print to Phomemo Q02E
                } label: {
                    Label("Print Label", systemImage: "printer")
                }
                .foregroundStyle(.secondary)
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Container", systemImage: "trash")
                }
            }
        }
        .navigationTitle(container.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showEditContainer = true }
            }
        }
        // Photo action sheet
        .confirmationDialog("Photo", isPresented: $showPhotoActionSheet) {
            Button("Choose from Library") { showPhotoLibrary = true }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { showCamera = true }
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoLibrary, selection: $photoItem, matching: .images)
        .sheet(isPresented: $showCamera) {
            CameraPickerView(isPresented: $showCamera) { image in
                savePhoto(image)
            }
        }
        .onChange(of: photoItem) { _, newItem in
            Task {
                guard let newItem else { return }
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    savePhoto(image)
                }
                photoItem = nil
            }
        }
        // Edit sheet
        .sheet(isPresented: $showEditContainer) {
            if let zone = container.zone {
                AddEditContainerView(zone: zone, container: container)
            }
        }
        // Move sheet
        .sheet(isPresented: $showMoveContainer) {
            MoveContainerView(container: container)
        }
        // Full-screen photo
        .fullScreenCover(isPresented: $showFullScreenPhoto) {
            FullScreenPhotoView(photoPath: container.photo ?? "")
        }
        // Delete confirmation
        .confirmationDialog(
            "Delete \"\(container.name)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteContainer() }
            Button("Cancel", role: .cancel) {}
        } message: {
            let count = container.items.count
            if count > 0 {
                Text("This will delete \(count) item\(count == 1 ? "" : "s") inside this container.")
            } else {
                Text("This container is empty.")
            }
        }
        // Auto-focus when add item form appears
        .onChange(of: isAddingItem) { _, newValue in
            if newValue { addItemFocused = true }
        }
    }

    // MARK: - Item actions

    private func commitItem() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let qty = Int(newItemQuantity)
        let item = Item(name: name, quantity: qty)
        container.items.append(item)   // auto-inserts into context and wires the inverse
        container.updatedAt = Date()
        newItemName = ""
        newItemQuantity = ""
        isAddingItem = false
    }

    private func deleteItems(at offsets: IndexSet) {
        let items = offsets.map { sortedItems[$0] }
        for item in items {
            modelContext.delete(item)
        }
        container.updatedAt = Date()
    }

    // MARK: - Photo actions

    private func savePhoto(_ image: UIImage) {
        if let existingPath = container.photo {
            try? FileManager.default.removeItem(atPath: existingPath)
        }
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let filename = UUID().uuidString + ".jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        try? data.write(to: url)
        container.photo = url.path
        container.updatedAt = Date()
    }

    private func removePhoto() {
        if let path = container.photo {
            try? FileManager.default.removeItem(atPath: path)
        }
        container.photo = nil
        container.updatedAt = Date()
    }

    // MARK: - Delete

    private func deleteContainer() {
        container.delete(from: modelContext)
        dismiss()
    }
}

// MARK: - Full-screen photo viewer

private struct FullScreenPhotoView: View {
    let photoPath: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            if let image = UIImage(contentsOfFile: photoPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                    .padding()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContainerDetailView(container: {
            let loc = Location(name: "Garage")
            let zone = Zone(name: "Wall Shelves", location: loc)
            let c = Container(
                name: "Tool Box",
                type: .box,
                notes: "Hand tools — hammer, screwdrivers, pliers",
                locationId: loc.id,
                zoneId: zone.id,
                zone: zone
            )
            return c
        }())
    }
    .modelContainer(previewContainer)
}
