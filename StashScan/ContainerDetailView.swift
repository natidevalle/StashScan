//
//  ContainerDetailView.swift
//  StashScan
//
//  Placeholder detail screen for a container.
//

import SwiftUI
import SwiftData

struct ContainerDetailView: View {
    let container: Container

    var body: some View {
        List {
            Section {
                LabeledContent("Type", value: container.type.rawValue)
                if !container.notes.isEmpty {
                    LabeledContent("Notes", value: container.notes)
                }
            }

            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Items coming soon")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(container.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        ContainerDetailView(container: {
            let loc = Location(name: "Garage")
            let zone = Zone(name: "Wall Shelves", location: loc)
            return Container(
                name: "Tool Box",
                type: .box,
                notes: "Hand tools — hammer, screwdrivers, pliers",
                locationId: loc.id,
                zoneId: zone.id,
                zone: zone
            )
        }())
    }
    .modelContainer(previewContainer)
}
