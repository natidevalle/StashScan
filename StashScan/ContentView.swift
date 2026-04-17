//
//  ContentView.swift
//  StashScan
//
//  Root view: TabView with Home, Search, and Scan tabs.
//  Home tab hosts the full navigation stack (Locations → Zones → Containers).
//  Search tab is a dedicated full-screen search experience.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Shared design tokens (available across the module)

let stashBlue      = Color(red: 24/255,  green: 95/255,  blue: 165/255)
let stashBlueTint  = Color(red: 230/255, green: 241/255, blue: 251/255)
let stashDeleteRed = Color(red: 226/255, green: 75/255,  blue:  74/255)

// MARK: - Design System colour tokens (DS §2)

extension Color {
    /// Clay accent — #B3673A light / #C97F55 dark (DS §2.1)
    static let dsAccent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.788, green: 0.498, blue: 0.333, alpha: 1)
            : UIColor(red: 0.702, green: 0.404, blue: 0.286, alpha: 1)
    })
    /// Muted accent fill — #E8D5C8 light / #3D2416 dark (DS §2.1)
    static let dsAccentMuted = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.239, green: 0.141, blue: 0.086, alpha: 1)
            : UIColor(red: 0.910, green: 0.835, blue: 0.784, alpha: 1)
    })
    /// Accent foreground text — #6B3318 light / #F0D5C2 dark (DS §2.1)
    static let dsAccentForeground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.941, green: 0.835, blue: 0.761, alpha: 1)
            : UIColor(red: 0.420, green: 0.200, blue: 0.094, alpha: 1)
    })
    /// Muted green success — printer connected (DS §2.2)
    static let dsSuccess = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.75, blue: 0.55, alpha: 1)
            : UIColor(red: 0.20, green: 0.60, blue: 0.40, alpha: 1)
    })
}

// MARK: - Shared list-row icon
// Outline-only, secondaryLabel colour, 20pt (DS §5.1, §7.1).

struct ListIcon: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 20))
            .foregroundStyle(Color(.secondaryLabel))
            .frame(width: 28, height: 28)
    }
}

// MARK: - App routes (non-model navigation values)

enum AppRoute: Hashable {
    case settings
}

// MARK: - Root ContentView (TabView)

struct ContentView: View {
    enum AppTab: Hashable { case home, search, scan }

    @State private var selectedTab: AppTab = .home
    @State private var navigationPath = NavigationPath()

    private var homeIsSelected: Bool   { selectedTab == .home && navigationPath.isEmpty }
    private var searchIsSelected: Bool { selectedTab == .search }
    private var scanIsSelected: Bool   { selectedTab == .scan }

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
            .toolbar(.hidden, for: .tabBar)
            .tabItem { Label("Home", systemImage: "house") }
            .tag(AppTab.home)

            // ── Search tab ─────────────────────────────────────────────
            NavigationStack {
                SearchView()
                    .navigationDestination(for: Container.self) {
                        ContainerDetailView(container: $0)
                    }
                    .navigationDestination(for: Zone.self) {
                        ZoneDetailView(zone: $0)
                    }
                    .navigationDestination(for: Location.self) {
                        LocationDetailView(location: $0)
                    }
            }
            .toolbar(.hidden, for: .tabBar)
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(AppTab.search)

            // ── Scan tab ───────────────────────────────────────────────
            ScannerView(onFound: { container in
                selectedTab = .home
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    navigationPath.append(container)
                }
            }, cancellable: false)
            .toolbar(.hidden, for: .tabBar)
            .tabItem { Label("Scan", systemImage: "qrcode.viewfinder") }
            .tag(AppTab.scan)
        }
        .ignoresSafeArea(.keyboard)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppTabBar(
                homeIsSelected:   homeIsSelected,
                searchIsSelected: searchIsSelected,
                scanIsSelected:   scanIsSelected,
                onHomeTap: {
                    if selectedTab == .home {
                        navigationPath = NavigationPath()
                    } else {
                        selectedTab = .home
                    }
                },
                onSearchTap: { selectedTab = .search },
                onScanTap:   { selectedTab = .scan }
            )
        }
    }
}

