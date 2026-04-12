//
//  SettingsView.swift
//  StashScan
//
//  Placeholder settings screen.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "gearshape.2")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Settings coming soon")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
