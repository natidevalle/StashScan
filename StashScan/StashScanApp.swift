//
//  StashScanApp.swift
//  StashScan
//
//  Created by Serenity on 12/04/2026.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct StashScanApp: App {
    @State private var printer = PhomemoPrinter()

    init() {
        // iOS 26 changed the back button default to show only the chevron with no title.
        // Restore the title by explicitly configuring UIBarButtonItemAppearance for all
        // three standard UINavigationBar appearance slots.
        let backItem = UIBarButtonItemAppearance(style: .plain)
        backItem.normal.titleTextAttributes = [.foregroundColor: UIColor.tintColor]

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backButtonAppearance = backItem

        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

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
