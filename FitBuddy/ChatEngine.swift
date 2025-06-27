import Foundation
import SwiftUI

// MARK: - Chat Engine

enum ChatStage {
    case idle
    case onboarding(QIndex)
    case planning
    case editing
    case qa
}

enum QIndex: Int, CaseIterable {
    case name = 0
    case age = 1
    case weight = 2
    case height = 3
    case goal = 4
    case equipment = 5
    case fitnessLevel = 6
    
    var question: String {
        switch self {
        case .name: return "What's your name?"
        case .age: return "How old are you?"
        case .weight: return "What's your current weight (in kg)?"
        case .height: return "What's your height (in cm)?"
        case .goal: return "What's your main fitness goal? (e.g., lose weight, build muscle, improve endurance)"
        case .equipment: return "What equipment do you have access to? (e.g., none, dumbbells, gym)"
        case .fitnessLevel: return "What's your current fitness level? (beginner, intermediate, advanced)"
        }
    }
    
    var field: String {
        switch self {
        case .name: return "name"
        case .age: return "age"
        case .weight: return "weight"
        case .height: return "height"
        case .goal: return "goals"
        case .equipment: return "equipment"
        case .fitnessLevel: return "fitnessLevel"
        }
    }
}

enum BotAction {
    case createPlan
    case schedulePlan(Date)
    case updatePlan(PlanPatch)
    case none
}

struct ChatResponse {
    let text: String
    let stage: ChatStage
    let actions: [BotAction]
    let showInput: Bool
    
    init(text: String, stage: ChatStage, actions: [BotAction] = [], showInput: Bool = true) {
        self.text = text
        self.stage = stage
        self.actions = actions
        self.showInput = showInput
    }
}

struct PlanPatch {
    let type: PatchType
    let day: Int?
    let exercise: String?
    let value: String?
    
    enum PatchType {
        case addExercise
        case removeExercise
        case changeDate
        case changeIntensity
        case changeEquipment
    }
}

class ChatEngine: ObservableObject {
    @Published var currentStage: ChatStage = .idle
    @Published var currentQuestionIndex: QIndex = .name
    
    private var profileManager: ProfileManager
    private var workoutJournal: WorkoutJournal
    private var calendarManager: CalendarManager
    private var gptService: GPTService
    
    init(profileManager: ProfileManager, workoutJournal: WorkoutJournal, calendarManager: CalendarManager, gptService: GPTService) {
        self.profileManager = profileManager
        self.workoutJournal = workoutJournal
        self.calendarManager = calendarManager
        self.gptService = gptService
    }
    
    func updateDependencies(profileManager: ProfileManager, workoutJournal: WorkoutJournal, calendarManager: CalendarManager, gptService: GPTService) {
        self.profileManager = profileManager
        self.workoutJournal = workoutJournal
        self.calendarManager = calendarManager
        self.gptService = gptService
    }
    
    func handle(userInput: String) -> ChatResponse {
        let input = userInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        switch currentStage {
        case .idle:
            return handleIdle(input: input)
        case .onboarding:
            return handleOnboarding(input: input)
        case .planning:
            return handlePlanning(input: input)
        case .editing:
            return handleEditing(input: input)
        case .qa:
            return handleQA(input: input)
        }
    }
    
    private func handleIdle(input: String) -> ChatResponse {
        // Check if it's a question or command
        if input.contains("?") || input.hasPrefix("how") || input.hasPrefix("why") || input.hasPrefix("what") {
            return ChatResponse(text: "Let me help you with that!", stage: .qa, actions: [.none])
        }
        
        // Check if user wants to start planning
        if input.contains("plan") || input.contains("workout") || input.contains("routine") {
            return startOnboarding()
        }
        
        // Default to QA
        return ChatResponse(text: "I'm here to help with your fitness journey! Ask me anything about workouts, nutrition, or let's create a personalized plan together.", stage: .qa, actions: [.none])
    }
    
