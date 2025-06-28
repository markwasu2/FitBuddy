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