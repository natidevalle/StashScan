//
//  ContentView.swift
//  StashScan
//
//  Home screen: location hierarchy + full-text search + QR scan entry point.
//

import SwiftUI
import SwiftData

// MARK: - Search result model

private struct SearchResult: Identifiable {
    var id: UUID { container.id }
    let container: Container
    /// The first item whose name matched the query, if the match was item-level.
    let matchingItem: Item?
    /// True when any field exactly equals the query — used for ranking.
    let isExact: Bool

    var locationPath: String {
        let loc  = container.zone?.location?.name ?? "?"
        let zone = container.zone?.name ?? "?"
        return "\(loc) › \(zone)"
    }
}

// MARK: - ContentView

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Location.name) private var locations: [Location]
    @Query(sort: \Container.name) private var allContainers: [Container]

    @State private var searchText = ""
    @State private var showAddLocation = false
    @State private var locationToEdit: Location? = nil
    @State private var locationToDelete: Location? = nil
    @State private var showDeleteConfirm = false

    // Scanner + programmatic navigation
    @State private var showScanner = false
    @State private var navigationPath = NavigationPath()

    // MARK: Search

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private var searchResults: [SearchResult] {
        guard !trimmedQuery.isEmpty else { return [] }
        let lower = trimmedQuery.lowercased()
        var results: [SearchResult] = []

        for container in allContainers {
            let name  = container.name.lowercased()
            let notes = container.notes.lowercased()
            let zone  = (container.zone?.name ?? "").lowercased()
            let loc   = (container.zone?.location?.name ?? "").lowercased()

            // Prefer an exact item match; fall back to partial.
            let exactItem   = container.items.first { $0.name.lowercased() == lower }
            let partialItem = exactItem
                ?? container.items.first { $0.name.lowercased().contains(lower) }

            let fieldHit = name.contains(lower) || notes.contains(lower)
                        || zone.contains(lower)  || loc.contains(lower)

            guard fieldHit || partialItem != nil else { continue }

            let isExact = name == lower || notes == lower
                       || zone == lower || loc == lower
                       || exactItem != nil

            results.append(SearchResult(
                container: container,
                matchingItem: partialItem,
                isExact: isExact
            ))
        }

        // Exact matches first; within each tier sort alphabetically by container name.
        return results.sorted {
            if $0.isExact != $1.isExact { return $0.isExact }
            return $0.container.name
                .localizedCaseInsensitiveCompare($1.container.name) == .orderedAscending
        }
    }

    // MARK: Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                if trimmedQuery.isEmpty {
                    // ── Normal hierarchy ───────────────────────────────
                    ForEach(locations) { location in
                        NavigationLink(destination: LocationDetailView(location: location)) {
                            Label(location.name, systemImage: "house")
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                locationToDelete = location
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                locationToEdit = location
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                } else {
                    // ── Search results ────────────────────────────────
                    ForEach(searchResults) { result in
                        NavigationLink(value: result.container) {
                            searchResultRow(result)
                        }
                    }
                }
            }
            .navigationTitle("StashScan")
            .searchable(text: $searchText, prompt: "Search containers, items, notes…")
            .overlay { emptyStateOverlay }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddLocation = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                }
                ToolbarItem(placement: .bottomBar) { Spacer() }
                ToolbarItem(placement: .bottomBar) {
                    Button { showScanner = true } label: {
                        Label("Scan", systemImage: "qrcode.viewfinder")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .bottomBar) { Spacer() }
            }
            // Programmatic destination: scan result jumps straight to ContainerDetailView.
            // Also used by search result NavigationLink(value:) rows.
            .navigationDestination(for: Container.self) { container in
                ContainerDetailView(container: container)
            }
            .sheet(isPresented: $showAddLocation) {
                AddEditLocationView()
            }
            .sheet(item: $locationToEdit) { location in
                AddEditLocationView(location: location)
            }
            .confirmationDialog(
                "Delete \"\(locationToDelete?.name ?? "")\"?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let loc = locationToDelete { loc.delete(from: modelContext) }
                    locationToDelete = nil
                }
                Button("Cancel", role: .cancel) { locationToDelete = nil }
            } message: {
                if let loc = locationToDelete { Text(deleteMessage(for: loc)) }
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            ScannerView { container in
                showScanner = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    navigationPath.append(container)
                }
            }
        }
    }

    // MARK: - Search result row

    @ViewBuilder
    private func searchResultRow(_ result: SearchResult) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: containerIcon(for: result.container.type))
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(result.container.name)
                if let item = result.matchingItem {
                    Label(item.name, systemImage: "tag.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(result.locationPath)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyStateOverlay: some View {
        if trimmedQuery.isEmpty && locations.isEmpty {
            ContentUnavailableView(
                "No Locations",
                systemImage: "house.slash",
                description: Text("Tap + to add your first location.")
            )
        } else if !trimmedQuery.isEmpty && searchResults.isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
    }

    // MARK: - Helpers

    private func containerIcon(for type: ContainerType) -> String {
        switch type {
        case .box:    return "shippingbox"
        case .bag:    return "bag"
        case .bin:    return "trash"
        case .drawer: return "square.stack"
        case .shelf:  return "books.vertical"
        case .other:  return "archivebox"
        }
    }

    private func deleteMessage(for location: Location) -> String {
        let zoneCount = location.zones.count
        let containerCount = location.zones.reduce(0) { $0 + $1.containers.count }
        if containerCount > 0 {
            return "This will delete \(zoneCount) zone\(zoneCount == 1 ? "" : "s") and \(containerCount) container\(containerCount == 1 ? "" : "s") and all their contents."
        } else if zoneCount > 0 {
            return "This will delete \(zoneCount) zone\(zoneCount == 1 ? "" : "s")."
        } else {
            return "This location is empty."
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
