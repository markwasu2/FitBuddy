import Foundation
import SwiftUI
import EventKit

class CalendarManager: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var workoutPlans: [WorkoutPlan] = []
    private let eventStore = EKEventStore()
    
    init() {
        loadEvents()
        requestCalendarAccess()
    }
    
    private func requestCalendarAccess() {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        print("Calendar access granted")
                    } else {
                        print("Calendar access denied: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        print("Calendar access granted")
                    } else {
                        print("Calendar access denied: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
    }
    
    private func saveEvents() {
        do {
            let data = try JSONEncoder().encode(events)
            UserDefaults.standard.set(data, forKey: "calendarEvents")
        } catch {
            print("Failed to save events: \(error)")
        }
    }
    
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: "calendarEvents") {
            do {
                events = try JSONDecoder().decode([CalendarEvent].self, from: data)
            } catch {
                print("Failed to load events: \(error)")
            }
        }
    }
    
    func addEvent(title: String, date: Date, time: String) {
        // Parse time string to get actual date with time
        let eventDate = parseDateTime(date: date, time: time)
        
        // Add to local events array on main thread
        let event = CalendarEvent(
            title: title,
            date: eventDate,
            time: time,
            isWorkout: true
        )
        
        DispatchQueue.main.async {
            self.events.append(event)
            print("Event count after append: \(self.events.count)")
            self.saveEvents()
        }
        
        // Add to iOS Calendar
        addToIOSCalendar(title: title, date: eventDate)
        
        print("Scheduled workout: \(title) on \(DateFormatter.prettyDate.string(from: eventDate))")
    }
    
    private func addToIOSCalendar(title: String, date: Date) {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = date
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: date) ?? date
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("Successfully added to iOS Calendar")
        } catch {
            print("Failed to add to iOS Calendar: \(error.localizedDescription)")
        }
    }
    
    private func parseDateTime(date: Date, time: String) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Parse time string (e.g., "9:00 AM", "6:00 PM")
        let timeComponents = parseTimeString(time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        return calendar.date(from: components) ?? date
    }
    
    private func parseTimeString(_ timeString: String) -> (hour: Int, minute: Int) {
        let lowercased = timeString.lowercased()
        
        // Handle common time formats
        if lowercased.contains("am") || lowercased.contains("pm") {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            if let date = formatter.date(from: timeString) {
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                return (components.hour ?? 9, components.minute ?? 0)
            }
        }
        
        // Default to 9 AM if parsing fails
        return (9, 0)
    }
    
    func addWorkoutPlan(_ plan: WorkoutPlan) {
        DispatchQueue.main.async {
            self.workoutPlans.append(plan)
            print("Added workout plan: \(plan.title)")
        }
        
        // Automatically schedule the workout for today at a default time if no specific time is given
        let defaultTime = "6:00 PM"
        addEvent(title: plan.title, date: Date(), time: defaultTime)
    }
    
    func scheduleWorkout(_ plan: WorkoutPlan, date: Date, time: String) {
        print("🎯 CalendarManager: Attempting to schedule workout '\(plan.title)' for \(date) at \(time)")
        
        // Parse the date and time
        let scheduledDate = parseDateTime(date: date, time: time)
        print("🎯 CalendarManager: Parsed scheduled date: \(scheduledDate)")
        
        // Add to local events array on main thread
        let event = CalendarEvent(
            title: plan.title,
            date: scheduledDate,
            time: time,
            isWorkout: true
        )
        
        DispatchQueue.main.async {
            self.events.append(event)
            print("🎯 CalendarManager: Added to local events. Total events: \(self.events.count)")
            self.saveEvents()
        }
        
        // Add to iOS Calendar
        addToIOSCalendar(title: plan.title, date: scheduledDate)
        
        print("🎯 CalendarManager: Successfully scheduled workout: \(plan.title) for \(DateFormatter.prettyDate.string(from: scheduledDate))")
    }
    
    func getUpcomingWorkouts() -> [CalendarEvent] {
        let now = Date()
        return events.filter { $0.date > now }.sorted { $0.date < $1.date }
    }
}

// MARK: - Calendar Event Model
struct CalendarEvent: Identifiable, Codable {
    var id: UUID = UUID()
    let title: String
    let date: Date
    let time: String
    let isWorkout: Bool
    
    var formattedDate: String {
        DateFormatter.prettyDate.string(from: date)
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