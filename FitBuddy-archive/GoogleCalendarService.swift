import Foundation
import EventKit

class GoogleCalendarService: ObservableObject {
    @Published var isConnected = false
    @Published var isLoading = false
    
    private let clientID = "YOUR_GOOGLE_CLIENT_ID" // Replace with actual Google Client ID
    private let clientSecret = "YOUR_GOOGLE_CLIENT_SECRET" // Replace with actual Google Client Secret
    private let redirectURI = "com.peregrine.app://oauth2redirect"
    
    private var accessToken: String?
    private var refreshToken: String?
    
    init() {
        loadTokens()
    }
    
    // MARK: - Authentication
    
    func authenticate() {
        isLoading = true
        
        // In a real implementation, this would open Safari for OAuth
        // For now, we'll simulate the authentication flow
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isLoading = false
            self.isConnected = true
            self.saveTokens()
        }
    }
    
    func disconnect() {
        accessToken = nil
        refreshToken = nil
        isConnected = false
        saveTokens()
    }
    
    // MARK: - Calendar Operations
    
    func addWorkoutToGoogleCalendar(title: String, date: Date, description: String, completion: @escaping (Bool) -> Void) {
        guard isConnected else {
            print("❌ Google Calendar not connected")
            completion(false)
            return
        }
        // In a real implementation, this would make an API call to Google Calendar
        // For now, we'll simulate the API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("✅ Added to Google Calendar: \(title)")
            completion(true)
        }
    }
    
    func syncWorkoutsToGoogleCalendar(workouts: [PersonalizedWorkoutPlan]) {
        guard isConnected else {
            print("❌ Google Calendar not connected")
            return
        }
        
        for workout in workouts {
            for day in workout.scheduledDays {
                scheduleWorkoutInGoogleCalendar(workout, on: day)
            }
        }
    }
    
    private func scheduleWorkoutInGoogleCalendar(_ workout: PersonalizedWorkoutPlan, on day: WeekDay) {
        let calendar = Calendar.current
        let now = Date()
        
        // Find next occurrence of this weekday
        var nextDate = now
        while calendar.component(.weekday, from: nextDate) != day.calendarWeekday {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
        }
        
        // Set the time based on preferences
        let timeString = workout.preferences.preferredTime.timeString
        let scheduledDate = parseDateTime(date: nextDate, time: timeString)
        
        addWorkoutToGoogleCalendar(
            title: workout.title,
            date: scheduledDate,
            description: workout.description
        ) { success in
            if success {
                print("🎯 Google Calendar: Scheduled \(workout.title) on \(day.rawValue)")
            }
        }
    }
    
    private func parseDateTime(date: Date, time: String) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Parse time string (e.g., "7:00 AM", "6:00 PM")
        let timeComponents = parseTimeString(time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        return calendar.date(from: components) ?? date
    }
    
    private func parseTimeString(_ timeString: String) -> (hour: Int, minute: Int) {
        let lowercased = timeString.lowercased()
        
        if lowercased.contains("am") || lowercased.contains("pm") {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            if let date = formatter.date(from: timeString) {
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                return (components.hour ?? 9, components.minute ?? 0)
            }
        }
        
        return (9, 0)
    }
    
    // MARK: - Persistence
    
    private func saveTokens() {
        UserDefaults.standard.set(accessToken, forKey: "googleAccessToken")
        UserDefaults.standard.set(refreshToken, forKey: "googleRefreshToken")
        UserDefaults.standard.set(isConnected, forKey: "googleCalendarConnected")
    }
    
    private func loadTokens() {
        accessToken = UserDefaults.standard.string(forKey: "googleAccessToken")
        refreshToken = UserDefaults.standard.string(forKey: "googleRefreshToken")
        isConnected = UserDefaults.standard.bool(forKey: "googleCalendarConnected")
    }
}

// MARK: - Google Calendar Models

struct GoogleCalendarEvent: Codable {
    let summary: String
    let description: String
    let start: GoogleCalendarDateTime
    let end: GoogleCalendarDateTime
    let reminders: GoogleCalendarReminders?
    
    init(summary: String, description: String, start: GoogleCalendarDateTime, end: GoogleCalendarDateTime) {
        self.summary = summary
        self.description = description
        self.start = start
        self.end = end
        self.reminders = GoogleCalendarReminders(useDefault: false, overrides: [
            GoogleCalendarReminder(method: "popup", minutes: 15)
        ])
    }
}

struct GoogleCalendarDateTime: Codable {
    let dateTime: String
    let timeZone: String
    
    init(date: Date) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        self.dateTime = formatter.string(from: date)
        self.timeZone = TimeZone.current.identifier
    }
}

struct GoogleCalendarReminders: Codable {
    let useDefault: Bool
    let overrides: [GoogleCalendarReminder]
}

struct GoogleCalendarReminder: Codable {
    let method: String
    let minutes: Int
} 