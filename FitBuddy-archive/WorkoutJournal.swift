import Foundation
import SwiftUI

class WorkoutJournal: ObservableObject {
    @Published var entries: [WorkoutEntry] = []
    
    func upsert(_ entry: WorkoutEntry) {
        // Simple implementation - in a real app this would save to persistent storage
        print("Saving workout entry: \(entry)")
        
        // Remove existing entry for the same date if it exists
        entries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: entry.date) }
        
        // Add the new entry
        entries.append(entry)
    }
    
    func entry(for date: Date) -> WorkoutEntry? {
        // Simple implementation - in a real app this would load from persistent storage
        return entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func delete(_ entry: WorkoutEntry) {
        entries.removeAll { $0.id == entry.id }
    }
} 