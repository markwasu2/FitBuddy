import Foundation
import SwiftUI

class CalendarManager: ObservableObject {
    @Published var events: [String] = []
    
    func addEvent(title: String, date: Date, time: String) {
        let event = "\(title) on \(DateFormatter.prettyDate.string(from: date)) at \(time)"
        events.append(event)
        print("Scheduled: \(event)")
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let prettyDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
} 