    private func handleOnboarding(input: String) -> ChatResponse {
        // Validate and save the answer
        let isValid = validateAnswer(input: input, for: currentQuestionIndex)
        if !isValid {
            return ChatResponse(text: "Please provide a valid answer. \(currentQuestionIndex.question)", stage: .onboarding(currentQuestionIndex), actions: [.none])
        }
        
        // Save to profile
        saveAnswer(input: input, for: currentQuestionIndex)
        
        // Move to next question or complete
        if let nextIndex = getNextQuestionIndex() {
            currentQuestionIndex = nextIndex
            return ChatResponse(text: nextIndex.question, stage: .onboarding(nextIndex), actions: [.none])
        } else {
            // Onboarding complete, create plan
            return createWorkoutPlan()
        }
    }
    
    private func handlePlanning(input: String) -> ChatResponse {
        if input.contains("schedule") || input.contains("yes") || input.contains("ok") {
            return schedulePlan()
        } else if input.contains("edit") || input.contains("change") || input.contains("modify") {
            return ChatResponse(text: "What would you like to change? You can:\n• Add exercises\n• Change dates\n• Adjust intensity\n• Modify equipment", stage: .editing, actions: [.none])
        } else if input.contains("discard") || input.contains("no") || input.contains("cancel") {
            return ChatResponse(text: "No problem! Let me know if you'd like to create a different plan later.", stage: .idle, actions: [.none])
        } else {
            return ChatResponse(text: "Would you like to:\n✅ Schedule this plan\n📝 Edit something\n❌ Discard", stage: .planning, actions: [.createPlan])
        }
    }
    
    private func handleEditing(input: String) -> ChatResponse {
        if input.contains("done") || input.contains("good") || input.contains("looks good") {
            return ChatResponse(text: "Perfect! Your plan is ready. Would you like to schedule it?", stage: .planning, actions: [.createPlan])
        }
        
        // Parse editing commands
        let patch = parseEditCommand(input: input)
        if let patch = patch {
            return ChatResponse(text: "I've updated your plan based on your request. What else would you like to change?", stage: .editing, actions: [.updatePlan(patch)])
        }
        
        return ChatResponse(text: "I didn't understand that edit command. Try:\n• 'Add kettlebell swings to Day 2'\n• 'Move leg day to Friday'\n• 'Increase burpees to 25 reps'", stage: .editing, actions: [.none])
    }
    
    private func handleQA(input: String) -> ChatResponse {
        // Pass to GPT service for general fitness questions
        return ChatResponse(text: "Let me help you with that question!", stage: .qa, actions: [.none])
    }
    
    private func startOnboarding() -> ChatResponse {
        currentStage = .onboarding(.name)
        currentQuestionIndex = .name
        return ChatResponse(text: "Great! Let's create a personalized workout plan. \(QIndex.name.question)", stage: .onboarding(.name), actions: [.none])
    }
    
    private func validateAnswer(input: String, for question: QIndex) -> Bool {
        switch question {
        case .name:
            return input.count >= 2
        case .age:
            return Int(input) != nil && (18...100).contains(Int(input) ?? 0)
        case .weight:
            return Double(input) != nil && (30...300).contains(Double(input) ?? 0)
        case .height:
            return Int(input) != nil && (100...250).contains(Int(input) ?? 0)
        case .goal, .equipment, .fitnessLevel:
            return input.count >= 3
        }
    }
    
    private func saveAnswer(input: String, for question: QIndex) {
        switch question {
        case .name:
            profileManager.name = input.capitalized
        case .age:
            profileManager.age = Int(input) ?? 25
        case .weight:
            profileManager.weight = Int(input) ?? 70
        case .height:
            profileManager.height = Int(input) ?? 170
        case .goal:
            profileManager.goals = [input]
        case .equipment:
            profileManager.equipment = [input]
        case .fitnessLevel:
            profileManager.fitnessLevel = input
        }
    }
    
    private func getNextQuestionIndex() -> QIndex? {
        let currentIndex = currentQuestionIndex.rawValue
        let nextIndex = currentIndex + 1
        return QIndex.allCases.first { $0.rawValue == nextIndex }
    }
    