// MARK: - Custom tab bar

private struct AppTabBar: View {
    let homeIsSelected:   Bool
    let searchIsSelected: Bool
    let scanIsSelected:   Bool
    let onHomeTap:   () -> Void
    let onSearchTap: () -> Void
    let onScanTap:   () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton("Home",   symbol: "house",              selectedSymbol: "house.fill", isSelected: homeIsSelected,   action: onHomeTap)
                .padding(.top, 20)
            tabButton("Search", symbol: "magnifyingglass",                                  isSelected: searchIsSelected, action: onSearchTap)
                .padding(.top, 20)
            tabButton("Scan",   symbol: "qrcode.viewfinder",                                isSelected: scanIsSelected,   action: onScanTap)
                .padding(.top, 20)
        }
        .frame(height: 49)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private func tabButton(_ title: String, symbol: String, selectedSymbol: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: isSelected ? (selectedSymbol ?? symbol) : symbol)
                    .font(.system(size: 22))
                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundStyle(isSelected ? Color.dsAccent : Color(.secondaryLabel))
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

// MARK: - Home view (locations list only)

private struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Location.name) private var locations: [Location]

    @State private var showAddLocation   = false
    @State private var locationToDelete: Location? = nil
    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            ForEach(locations) { location in
                NavigationLink(value: location) {
                    HStack(spacing: 12) {
                        ListIcon(symbol: "map")
                        Text(location.name)
                            .font(.body)
                    }
                    .padding(.vertical, 10)
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 49)
        }
        .overlay {
            if locations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "map")
                        .font(.system(size: 48))
                        .foregroundColor(Color(.tertiaryLabel))
                    Text("No Locations")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Tap + to add your first location.")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Locations")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddLocation = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color(.label))
                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color(.label))
                }
                .buttonStyle(.plain)
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

// MARK: - Search view (dedicated Search tab)

private struct SearchView: View {
    @Query(sort: \Container.name) private var allContainers: [Container]
    @FocusState private var searchFocused: Bool
    @State private var searchText = ""

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
        VStack(spacing: 0) {
            // ── Search bar ─────────────────────────────────────────────
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 16))
                TextField("Search items, containers, notes…", text: $searchText)
                    .focused($searchFocused)
                    .submitLabel(.search)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // ── Results list ───────────────────────────────────────────
            List {
                if !searchResults.isEmpty {
                    Section {
                        ForEach(searchResults) { result in
                            NavigationLink(value: result.containerForNav) {
                                searchResultRow(result)
                            }
                        }
                    } header: {
                        Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                            .font(.system(size: 14, weight: .regular))
                            .textCase(nil)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 49)
            }
            .overlay { emptyStateOverlay }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                searchFocused = true
            }
        }
    }

    // MARK: Search row

    @ViewBuilder
    private func searchResultRow(_ result: SearchResult) -> some View {
        HStack(spacing: 12) {
            Group {
                switch result.kind {
                case .item:      Image(systemName: "tag")
                case .container: Image(systemName: "archivebox")
                }
            }
            .font(.system(size: 20))
            .foregroundStyle(Color(.secondaryLabel))
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                switch result.kind {
                case .item(let item, let container):
                    HStack(spacing: 4) {
                        Text(item.name)
                            .font(.body).fontWeight(.semibold)
                            .foregroundStyle(Color(.label))
                        if let qty = item.quantity, qty > 1 {
                            Text("×\(qty)")
                                .font(.body)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                    Text(
                        "\(container.zone?.location?.name ?? "?") > " +
                        "\(container.zone?.name ?? "?") > " +
                        "\(container.name)"
                    )
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))

                case .container(let container):
                    Text(container.name)
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(Color(.label))
                    Text(
                        "\(container.zone?.location?.name ?? "?") > " +
                        "\(container.zone?.name ?? "?")"
                    )
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
                }
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: Empty state

    @ViewBuilder
    private var emptyStateOverlay: some View {
        if trimmedQuery.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(Color(.tertiaryLabel))
                Text("Search")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Search for items, containers, and notes.")
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if searchResults.isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
