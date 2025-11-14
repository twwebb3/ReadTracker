//
//  ReadTrackerApp.swift
//  ReadTracker
//
//  Created by Theodore Webb on 11/14/25.
//

import SwiftUI

@main
struct ReadTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
