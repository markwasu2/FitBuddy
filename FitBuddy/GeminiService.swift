import Foundation
import SwiftUI
import GoogleGenerativeAI

class GeminiService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false
    
    private let model = GenerativeModel(name: "gemini-1.5-flash", apiKey: Config.geminiAPIKey)
    
    private var profileManager: ProfileManager?
    private var calendarManager: CalendarManager?
    private var workoutPlanManager: WorkoutPlanManager?
    
    // Helper closures for external actions
    var scheduleWorkout: ((Date, String, String) -> Void)?
    var updateProfile: ((String) -> Void)?
    
    init() {
        // Initialize with welcome message
        let welcomeMessage = ChatMessage(
            content: "Hey! I'm your FitBuddy coach. I can help you with workout plans, answer fitness questions, and keep track of your progress. What would you like to work on today?",
            isFromUser: false,
            timestamp: Date()
        )
        
        self.messages = [welcomeMessage]
    }
    
    func configure(profileManager: ProfileManager, calendarManager: CalendarManager, workoutPlanManager: WorkoutPlanManager) {
        self.profileManager = profileManager
        self.calendarManager = calendarManager
        self.workoutPlanManager = workoutPlanManager
    }
    
    func sendMessage(_ message: String) async {
        await MainActor.run {
            self.isProcessing = true
        }
        
        // Add user message to conversation
        await MainActor.run {
            self.messages.append(ChatMessage(content: message, isFromUser: true, timestamp: Date()))
        }
        
        // Generate conversational response
        let response = await generateConversationalResponse(message)
        
        // Add assistant response
        await MainActor.run {
            self.messages.append(ChatMessage(content: response, isFromUser: false, timestamp: Date()))
            
            // Trim messages to last 50 for performance
            if self.messages.count > 50 {
                let welcomeMessage = self.messages.first!
                let suffixCount = min(49, self.messages.count - 1)
                self.messages = [welcomeMessage] + self.messages.suffix(suffixCount)
            }
            
            self.isProcessing = false
        }
    }
    
    private func generateConversationalResponse(_ userMessage: String) async -> String {
        // Build conversation context
        let recentMessages = messages.suffix(10).map { msg in
            "\(msg.isFromUser ? "User" : "Assistant"): \(msg.content)"
        }.joined(separator: "\n")
        
        // Get user profile info
        let profileInfo = getUserProfileInfo()
        
        // Create the system prompt
        let systemPrompt = """
        You are FitBuddy, a friendly and knowledgeable AI fitness coach. You help users with:
        
        1. **Creating personalized workout plans** - Ask for their goals, fitness level, and equipment, then create specific plans
        2. **Updating workout plans** - Modify existing plans based on their feedback
        3. **Scheduling workouts** - Help them schedule sessions in their calendar
        4. **Profile updates** - Update their age, weight, height, goals, etc.
        5. **Fitness advice** - Answer questions about nutrition, technique, recovery, etc.
        
        **User Profile:** \(profileInfo)
        
        **Recent Conversation:**
        \(recentMessages)
        
        **Current User Message:** \(userMessage)
        
        **Instructions:**
        - Be conversational and direct. Don't ask for information they've already provided.
        - If they want a workout plan, create one immediately with specific exercises, sets, and reps.
        - If they want to schedule something, ask for the date/time and then confirm the scheduling.
        - If they want to update their profile, acknowledge the change and confirm it's saved.
        - If they ask fitness questions, provide specific, actionable advice.
        - Always be helpful and proactive. Don't revert to asking basic questions if they've already provided context.
        
        Respond naturally as a fitness coach would in a conversation.
        """
        
        do {
            // Add timeout to prevent hanging
            let task = Task {
                try await model.generateContent(systemPrompt)
            }
            
            let response = try await withTimeout(seconds: 10) {
                try await task.value
            }
            
            let reply = response.text ?? "I'm here to help! What would you like to work on?"
            
            // Handle specific actions based on the response
            await handleActions(userMessage: userMessage, response: reply)
            
            return reply
        } catch {
            print("Gemini API Error: \(error)")
            return "I'm having trouble connecting right now. Let me help you with a workout plan or fitness advice. What would you like to focus on?"
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private struct TimeoutError: Error {}
    
    private func handleActions(userMessage: String, response: String) async {
        let lowercased = userMessage.lowercased()
        
        // Handle scheduling requests
        if lowercased.contains("schedule") || lowercased.contains("calendar") || lowercased.contains("book") {
            if let (date, time) = parseDateAndTime(userMessage) {
                scheduleWorkout?(date, time, "Workout Session")
            }
        }
        
        // Handle profile updates
        if lowercased.contains("weight") || lowercased.contains("height") || lowercased.contains("age") || 
           lowercased.contains("goal") || lowercased.contains("fitness level") {
            updateProfile?(userMessage)
        }
    }
    
    private func getUserProfileInfo() -> String {
        guard let profile = profileManager else { return "Profile not loaded" }
        
        return """
        Age: \(profile.age)
        Weight: \(profile.weight) kg
        Height: \(profile.height) cm
        Fitness Level: \(profile.fitnessLevel)
        Goals: \(profile.goals.joined(separator: ", "))
        Equipment: \(profile.equipment.joined(separator: ", "))
        """
    }
    
    private func parseDateAndTime(_ text: String) -> (Date, String)? {
        let lowercased = text.lowercased()
        
        // Parse common date patterns
        var targetDate = Date()
        var timeString = "9:00 AM"
        
        if lowercased.contains("tomorrow") {
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        } else if lowercased.contains("today") {
            targetDate = Date()
        } else if lowercased.contains("monday") || lowercased.contains("mon") {
            targetDate = getNextWeekday(2) // Monday = 2
        } else if lowercased.contains("tuesday") || lowercased.contains("tue") {
            targetDate = getNextWeekday(3) // Tuesday = 3
        } else if lowercased.contains("wednesday") || lowercased.contains("wed") {
            targetDate = getNextWeekday(4) // Wednesday = 4
        } else if lowercased.contains("thursday") || lowercased.contains("thu") {
            targetDate = getNextWeekday(5) // Thursday = 5
        } else if lowercased.contains("friday") || lowercased.contains("fri") {
            targetDate = getNextWeekday(6) // Friday = 6
        } else if lowercased.contains("saturday") || lowercased.contains("sat") {
            targetDate = getNextWeekday(7) // Saturday = 7
        } else if lowercased.contains("sunday") || lowercased.contains("sun") {
            targetDate = getNextWeekday(1) // Sunday = 1
        }
        
        // Parse time
        if lowercased.contains("6am") || lowercased.contains("6 am") { timeString = "6:00 AM" }
        else if lowercased.contains("7am") || lowercased.contains("7 am") { timeString = "7:00 AM" }
        else if lowercased.contains("8am") || lowercased.contains("8 am") { timeString = "8:00 AM" }
        else if lowercased.contains("9am") || lowercased.contains("9 am") { timeString = "9:00 AM" }
        else if lowercased.contains("10am") || lowercased.contains("10 am") { timeString = "10:00 AM" }
        else if lowercased.contains("11am") || lowercased.contains("11 am") { timeString = "11:00 AM" }
        else if lowercased.contains("12pm") || lowercased.contains("12 pm") || lowercased.contains("noon") { timeString = "12:00 PM" }
        else if lowercased.contains("1pm") || lowercased.contains("1 pm") { timeString = "1:00 PM" }
        else if lowercased.contains("2pm") || lowercased.contains("2 pm") { timeString = "2:00 PM" }
        else if lowercased.contains("3pm") || lowercased.contains("3 pm") { timeString = "3:00 PM" }
        else if lowercased.contains("4pm") || lowercased.contains("4 pm") { timeString = "4:00 PM" }
        else if lowercased.contains("5pm") || lowercased.contains("5 pm") { timeString = "5:00 PM" }
        else if lowercased.contains("6pm") || lowercased.contains("6 pm") { timeString = "6:00 PM" }
        else if lowercased.contains("7pm") || lowercased.contains("7 pm") { timeString = "7:00 PM" }
        else if lowercased.contains("8pm") || lowercased.contains("8 pm") { timeString = "8:00 PM" }
        else if lowercased.contains("9pm") || lowercased.contains("9 pm") { timeString = "9:00 PM" }
        else if lowercased.contains("10pm") || lowercased.contains("10 pm") { timeString = "10:00 PM" }
        
        return (targetDate, timeString)
    }
    
    private func getNextWeekday(_ weekday: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        
        let daysToAdd = (weekday - todayWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
    }
    
    func clearConversation() {
        messages = [
            ChatMessage(
                content: "Hey! I'm your FitBuddy coach. I can help you with workout plans, answer fitness questions, and keep track of your progress. What would you like to work on today?",
                isFromUser: false,
                timestamp: Date()
            )
        ]
    }
} 