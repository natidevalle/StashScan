//
//  ContainerDetailView.swift
//  StashScan
//
//  Full detail screen for a container: hero, items, actions.
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - ContainerDetailView

struct ContainerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let container: Container

    // Sheets / alerts
    @State private var showEditContainer   = false
    @State private var showMoveContainer   = false
    @State private var showPrintPreview    = false
    @State private var showDeleteConfirm   = false
    @State private var showFullScreenPhoto = false

    // Photo picking (placeholder tap)
    @State private var showPhotoActionSheet = false
    @State private var showPhotoLibrary     = false
    @State private var showCamera           = false
    @State private var photoItem: PhotosPickerItem? = nil

    // Inline item add
    enum ItemField: Hashable { case name, qty }
    @State private var isAddingItem = false
    @State private var newItemName  = ""
    @State private var newItemQty   = ""
    @FocusState private var itemFocus: ItemField?

    // MARK: Computed

    private var sortedItems: [Item] {
        container.items.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var locationPath: String {
        let loc  = container.zone?.location?.name ?? "Unknown Location"
        let zone = container.zone?.name ?? "Unknown Zone"
        return "\(loc) > \(zone)"
    }


    // MARK: Body

    var body: some View {
        List {
            heroSection
            itemsSection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 49)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .regular))
                        Text(container.zone?.name ?? "Back")
                            .font(.body)
                    }
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showEditContainer = true } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(Color(.label))
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        // Photo action sheet (placeholder tap)
        .confirmationDialog("Add Photo", isPresented: $showPhotoActionSheet) {
            Button("Choose from Library") { showPhotoLibrary = true }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { showCamera = true }
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoLibrary, selection: $photoItem, matching: .images)
        .sheet(isPresented: $showCamera) {
            CameraPickerView(isPresented: $showCamera) { image in savePhoto(image) }
        }
        .onChange(of: photoItem) { _, newItem in
            Task {
                guard let newItem else { return }
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) { savePhoto(image) }
                photoItem = nil
            }
        }
        .sheet(isPresented: $showEditContainer) {
            if let zone = container.zone {
                AddEditContainerView(zone: zone, container: container)
            }
        }
        .sheet(isPresented: $showMoveContainer)  { MoveContainerView(container: container) }
        .sheet(isPresented: $showPrintPreview)   { PrintPreviewView(container: container) }
        .fullScreenCover(isPresented: $showFullScreenPhoto) {
            FullScreenPhotoView(photoPath: container.photoURL?.path ?? "")
        }
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
        // Dismiss item add row when focus moves fully away
        .onChange(of: itemFocus) { _, newFocus in
            guard newFocus == nil, isAddingItem else { return }
            Task { @MainActor in
                await Task.yield()
                if itemFocus == nil {
                    isAddingItem = false
                    newItemName  = ""
                    newItemQty   = ""
                }
            }
        }
    }

    // MARK: - Hero (full-bleed page header)

    @ViewBuilder
    private var heroSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 0) {

                // Photo strip
                if let url = container.photoURL, let img = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .clipped()
                        .contentShape(Rectangle())
                } else {
                    Button { showPhotoActionSheet = true } label: {
                        ZStack {
                            Color(.secondarySystemBackground)
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                            VStack(spacing: 8) {
                                Image(systemName: "camera")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(.tertiaryLabel))
                                Text("Tap to add photo")
                                    .font(.subheadline)
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Details (DS §9.2)
                VStack(alignment: .leading, spacing: 6) {

                    // Row 1: name + type pill
                    HStack(alignment: .firstTextBaseline) {
                        Text(container.name)
                            .font(.title2)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(container.type.rawValue)
                            .font(.caption)
                            .foregroundColor(Color.dsAccentForeground)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.dsAccentMuted)
                            .clipShape(Capsule())
                    }

                    // Row 2: notes (hidden if empty)
                    if !container.notes.isEmpty {
                        Text(container.notes)
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }

                    // Row 3: location path (DS §7.2)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.secondaryLabel))
                        Text(locationPath)
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                    }

                    // Row 4: updated timestamp (DS §7.3)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.secondaryLabel))
                        Text(container.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }

    // MARK: - Items section

    @ViewBuilder
    private var itemsSection: some View {
        Section {
            ForEach(sortedItems) { item in
                HStack {
                    Text(item.name)
                        .font(.body)
                    Spacer()
                    if let qty = item.quantity, qty > 0 {
                        Text("×\(qty)")
                            .font(.body)
                            .foregroundStyle(Color(.secondaryLabel))
                            .monospacedDigit()
                    }
                }
            }
            .onDelete { deleteItems(at: $0) }

            // Inline add fields
            if isAddingItem {
                HStack(spacing: 12) {
                    TextField("Item name", text: $newItemName)
                        .font(.system(size: 17))
                        .focused($itemFocus, equals: .name)
                        .onSubmit { commitItem() }
                    Divider().frame(height: 18)
                    TextField("Qty", text: $newItemQty)
                        .font(.system(size: 17))
                        .keyboardType(.numberPad)
                        .frame(width: 48)
                        .multilineTextAlignment(.trailing)
                        .focused($itemFocus, equals: .qty)
                }
                HStack {
                    Button("Cancel") {
                        isAddingItem = false
                        newItemName  = ""
                        newItemQty   = ""
                        itemFocus    = nil
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    Spacer()
                    Button("Add") { commitItem() }
                        .buttonStyle(.borderless)
                        .bold()
                        .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .font(.system(size: 15))
            }

            // "Add item" action row (DS §7.6 / §5.2)
            if !isAddingItem {
                Button {
                    isAddingItem = true
                    itemFocus    = .name
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 22))
                            .foregroundColor(Color.dsAccent)
                            .frame(width: 28)
                        Text("Add item")
                            .font(.callout)
                            .foregroundColor(Color.dsAccent)
                        Spacer()
                    }
                }
            }
        } header: {
            Text("ITEMS")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(.secondaryLabel))
        }
    }

    // MARK: - Actions section

    @ViewBuilder
    private var actionsSection: some View {
        Section {
            Button { showMoveContainer = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 22))
                        .foregroundColor(Color.dsAccent)
                        .frame(width: 28)
                    Text("Move Container")
                        .font(.callout)
                        .foregroundColor(Color.dsAccent)
                    Spacer()
                }
            }
            Button { showPrintPreview = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "printer")
                        .font(.system(size: 22))
                        .foregroundColor(Color.dsAccent)
                        .frame(width: 28)
                    Text("Print Label")
                        .font(.callout)
                        .foregroundColor(Color.dsAccent)
                    Spacer()
                }
            }
            Button { showDeleteConfirm = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 22))
                        .foregroundColor(.red)
                        .frame(width: 28)
                    Text("Delete Container")
                        .font(.callout)
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        } header: {
            Text("ACTIONS")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(.secondaryLabel))
        }
    }

    // MARK: - Item actions

    private func commitItem() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let item = Item(name: name, quantity: Int(newItemQty))
        container.items.append(item)
        container.updatedAt = Date()
        newItemName = ""
        newItemQty  = ""
        itemFocus   = .name   // keep keyboard open for next item
    }

    private func deleteItems(at offsets: IndexSet) {
        let items = offsets.map { sortedItems[$0] }
        for item in items { modelContext.delete(item) }
        container.updatedAt = Date()
    }

    // MARK: - Photo

    private func savePhoto(_ image: UIImage) {
        if let existingURL = container.photoURL {
            try? FileManager.default.removeItem(at: existingURL)
        }
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let filename = UUID().uuidString + ".jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        try? data.write(to: url)
        container.photo     = filename   // store filename only, not full path
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
            Button { dismiss() } label: {
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
            let loc  = Location(name: "Basement")
            let zone = Zone(name: "Kallax", location: loc)
            let c    = Container(
                name: "Cable Box",
                type: .box,
                notes: "HDMI, USB-C, power adapters",
                locationId: loc.id,
                zoneId: zone.id,
                zone: zone
            )
            c.items.append(Item(name: "Extension cable", quantity: 2))
            c.items.append(Item(name: "HDMI cable"))
            return c
        }())
    }
    .modelContainer(previewContainer)
}
