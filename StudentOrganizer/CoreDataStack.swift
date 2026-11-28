import CoreData
  
/// Centralized Core Data manager used throughout the app.
/// A single shared instance prevents multiple database containers
/// from being created and ensures all screens work with the same data source.
final class CoreDataStack {
  
    /// Shared singleton instance so every view accesses the same Core Data stack.
    static let shared = CoreDataStack()
  
    /// Persistent container that loads the app's data model and manages
    /// the connection between Core Data objects and the SQLite database.
    let container: NSPersistentContainer
  
    /// Exposes the main context used by the UI so changes can be made
    /// and saved from anywhere in the application.
    var context: NSManagedObjectContext { container.viewContext }
  
    private init() {
        // The container name must match the data model file name,
        // otherwise Core Data cannot locate and load the application's schema.
        container = NSPersistentContainer(name: "StudentOrganizer")
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                // A failed store load means no data can be read or written,
                // so the app cannot safely continue running.
                fatalError("Core Data failed to load: \(error)")
            }
            // Useful during development to verify where the database file
            // is being stored on the device or simulator.
            print("Database file: \(storeDescription.url?.path ?? "unknown")")
        }
    }
  
    /// Saves pending changes so newly created, edited, or deleted records
    /// persist even after the app is closed and reopened.
    func save() {
        // Avoids unnecessary save operations when no data has changed,
        // improving performance and reducing disk writes.
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            // Logs save failures to help diagnose data persistence issues
            // without immediately crashing the application.
            print("Core Data save failed: \(error)")
        }
    }
} 