    private func createWorkoutPlan() -> ChatResponse {
        currentStage = .planning
        
        let planText = """
        Here's your personalized 3-day workout plan:
        
        **Day 1: Upper Body**
        • Push-ups: 3 sets × 10 reps
        • Dumbbell rows: 3 sets × 12 reps
        • Shoulder press: 3 sets × 8 reps
        • Plank: 3 sets × 30 seconds
        
        **Day 2: Lower Body**
        • Squats: 3 sets × 15 reps
        • Lunges: 3 sets × 10 reps each leg
        • Glute bridges: 3 sets × 12 reps
        • Calf raises: 3 sets × 20 reps
        
        **Day 3: Cardio & Core**
        • Jumping jacks: 3 sets × 30 seconds
        • Mountain climbers: 3 sets × 20 reps
        • Bicycle crunches: 3 sets × 15 reps
        • Burpees: 3 sets × 8 reps
        
        Would you like to:
        ✅ Schedule this plan
        📝 Edit something
        ❌ Discard
        """
        
        return ChatResponse(text: planText, stage: .planning, actions: [.createPlan])
    }
    
    private func schedulePlan() -> ChatResponse {
        // Schedule for tomorrow at 7 AM
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let scheduledDate = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        
        // Create workout entries
        for dayOffset in 0..<3 {
            let workoutDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: scheduledDate) ?? scheduledDate
            let entry = WorkoutEntry(
                date: workoutDate,
                exercises: getExercisesForDay(dayOffset + 1),
                notes: "Generated workout plan",
                calories: 300,
                type: "Strength Training",
                duration: 45,
                mood: .good,
                difficulty: .moderate
            )
            workoutJournal.upsert(entry)
        }
        
        return ChatResponse(text: "Perfect! I've scheduled your 3-day workout plan starting tomorrow at 7 AM. You can track your progress in the Calendar tab!", stage: .idle, actions: [.schedulePlan(scheduledDate)])
    }
    
    private func getExercisesForDay(_ day: Int) -> [ExerciseItem] {
        switch day {
        case 1:
            return [
                ExerciseItem(name: "Push-ups", sets: 3, reps: 10),
                ExerciseItem(name: "Dumbbell rows", sets: 3, reps: 12),
                ExerciseItem(name: "Shoulder press", sets: 3, reps: 8),
                ExerciseItem(name: "Plank", sets: 3, reps: 1, duration: 30)
            ]
        case 2:
            return [
                ExerciseItem(name: "Squats", sets: 3, reps: 15),
                ExerciseItem(name: "Lunges", sets: 3, reps: 10),
                ExerciseItem(name: "Glute bridges", sets: 3, reps: 12),
                ExerciseItem(name: "Calf raises", sets: 3, reps: 20)
            ]
        case 3:
            return [
                ExerciseItem(name: "Jumping jacks", sets: 3, reps: 1, duration: 30),
                ExerciseItem(name: "Mountain climbers", sets: 3, reps: 20),
                ExerciseItem(name: "Bicycle crunches", sets: 3, reps: 15),
                ExerciseItem(name: "Burpees", sets: 3, reps: 8)
            ]
        default:
            return []
        }
    }
    
    private func parseEditCommand(input: String) -> PlanPatch? {
        let words = input.components(separatedBy: " ")
        
        if input.contains("add") && input.contains("day") {
            // "Add kettlebell swings to Day 2"
            let dayMatch = words.first { $0.contains("day") }
            let day = dayMatch?.replacingOccurrences(of: "day", with: "").trimmingCharacters(in: .whitespaces)
            let exercise = words.dropFirst(2).joined(separator: " ") // Skip "add" and "to"
            
            return PlanPatch(type: .addExercise, day: Int(day ?? "1"), exercise: exercise, value: nil)
        }
        
        if input.contains("move") && input.contains("to") {
            // "Move leg day to Friday"
            return PlanPatch(type: .changeDate, day: nil, exercise: nil, value: input)
        }
        
        if input.contains("increase") || input.contains("decrease") {
            // "Increase burpees to 25 reps"
            return PlanPatch(type: .changeIntensity, day: nil, exercise: nil, value: input)
        }
        
        return nil
    }
} 