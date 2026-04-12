//
//  StashScanApp.swift
//  StashScan
//
//  Created by Serenity on 12/04/2026.
//

import SwiftUI
import SwiftData

@main
struct StashScanApp: App {
    @State private var printer = PhomemoPrinter()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Location.self,
            Zone.self,
            Container.self,
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(printer)
        }
        .modelContainer(sharedModelContainer)
    }
}
