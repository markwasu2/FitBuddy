//
//  Persistence.swift
//  FitBuddy
//
//  Created by Mark Wasuwanich on 6/16/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Log the error instead of crashing
            print("Failed to save preview data: \(error)")
            let nsError = error as NSError
            print("Error details: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Peregrine")
        if inMemory {
            if let firstStoreDescription = container.persistentStoreDescriptions.first {
                firstStoreDescription.url = URL(fileURLWithPath: "/dev/null")
            }
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Log the error instead of crashing
                print("Failed to load persistent stores: \(error)")
                print("Error details: \(error), \(error.userInfo)")
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
