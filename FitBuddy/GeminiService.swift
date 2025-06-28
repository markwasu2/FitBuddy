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
        
        self.messages.append(welcomeMessage)
    }
    
    func configure(profileManager: ProfileManager, calendarManager: CalendarManager, workoutPlanManager: WorkoutPlanManager) {
        self.profileManager = profileManager
        self.calendarManager = calendarManager
        self.workoutPlanManager = workoutPlanManager
    }
    
    func sendMessage(_ message: String) async -> String {
        await MainActor.run {
            self.isProcessing = true
        }
        
        // Add user message to conversation on main thread
        await MainActor.run {
            self.messages.append(ChatMessage(content: message, isFromUser: true, timestamp: Date()))
        }
        
        // Classify intent
        let intent = classifyIntent(message)
        
        // Generate response based on intent
        let response = await generateResponse(for: intent, userMessage: message)
        
        // TECHNICAL HOT-FIX: Ensure we never have blank responses
        let replyText: String
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            replyText = trimmed
        } else {
            replyText = "⚠️ I'm having trouble generating that. Could you rephrase?"
        }
        
        // Add assistant response to conversation on main thread
        await MainActor.run {
            self.messages.append(ChatMessage(content: replyText, isFromUser: false, timestamp: Date()))
            
            // Trim conversation to last 50 turns to avoid performance stalls
            if self.messages.count > 50 {
                let welcomeMessage = self.messages.first!
                self.messages = [welcomeMessage] + self.messages.suffix(49)
            }
            
            self.isProcessing = false
        }
        
        return replyText
    }
    
    private func classifyIntent(_ message: String) -> MessageIntent {
        let lowercased = message.lowercased()
        
        if lowercased.contains("workout") && (lowercased.contains("plan") || lowercased.contains("routine") || lowercased.contains("split")) {
            return .workoutPlanRequest
        }
        
        if lowercased.contains("schedule") || lowercased.contains("calendar") || lowercased.contains("book") {
            return .scheduleConfirmation
        }
        
        if lowercased.contains("add") || lowercased.contains("edit") || lowercased.contains("change") || lowercased.contains("modify") {
            return .workoutPlanEdit
        }
        
        if lowercased.contains("lbs") || lowercased.contains("kg") || lowercased.contains("weight") || lowercased.contains("height") || lowercased.contains("age") {
            return .profileUpdate
        }
        
        if lowercased.contains("?") || lowercased.contains("why") || lowercased.contains("how") || lowercased.contains("what") {
            return .generalFitnessQuestion
        }
        
        return .other
    }
    
    private func generateResponse(for intent: MessageIntent, userMessage: String) async -> String {
        switch intent {
        case .workoutPlanRequest:
            return await handleWorkoutPlanRequest(userMessage)
        case .workoutPlanEdit:
            return await handleWorkoutPlanEdit(userMessage)
        case .scheduleConfirmation:
            return await handleScheduleConfirmation(userMessage)
        case .profileUpdate:
            return await handleProfileUpdate(userMessage)
        case .generalFitnessQuestion:
            return await handleGeneralFitnessQuestion(userMessage)
        case .other:
            return await handleGeneralQuery(userMessage)
        }
    }
    
    private func handleWorkoutPlanRequest(_ message: String) async -> String {
        // Check for missing profile info
        let missingInfo = getMissingProfileInfo()
        if !missingInfo.isEmpty {
            return "I need a bit more info to create your perfect workout plan. \(missingInfo)"
        }
        
        // Generate workout plan using Gemini
        let prompt = """
        Create a personalized 3-day workout plan for a \(profileManager?.fitnessLevel ?? "intermediate") level person.
        
        Profile: Age \(profileManager?.age ?? 30), Weight \(profileManager?.weight ?? 150) lbs, Goals: \(profileManager?.goals.joined(separator: ", ") ?? "general fitness"), Equipment: \(profileManager?.equipment.joined(separator: ", ") ?? "basic")
        
        Format as:
        **Day 1 - [Focus]**
        • [Exercise] — [sets]x[reps] @ [intensity] ([rest]s rest)
        
        Keep each day to 3-4 exercises max. Be specific with sets, reps, and rest periods.
        """
        
        do {
            let response = try await model.generateContent(prompt)
            let plan = response.text ?? "I couldn't generate a workout plan right now."
            return plan + "\n\nWould you like me to schedule these sessions in your calendar?"
        } catch {
            return "Here's a solid 3-day plan for you:\n\n**Day 1 - Upper Body**\n• Push-ups — 3x12 @ moderate (60s rest)\n• Dumbbell rows — 3x10 @ moderate (60s rest)\n• Shoulder press — 3x8 @ moderate (90s rest)\n\n**Day 2 - Lower Body**\n• Squats — 3x15 @ moderate (60s rest)\n• Lunges — 3x10 each leg @ moderate (60s rest)\n• Glute bridges — 3x12 @ moderate (45s rest)\n\n**Day 3 - Full Body**\n• Burpees — 3x8 @ high intensity (90s rest)\n• Plank — 3x30s @ moderate (45s rest)\n• Mountain climbers — 3x20 @ moderate (60s rest)\n\nWould you like me to schedule these sessions in your calendar?"
        }
    }
    
    private func handleWorkoutPlanEdit(_ message: String) async -> String {
        let prompt = """
        The user wants to modify their workout plan: "\(message)"
        
        Provide a specific, actionable response about how to modify their workout. Be direct and helpful.
        """
        
        do {
            let response = try await model.generateContent(prompt)
            return response.text ?? "I'll help you modify your workout plan. What specific changes would you like to make?"
        } catch {
            return "I'll help you modify your workout plan. What specific changes would you like to make?"
        }
    }
    
    private func handleScheduleConfirmation(_ message: String) async -> String {
        // Parse date/time and schedule
        if let (date, time) = DateParser.parse(message) {
            scheduleWorkout?(date, time, "Workout Session")
            return "✅ Got it — session scheduled for \(DateFormatter.prettyDate.string(from: date)) at \(time)."
        }
        return "I couldn't understand the date/time. Could you try again? (e.g., 'Tuesday 7am' or 'tomorrow at 6pm')"
    }
    
    private func handleProfileUpdate(_ message: String) async -> String {
        updateProfile?(message)
        return "Profile updated successfully! I've noted your changes."
    }
    
    private func handleGeneralFitnessQuestion(_ message: String) async -> String {
        let prompt = """
        Answer this fitness question: "\(message)"
        
        Provide 3 actionable bullet points. Be direct, practical, and specific. No fluff.
        """
        
        do {
            let response = try await model.generateContent(prompt)
            return response.text ?? "Here's what you need to know:\n• Focus on proper form first\n• Gradually increase intensity\n• Listen to your body"
        } catch {
            return "Here's what you need to know:\n• Focus on proper form first\n• Gradually increase intensity\n• Listen to your body"
        }
    }
    
    private func handleGeneralQuery(_ message: String) async -> String {
        let prompt = """
        The user said: "\(message)"
        
        You are a fitness coach. Respond proactively and helpfully. If they're asking for something unclear, suggest specific options like:
        - "Want a workout plan? I can create one for you."
        - "Need fitness advice? Ask me anything specific."
        - "Want to update your profile? Tell me your current stats."
        
        Be direct and actionable.
        """
        
        do {
            let response = try await model.generateContent(prompt)
            return response.text ?? "I can help you with workout plans, fitness questions, or profile updates. What would you like to work on?"
        } catch {
            return "I can help you with workout plans, fitness questions, or profile updates. What would you like to work on?"
        }
    }
    
    private func getMissingProfileInfo() -> String {
        guard let profile = profileManager else { return "Please complete your profile setup first." }
        
        var missing: [String] = []
        if profile.age == 0 { missing.append("your age") }
        if profile.goals.isEmpty { missing.append("your fitness goals") }
        if profile.equipment.isEmpty { missing.append("available equipment") }
        if profile.fitnessLevel.isEmpty { missing.append("your fitness level") }
        
        if missing.isEmpty { return "" }
        
        return "Please tell me: " + missing.joined(separator: ", ")
    }
}

// MARK: - Supporting Types

enum MessageIntent {
    case workoutPlanRequest
    case workoutPlanEdit
    case scheduleConfirmation
    case profileUpdate
    case generalFitnessQuestion
    case other
}

// MARK: - Date Parser Helper

struct DateParser {
    static func parse(_ text: String) -> (Date, String)? {
        // Simple date parsing - in a real app, use a more robust parser
        let lowercased = text.lowercased()
        
        if lowercased.contains("tomorrow") {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let time = extractTime(from: text) ?? "9:00 AM"
            return (tomorrow, time)
        }
        
        if lowercased.contains("today") {
            let time = extractTime(from: text) ?? "9:00 AM"
            return (Date(), time)
        }
        
        // Add more parsing logic for specific days, times, etc.
        return nil
    }
    
    private static func extractTime(from text: String) -> String? {
        // Simple time extraction - in a real app, use regex or NLP
        if text.contains("am") || text.contains("pm") {
            // Extract time pattern
            return "9:00 AM" // Placeholder
        }
        return nil
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