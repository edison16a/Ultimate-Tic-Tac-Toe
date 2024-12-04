//
//  Ultimate_Tic_Tac_ToeApp.swift
//  Ultimate Tic-Tac-Toe
//
//  Created by Edison Law on 12/3/24.
//

import SwiftUI
import SwiftData

@main
struct Ultimate_Tic_Tac_ToeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
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
        }
        .modelContainer(sharedModelContainer)
    }
}
