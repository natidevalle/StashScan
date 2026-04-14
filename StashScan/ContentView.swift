//
//  ContentView.swift
//  StashScan
//
//  Root view: TabView with Home and Scan tabs.
//  Home tab hosts the full navigation stack (Locations → Zones → Containers).
//

import SwiftUI
import SwiftData

// MARK: - Shared design tokens (available across the module)

let stashBlue      = Color(red: 24/255,  green: 95/255,  blue: 165/255)
let stashBlueTint  = Color(red: 230/255, green: 241/255, blue: 251/255)
let stashDeleteRed = Color(red: 226/255, green: 75/255,  blue:  74/255)

// MARK: - Shared list-row icon
// Outline-only, primary label colour, no background.

struct ListIcon: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 17))
            .foregroundStyle(.primary)
            .frame(width: 28, height: 28)
    }
}

// MARK: - App routes (non-model navigation values)

enum AppRoute: Hashable {
    case settings
}

// MARK: - Root ContentView (TabView)

struct ContentView: View {
    // .inNav has no matching tab item tag → no tab highlighted when navigating deep.
    enum AppTab: Hashable { case home, scan, inNav }

    @State private var selectedTab: AppTab = .home
    @State private var navigationPath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {

            // ── Home tab ───────────────────────────────────────────────
            NavigationStack(path: $navigationPath) {
                HomeView()
                    .navigationDestination(for: Location.self) {
                        LocationDetailView(location: $0)
                    }
                    .navigationDestination(for: Zone.self) {
                        ZoneDetailView(zone: $0)
                    }
                    .navigationDestination(for: Container.self) {
                        ContainerDetailView(container: $0)
                    }
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .settings: SettingsView()
                        }
                    }
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(AppTab.home)

            // ── Scan tab ───────────────────────────────────────────────
            ScannerView(onFound: { container in
                selectedTab = .home
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    navigationPath.append(container)
                }
            }, cancellable: false)
            .tabItem { Label("Scan", systemImage: "qrcode.viewfinder") }
            .tag(AppTab.scan)
        }
        // Deselect Home tab when navigating into the stack; reselect when back at root.
        .onChange(of: navigationPath.count) { _, count in
            if count > 0, selectedTab == .home  { selectedTab = .inNav }
            else if count == 0, selectedTab == .inNav { selectedTab = .home }
        }
        // Tapping Home tab from a child screen pops to root.
        .onChange(of: selectedTab) { _, tab in
            if tab == .home, !navigationPath.isEmpty {
                navigationPath = NavigationPath()
            }
        }
    }
}

// MARK: - Search result model

private struct SearchResult: Identifiable {
    let id = UUID()

    enum Kind {
        case item(Item, Container)   // item name matched
        case container(Container)    // container name / notes matched
    }

    let kind: Kind
    let isExact: Bool

    var containerForNav: Container {
        switch kind {
        case .item(_, let c): return c
        case .container(let c): return c
        }
    }
}

// MARK: - Home view (locations list + search)

private struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Location.name) private var locations: [Location]
    @Query(sort: \Container.name) private var allContainers: [Container]

    @State private var searchText        = ""
    @State private var isSearchActive    = false
    @State private var showAddLocation   = false
    @State private var locationToDelete: Location? = nil
    @State private var showDeleteConfirm = false

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private var searchResults: [SearchResult] {
        guard !trimmedQuery.isEmpty else { return [] }
        let lower = trimmedQuery.lowercased()
        var results: [SearchResult] = []

        for container in allContainers {
            for item in container.items {
                let itemLower = item.name.lowercased()
                guard itemLower.contains(lower) else { continue }
                results.append(SearchResult(
                    kind: .item(item, container),
                    isExact: itemLower == lower
                ))
            }
            let cLower = container.name.lowercased()
            let nLower = container.notes.lowercased()
            if cLower.contains(lower) || nLower.contains(lower) {
                results.append(SearchResult(
                    kind: .container(container),
                    isExact: cLower == lower || nLower == lower
                ))
            }
        }

        return results.sorted { a, b in
            let aItem: Bool; if case .item = a.kind { aItem = true } else { aItem = false }
            let bItem: Bool; if case .item = b.kind { bItem = true } else { bItem = false }
            if aItem != bItem { return aItem }
            if a.isExact != b.isExact { return a.isExact }
            return a.containerForNav.name
                .localizedCaseInsensitiveCompare(b.containerForNav.name) == .orderedAscending
        }
    }

    var body: some View {
        SearchListView(
            searchText: $searchText,
            isSearchActive: $isSearchActive,
            locations: locations,
            searchResults: searchResults,
            trimmedQuery: trimmedQuery,
            locationToDelete: $locationToDelete,
            showDeleteConfirm: $showDeleteConfirm
        )
        .navigationTitle("Locations")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddLocation = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showAddLocation) {
            AddEditLocationView()
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

    private func deleteMessage(for location: Location) -> String {
        let zoneCount = location.zones.count
        let containerCount = location.zones.reduce(0) { $0 + $1.containers.count }
        if containerCount > 0 {
            return "This will delete \(zoneCount) zone\(zoneCount == 1 ? "" : "s") and " +
                   "\(containerCount) container\(containerCount == 1 ? "" : "s") and all their contents."
        } else if zoneCount > 0 {
            return "This will delete \(zoneCount) zone\(zoneCount == 1 ? "" : "s")."
        } else {
            return "This location is empty."
        }
    }
}

// MARK: - Search list view

private struct SearchListView: View {
    @FocusState private var searchFocused: Bool

    @Binding var searchText: String
    @Binding var isSearchActive: Bool
    let locations: [Location]
    let searchResults: [SearchResult]
    let trimmedQuery: String
    @Binding var locationToDelete: Location?
    @Binding var showDeleteConfirm: Bool

    var body: some View {
        List {
            if isSearchActive {
                // ── Search mode: hide location list, show results only ─
                if !searchResults.isEmpty {
                    Section {
                        ForEach(searchResults) { result in
                            NavigationLink(value: result.containerForNav) {
                                searchResultRow(result)
                            }
                        }
                    } header: {
                        Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .textCase(nil)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                // ── Normal hierarchy ─────────────────────────────────
                ForEach(locations) { location in
                    NavigationLink(value: location) {
                        HStack(spacing: 12) {
                            ListIcon(symbol: "mappin.circle")
                            Text(location.name)
                                .font(.system(size: 17))
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            locationToDelete = location
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            // Custom search bar — left icon swaps between magnifier and back chevron.
            HStack(spacing: 8) {
                if isSearchActive {
                    Button {
                        searchText = ""
                        isSearchActive = false
                        searchFocused = false
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                    }
                } else {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                }

                TextField("Search items, containers, notes…", text: $searchText)
                    .focused($searchFocused)
                    .onChange(of: searchFocused) { _, focused in
                        if focused { isSearchActive = true }
                    }
                    .submitLabel(.search)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .overlay { emptyStateOverlay }
    }

    // MARK: Search row

    @ViewBuilder
    private func searchResultRow(_ result: SearchResult) -> some View {
        HStack(spacing: 12) {
            Group {
                switch result.kind {
                case .item:      Image(systemName: "tag")
                case .container: Image(systemName: "shippingbox")
                }
            }
            .font(.system(size: 17))
            .foregroundStyle(.primary)
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                switch result.kind {
                case .item(let item, let container):
                    HStack(spacing: 0) {
                        Text(item.name)
                            .font(.system(size: 13, weight: .bold))
                        if let qty = item.quantity, qty > 1 {
                            Text(" ×\(qty)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(
                        "\(container.name) · " +
                        "\(container.zone?.location?.name ?? "?") > " +
                        "\(container.zone?.name ?? "?")"
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                case .container(let container):
                    Text(container.name)
                        .font(.system(size: 13, weight: .bold))
                    Text(
                        "\(container.zone?.location?.name ?? "?") > " +
                        "\(container.zone?.name ?? "?")"
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: Empty state

    @ViewBuilder
    private var emptyStateOverlay: some View {
        if !isSearchActive && locations.isEmpty {
            ContentUnavailableView(
                "No Locations",
                systemImage: "mappin.slash",
                description: Text("Tap + to add your first location.")
            )
        } else if isSearchActive && !trimmedQuery.isEmpty && searchResults.isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
