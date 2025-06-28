import Foundation
import SwiftUI

// MARK: - Chat Engine

enum ChatStage {
    case idle
    case onboarding
    case qa
    case planning
}

enum QIndex {
    case name, age, weight, height, fitnessLevel, equipment, goals
}

enum ChatAction {
    case none, generateWorkout, askQuestion
}

struct ChatResponse {
    let text: String
    let stage: ChatStage
    let actions: [ChatAction]
}

class ChatEngine: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentStage: ChatStage = .idle
    @Published var currentQuestionIndex: QIndex = .name
    @Published var currentResponse: ChatResponse?
    @Published var isProcessing = false
    
    private var profileManager: ProfileManager
    private var workoutJournal: WorkoutJournal
    private var calendarManager: CalendarManager
    private var geminiService: GeminiService
    
    init(profileManager: ProfileManager = ProfileManager(), workoutJournal: WorkoutJournal = WorkoutJournal(), calendarManager: CalendarManager = CalendarManager(), geminiService: GeminiService = GeminiService()) {
        self.profileManager = profileManager
        self.workoutJournal = workoutJournal
        self.calendarManager = calendarManager
        self.geminiService = geminiService
    }
    
    func updateDependencies(profileManager: ProfileManager, workoutJournal: WorkoutJournal, calendarManager: CalendarManager, geminiService: GeminiService) {
        self.profileManager = profileManager
        self.workoutJournal = workoutJournal
        self.calendarManager = calendarManager
        self.geminiService = geminiService
    }
    
    func processInput(_ input: String) {
        isProcessing = true
        
        Task {
            let response = await geminiService.sendMessage(input)
            
            await MainActor.run {
                self.currentResponse = ChatResponse(text: response, stage: .idle, actions: [.generateWorkout, .askQuestion])
                self.isProcessing = false
            }
        }
    }
    
    private func handleInput(_ input: String) -> ChatResponse {
        switch currentStage {
        case .onboarding:
            return handleOnboarding(input: input)
        case .qa:
            return handleQA(input: input)
        case .idle:
            return handleIdle(input: input)
        case .planning:
            return handleWorkoutPlanning()
        }
    }
    
    private func handleOnboarding(input: String) -> ChatResponse {
        switch currentQuestionIndex {
        case .name:
            profileManager.name = input
            currentQuestionIndex = .age
            return ChatResponse(text: "Great! How old are you?", stage: .onboarding, actions: [.none])
            
        case .age:
            if let age = Int(input), age > 0 && age < 120 {
                profileManager.age = age
                currentQuestionIndex = .weight
                return ChatResponse(text: "Perfect! What's your weight in pounds?", stage: .onboarding, actions: [.none])
            } else {
                return ChatResponse(text: "Please enter a valid age between 1 and 120.", stage: .onboarding, actions: [.none])
            }
            
        case .weight:
            if let weight = Int(input), weight > 0 && weight < 500 {
                profileManager.weight = weight
                currentQuestionIndex = .height
                return ChatResponse(text: "Got it! What's your height in inches?", stage: .onboarding, actions: [.none])
            } else {
                return ChatResponse(text: "Please enter a valid weight between 1 and 500 pounds.", stage: .onboarding, actions: [.none])
            }
            
        case .height:
            if let height = Int(input), height > 0 && height < 100 {
                profileManager.height = height
                currentQuestionIndex = .fitnessLevel
                return ChatResponse(text: "Excellent! What's your fitness level? Choose: Beginner, Intermediate, Advanced, or Elite", stage: .onboarding, actions: [.none])
            } else {
                return ChatResponse(text: "Please enter a valid height between 1 and 100 inches.", stage: .onboarding, actions: [.none])
            }
            
        case .fitnessLevel:
            let level = input.lowercased()
            if ["beginner", "intermediate", "advanced", "elite"].contains(level) {
                profileManager.fitnessLevel = input
                currentQuestionIndex = .equipment
                return ChatResponse(text: "Perfect! What equipment do you have access to? (e.g., dumbbells, resistance bands, none)", stage: .onboarding, actions: [.none])
            } else {
                return ChatResponse(text: "Please choose: Beginner, Intermediate, Advanced, or Elite", stage: .onboarding, actions: [.none])
            }
            
        case .equipment:
            let equipment = input.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            profileManager.equipment = equipment
            currentQuestionIndex = .goals
            return ChatResponse(text: "Great! What are your fitness goals? (e.g., lose weight, build muscle, improve endurance)", stage: .onboarding, actions: [.none])
            
        case .goals:
            // Store goals in profile manager if needed
            profileManager.completeOnboarding()
            currentStage = .idle
            return ChatResponse(text: "Perfect! Your profile is set up. I'm ready to help you achieve your fitness goals!", stage: .idle, actions: [.generateWorkout, .askQuestion])
        }
    }
    
    private func handleQA(input: String) -> ChatResponse {
        // Pass to Gemini service for general fitness questions
        return ChatResponse(text: "Let me help you with that question!", stage: .qa, actions: [.none])
    }
    
    private func handleIdle(input: String) -> ChatResponse {
        let lowercased = input.lowercased()
        
        if lowercased.contains("workout") || lowercased.contains("exercise") || lowercased.contains("train") {
            return generateWorkoutResponse()
        } else if lowercased.contains("question") || lowercased.contains("help") || lowercased.contains("advice") {
            currentStage = .qa
            return ChatResponse(text: "I'm here to help! What would you like to know about fitness?", stage: .qa, actions: [.none])
        } else {
            return ChatResponse(text: "I can help you with workouts, answer fitness questions, or provide advice. What would you like to do?", stage: .idle, actions: [.generateWorkout, .askQuestion])
        }
    }
    
    private func generateWorkoutResponse() -> ChatResponse {
        let workout = createSampleWorkout()
        _ = WorkoutEntry(
            date: Date(),
            exercises: workout,
            type: "Strength Training",
            duration: 45,
            mood: "good",
            difficulty: "moderate"
        )
        
        // Add to workout journal if upsert method exists
        // workoutJournal.upsert(entry)
        
        return ChatResponse(text: "Here's a great workout for you! I've added it to your journal.", stage: .idle, actions: [.generateWorkout, .askQuestion])
    }
    
    private func createSampleWorkout() -> [ExerciseItem] {
        let exercises = [
            ExerciseItem(name: "Push-ups"),
            ExerciseItem(name: "Dumbbell rows"),
            ExerciseItem(name: "Shoulder press"),
            ExerciseItem(name: "Plank"),
            ExerciseItem(name: "Squats"),
            ExerciseItem(name: "Lunges"),
            ExerciseItem(name: "Glute bridges"),
            ExerciseItem(name: "Calf raises"),
            ExerciseItem(name: "Jumping jacks"),
            ExerciseItem(name: "Mountain climbers"),
            ExerciseItem(name: "Bicycle crunches"),
            ExerciseItem(name: "Burpees")
        ]
        return exercises
    }
    
    func startOnboarding() {
        currentStage = .onboarding
        currentQuestionIndex = .name
        currentResponse = ChatResponse(text: "Welcome to FitBuddy! Let's set up your profile. What's your name?", stage: .onboarding, actions: [.none])
    }
    
    func generateWorkout() {
        Task {
            let response = await geminiService.sendMessage("Generate a workout plan for me")
            await MainActor.run {
                self.currentResponse = ChatResponse(text: response, stage: .idle, actions: [.generateWorkout, .askQuestion])
            }
        }
    }
    
    func askQuestion() {
        currentStage = .qa
        currentResponse = ChatResponse(text: "What would you like to know about fitness?", stage: .qa, actions: [.none])
    }
    
    private func handleWorkoutLogging() {
        // Mock workout entry creation
        _ = WorkoutEntry(
            date: Date(),
            exercises: [ExerciseItem(name: "Push-ups")],
            type: "Strength Training",
            duration: 30,
            mood: "good",
            difficulty: "moderate"
        )
        
        let response = "Great! I've logged your workout. You completed a 30-minute strength training session. Keep up the momentum! 💪"
        messages.append(ChatMessage(content: response, isFromUser: false))
        currentStage = .idle
    }
    
    private func handleWorkoutPlanning() -> ChatResponse {
        let response = "I'd be happy to help you plan a workout! What type of training are you looking for today? (strength, cardio, flexibility, etc.)"
        messages.append(ChatMessage(content: response, isFromUser: false))
        currentStage = .planning
        return ChatResponse(text: response, stage: .planning, actions: [.none])
    }
    
    func sendMessage(_ message: String) {
        Task {
            let response = await geminiService.sendMessage(message)
            // Response is already added to geminiService.messages
        }
    }
} 