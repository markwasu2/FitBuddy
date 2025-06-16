//
//  FitBuddyApp.swift
//  FitBuddy
//
//  Created by Mark Wasuwanich on 6/16/25.
//

import SwiftUI

@main
struct FitBuddyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
