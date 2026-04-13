//
//  ContainerDetailView.swift
//  StashScan
//
//  Full detail screen for a container: hero card, items, actions.
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - ContainerDetailView

struct ContainerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let container: Container

    // Sheet / alert presentation
    @State private var showEditContainer  = false
    @State private var showMoveContainer  = false
    @State private var showPrintPreview   = false
    @State private var showDeleteConfirm  = false
    @State private var showFullScreenPhoto = false

    // Photo picking (for the placeholder tap on hero card)
    @State private var showPhotoActionSheet = false
    @State private var showPhotoLibrary     = false
    @State private var showCamera           = false
    @State private var photoItem: PhotosPickerItem? = nil

    // Inline item add
    @State private var isAddingItem   = false
    @State private var newItemName    = ""
    @State private var newItemQty     = ""
    @FocusState private var addItemFocused: Bool

    // MARK: Computed

    private var sortedItems: [Item] {
        container.items.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var locationPath: String {
        let loc  = container.zone?.location?.name ?? "Unknown Location"
        let zone = container.zone?.name ?? "Unknown Zone"
        return "\(loc) › \(zone)"
    }

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy, HH:mm"
        return f
    }()

    // MARK: Body

    var body: some View {
        List {
            heroCard
            itemsSection
            actionsSection
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showEditContainer = true } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        // Photo action sheet (from placeholder tap)
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
        // Print preview sheet
        .sheet(isPresented: $showPrintPreview) {
            PrintPreviewView(container: container)
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
        // Auto-focus when add row appears
        .onChange(of: isAddingItem) { _, newValue in
            if newValue { addItemFocused = true }
        }
    }

    // MARK: - Hero card

    @ViewBuilder
    private var heroCard: some View {
        Section {
            VStack(alignment: .leading, spacing: 0) {

                // ── Photo strip ───────────────────────────────────────
                if let path = container.photo, let img = UIImage(contentsOfFile: path) {
                    Button { showFullScreenPhoto = true } label: {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 88)
                            .clipped()
                    }
                    .buttonStyle(.plain)
                } else {
                    Button { showPhotoActionSheet = true } label: {
                        ZStack {
                            Color(.systemGray6)
                                .frame(maxWidth: .infinity)
                                .frame(height: 88)
                            VStack(spacing: 6) {
                                Image(systemName: "camera")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text("Tap to add photo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                // ── Details ───────────────────────────────────────────
                VStack(alignment: .leading, spacing: 6) {
                    Text(container.name)
                        .font(.system(size: 13, weight: .bold))

                    Text(container.type.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(stashBlueTint)
                        .foregroundStyle(stashBlue)
                        .clipShape(Capsule())

                    Text(locationPath)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    if !container.notes.isEmpty {
                        Text(container.notes)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

                    Text(Self.dateFmt.string(from: container.updatedAt))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .listRowInsets(EdgeInsets())
    }

    // MARK: - Items section

    @ViewBuilder
    private var itemsSection: some View {
        Section {
            ForEach(sortedItems) { item in
                HStack {
                    Text(item.name)
                    Spacer()
                    if let qty = item.quantity, qty > 0 {
                        Text("×\(qty)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .onDelete { deleteItems(at: $0) }

            // Inline add row
            if isAddingItem {
                HStack(spacing: 12) {
                    TextField("Item name", text: $newItemName)
                        .focused($addItemFocused)
                        .onSubmit { commitItem() }
                    Divider().frame(height: 18)
                    TextField("Qty", text: $newItemQty)
                        .keyboardType(.numberPad)
                        .frame(width: 48)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Button("Cancel") {
                        isAddingItem = false
                        newItemName  = ""
                        newItemQty   = ""
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

            // "Add item" bordered bar
            if !isAddingItem {
                Button {
                    isAddingItem   = true
                    addItemFocused = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Add item")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(stashBlue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(stashBlue.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color(.systemGroupedBackground))
                .listRowSeparator(.hidden)
            }
        } header: {
            Text("ITEMS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions section

    @ViewBuilder
    private var actionsSection: some View {
        Section {
            Button {
                showMoveContainer = true
            } label: {
                Label("Move Container", systemImage: "arrow.up.right.square")
                    .foregroundStyle(stashBlue)
            }
            Button {
                showPrintPreview = true
            } label: {
                Label("Print Label", systemImage: "printer")
                    .foregroundStyle(stashBlue)
            }
            Button {
                showDeleteConfirm = true
            } label: {
                Label("Delete Container", systemImage: "trash")
                    .foregroundStyle(stashDeleteRed)
            }
        } header: {
            Text("ACTIONS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Item actions

    private func commitItem() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let qty = Int(newItemQty)
        let item = Item(name: name, quantity: qty)
        container.items.append(item)
        container.updatedAt = Date()
        newItemName    = ""
        newItemQty     = ""
        addItemFocused = true   // keep keyboard open for next item
    }

    private func deleteItems(at offsets: IndexSet) {
        let items = offsets.map { sortedItems[$0] }
        for item in items { modelContext.delete(item) }
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
        container.photo     = url.path
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
