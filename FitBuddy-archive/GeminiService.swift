import Foundation
import SwiftUI
import GoogleGenerativeAI

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(content: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}

// MARK: - Context Management Structures
struct PersistentConversationContext: Codable {
    var workoutHistory: [WorkoutPlan] = []
    var userPreferences: WorkoutPreferences = WorkoutPreferences()
    var lastWorkoutType: WorkoutType = .strength
    var conversationSummary: String = ""
    var lastInteractionDate: Date = Date()
    var totalWorkoutsCreated: Int = 0
    var favoriteExercises: [String] = []
    var avoidedExercises: [String] = []
    var lastWorkoutPlan: WorkoutPlan?
    
    func toConversationContext() -> ConversationContext {
        var context = ConversationContext()
        context.lastWorkoutPlan = lastWorkoutPlan ?? workoutHistory.last
        context.currentWorkoutType = lastWorkoutType
        context.currentPreferences = userPreferences
        return context
    }
    
    mutating func updateWithNewWorkout(_ workout: WorkoutPlan) {
        workoutHistory.append(workout)
        totalWorkoutsCreated += 1
        lastInteractionDate = Date()
        
        // Update preferences based on the workout
        if !workout.targetMuscleGroups.isEmpty {
            // Add target areas to preferred workout types if they match
            for muscleGroup in workout.targetMuscleGroups {
                if let workoutType = mapMuscleGroupToWorkoutType(muscleGroup) {
                    if !userPreferences.preferredWorkoutTypes.contains(workoutType) {
                        userPreferences.preferredWorkoutTypes.append(workoutType)
                    }
                }
            }
        }
        
        // Remember favorite exercises
        for exercise in workout.exercises {
            if !favoriteExercises.contains(exercise.name) {
                favoriteExercises.append(exercise.name)
            }
        }
        
        // Keep only last 10 workouts to prevent memory bloat
        if workoutHistory.count > 10 {
            workoutHistory = Array(workoutHistory.suffix(10))
        }
    }
    
    mutating func updatePreferences(_ newPreferences: WorkoutPreferences) {
        // Merge new preferences with existing ones
        if !newPreferences.preferredWorkoutTypes.isEmpty {
            userPreferences.preferredWorkoutTypes = Array(Set(userPreferences.preferredWorkoutTypes + newPreferences.preferredWorkoutTypes))
        }
        if !newPreferences.availableEquipment.isEmpty {
            userPreferences.availableEquipment = Array(Set(userPreferences.availableEquipment + newPreferences.availableEquipment))
        }
        if !newPreferences.goals.isEmpty {
            userPreferences.goals = Array(Set(userPreferences.goals + newPreferences.goals))
        }
        if newPreferences.workoutDuration != .medium {
            userPreferences.workoutDuration = newPreferences.workoutDuration
        }
        if newPreferences.daysPerWeek != 3 {
            userPreferences.daysPerWeek = newPreferences.daysPerWeek
        }
        if newPreferences.preferredTime != .evening {
            userPreferences.preferredTime = newPreferences.preferredTime
        }
        if newPreferences.fitnessLevel != .beginner {
            userPreferences.fitnessLevel = newPreferences.fitnessLevel
        }
        lastInteractionDate = Date()
    }
    
    private func mapMuscleGroupToWorkoutType(_ muscleGroup: String) -> WorkoutType? {
        switch muscleGroup.lowercased() {
        case "legs", "glutes": return .strength
        case "arms", "chest", "back": return .strength
        case "core": return .strength
        case "cardio": return .cardio
        default: return nil
        }
    }
}

struct ConversationContext {
    var lastWorkoutPlan: WorkoutPlan?
    var currentWorkoutType: WorkoutType = .strength
    var currentPreferences: WorkoutPreferences = WorkoutPreferences()
    var conversationMemory: [String] = []
    var isUpdatingWorkout: Bool = false
    
    mutating func addToMemory(_ interaction: String) {
        conversationMemory.append(interaction)
        // Keep only last 20 interactions to prevent memory bloat
        if conversationMemory.count > 20 {
            conversationMemory = Array(conversationMemory.suffix(20))
        }
    }
}

// MARK: - Array Extension
extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        return Array(Set(self))
    }
}

// MARK: - Workout Modification Types
enum WorkoutModification: Equatable {
    case setDuration(Int)
    case increaseDuration
    case decreaseDuration
    case increaseIntensity
    case decreaseIntensity
    case removeEquipment
    case addDumbbells
    case focusOnLegs
    case focusOnArms
    case focusOnCore
    case focusOnFullBody
    case addExercises
    case removeExercises
    case addCardio
    case addStrength
    case changeWorkoutType
    case adaptToBodyweight
    case addWeights
    case addRecoveryExercises
    case avoidInjuredAreas
    case reduceIntensity
    case reduceDuration
}

class GeminiService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var awaitingSchedulingResponse = false
    
    private var calendarManager: CalendarManager?
    private var profileManager: ProfileManager?
    private var workoutPlanManager: WorkoutPlanManager?
    
    // Persistent context that survives app restarts
    private var persistentContext: PersistentConversationContext {
        get {
            if let data = UserDefaults.standard.data(forKey: "PeregrinePersistentContext"),
               let context = try? JSONDecoder().decode(PersistentConversationContext.self, from: data) {
                return context
            }
            return PersistentConversationContext()
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "PeregrinePersistentContext")
            }
        }
    }
    
    // Current session context (resets each session)
    private var sessionContext = ConversationContext()
    
    // Combined context that merges persistent and session data
    private var combinedContext: ConversationContext {
        var context = persistentContext.toConversationContext()
        // Merge session-specific data
        if let sessionPlan = sessionContext.lastWorkoutPlan {
            context.lastWorkoutPlan = sessionPlan
        }
        if sessionContext.currentWorkoutType != .strength {
            context.currentWorkoutType = sessionContext.currentWorkoutType
        }
        if !sessionContext.currentPreferences.preferredWorkoutTypes.isEmpty {
            // Merge session preferences
            context.currentPreferences.preferredWorkoutTypes = Array(Set(context.currentPreferences.preferredWorkoutTypes + sessionContext.currentPreferences.preferredWorkoutTypes))
        }
        return context
    }
    
    private var lastCreatedWorkoutPlan: WorkoutPlan?
    
    init() {
        loadPersistentContext()
        print("🤖 GeminiService: Initialized with persistent context")
        print("🤖 - Previous workout plans: \(persistentContext.workoutHistory.count)")
        print("🤖 - User preferences: \(persistentContext.userPreferences.preferredWorkoutTypes.map { $0.rawValue })")
        print("🤖 - Last workout type: \(persistentContext.lastWorkoutType.rawValue)")
    }
    
    private func loadPersistentContext() {
        let context = persistentContext
        print("🤖 Loading persistent context:")
        print("🤖 - Workout history: \(context.workoutHistory.count) plans")
        print("🤖 - User preferences: \(context.userPreferences.preferredWorkoutTypes.map { $0.rawValue })")
        print("🤖 - Last workout type: \(context.lastWorkoutType.rawValue)")
        
        // If we have previous context, create a welcome message that builds upon it
        if !context.workoutHistory.isEmpty || !context.userPreferences.preferredWorkoutTypes.isEmpty {
            let welcomeMessage = generateContextualWelcome()
            DispatchQueue.main.async {
                self.messages.append(ChatMessage(
                    content: welcomeMessage,
                    isFromUser: false,
                    timestamp: Date()
                ))
            }
        }
    }
    
    private func generateContextualWelcome() -> String {
        let context = persistentContext
        
        if !context.workoutHistory.isEmpty {
            let lastPlan = context.workoutHistory.last!
            return """
            **Welcome back!** 👋
            
            I remember your last workout: **\(lastPlan.title)**
            - Target areas: \(lastPlan.targetMuscleGroups.joined(separator: ", "))
            - Equipment: \(lastPlan.equipment.joined(separator: ", "))
            
            **What would you like to do?**
            • **Continue with this plan** - Say "continue" or "same workout"
            • **Modify it** - Say "make it harder", "focus on legs", etc.
            • **Create something new** - Ask for a different type of workout
            • **Build on your preferences** - I remember you like \(context.userPreferences.preferredWorkoutTypes.isEmpty ? "general workouts" : context.userPreferences.preferredWorkoutTypes.map { $0.rawValue }.joined(separator: ", "))
            
            I'm here to help you build on your fitness journey! 💪
            """
        } else if !context.userPreferences.preferredWorkoutTypes.isEmpty {
            return """
            **Welcome back!** 👋
            
            I remember your preferences:
            - You like to focus on: \(context.userPreferences.preferredWorkoutTypes.map { $0.rawValue }.joined(separator: ", "))
            - Preferred workout type: \(context.lastWorkoutType.rawValue)
            - Equipment available: \(context.userPreferences.availableEquipment.map { $0.rawValue }.joined(separator: ", "))
            
            **Let's create a workout that builds on what you enjoy!**
            Say something like "give me a workout" or "create something for me"
            """
        } else {
            return """
            **Welcome to Peregrine!** 💪
            
            I'm your AI fitness coach. Let's start by understanding your preferences!
            
            **Tell me:**
            • What type of workouts do you enjoy? (strength, cardio, yoga, etc.)
            • What areas do you want to focus on? (legs, arms, core, etc.)
            • What equipment do you have? (dumbbells, none, etc.)
            
            I'll remember your preferences and build better workouts over time!
            """
        }
    }
    
    // MARK: - Public Methods
    func sendMessage(_ message: String) {
        let userMessage = ChatMessage(content: message, isFromUser: true, timestamp: Date())
        messages.append(userMessage)
        
        isTyping = true
        
        // Process the message asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            let response = self.processMessage(message)
            
            DispatchQueue.main.async {
                self.messages.append(ChatMessage(
                    content: response,
                    isFromUser: false,
                    timestamp: Date()
                ))
                self.isTyping = false
            }
        }
    }
    
    private func processMessage(_ message: String) -> String {
        let lowercased = message.lowercased()
        
        // Check for workout plan requests
        if lowercased.contains("workout") || lowercased.contains("exercise") || lowercased.contains("training") {
            return generateWorkoutPlan(message)
        }
        
        // Check for profile updates
        if lowercased.contains("weight") || lowercased.contains("height") || lowercased.contains("age") || lowercased.contains("goal") {
            return handleProfileUpdate(message)
        }
        
        // Check for nutrition advice
        if lowercased.contains("nutrition") || lowercased.contains("diet") || lowercased.contains("food") || lowercased.contains("meal") {
            return generateNutritionAdvice(message)
        }
        
        // Check for emotional support
        if lowercased.contains("sad") || lowercased.contains("anxious") || lowercased.contains("tired") || lowercased.contains("can't") {
            return provideEmotionalSupport(message)
        }
        
        // Default response
        return """
        I'm here to help you with your fitness journey! 💪
        
        **What can I help you with?**
        • **Workout Plans** - "Give me a workout" or "Create a strength training plan"
        • **Profile Updates** - "My weight is 165 lbs" or "I'm 5'8" tall"
        • **Nutrition Advice** - "What should I eat?" or "Help with meal planning"
        • **Motivation** - "I'm feeling tired" or "I need motivation"
        
        Just tell me what you'd like to work on!
        """
    }
    
    private func generateWorkoutPlan(_ message: String) -> String {
        // This is a simplified version - in a real app, you'd integrate with WorkoutPlanManager
        return """
        **Here's a great workout for you!** 💪
        
        **Warm-up (5 minutes):**
        • Light jogging in place
        • Arm circles
        • Hip rotations
        
        **Main Workout (30 minutes):**
        • Push-ups: 3 sets of 10 reps
        • Squats: 3 sets of 15 reps
        • Plank: 3 sets of 30 seconds
        • Jumping jacks: 3 sets of 20 reps
        
        **Cool-down (5 minutes):**
        • Stretching exercises
        • Deep breathing
        
        **Total Time:** 40 minutes
        
        Would you like me to modify this workout or create a different type of plan?
        """
    }
    
    private func handleProfileUpdate(_ message: String) -> String {
        // Use the ProfileManager's updateProfile method which can parse the message
        profileManager?.updateProfile(message)
        
        let lowercased = message.lowercased()
        
        // Check what was updated and provide appropriate feedback
        if lowercased.contains("weight") || lowercased.contains("lbs") || lowercased.contains("pounds") {
            return """
            ✅ **Weight Updated!**
            
            I've updated your weight in your profile.
            
            This will help me create more personalized workout plans and track your progress better. Would you like me to update any other information or create a new workout plan based on your updated stats?
            """
        }
        
        if lowercased.contains("height") || lowercased.contains("inches") || lowercased.contains("tall") {
            return """
            ✅ **Height Updated!**
            
            I've updated your height in your profile.
            
            This helps me calculate your BMI and create more accurate fitness recommendations. Would you like me to update any other information?
            """
        }
        
        if lowercased.contains("age") || lowercased.contains("years old") {
            return """
            ✅ **Age Updated!**
            
            I've updated your age in your profile.
            
            This helps me create age-appropriate workout plans and calculate your target heart rate zones. Would you like me to create a new workout plan based on your updated profile?
            """
        }
        
        if lowercased.contains("goal") || lowercased.contains("want to") {
            return """
            ✅ **Fitness Goals Updated!**
            
            I've updated your fitness goals in your profile.
            
            Based on your new goals, I can create personalized workout plans that will help you achieve them. Would you like me to create a new workout plan tailored to these goals?
            """
        }
        
        return """
        ✅ **Profile Update**
        
        I can help you update your fitness profile! What would you like to change?
        
        **Available Updates:**
        • Weight (e.g., "My weight is 165 lbs")
        • Height (e.g., "I'm 5'8" tall")
        • Age (e.g., "I'm 28 years old")
        • Goals (e.g., "I want to lose weight and build muscle")
        
        Just tell me what you'd like to update!
        """
    }
    
    private func generateNutritionAdvice(_ message: String) -> String {
        return """
        **Nutrition Tips for Your Fitness Goals**
        
        Here are some key nutrition principles:
        
        **Protein**: Aim for 0.8-1.2g per pound of body weight
        **Carbs**: 45-65% of daily calories for energy
        **Fats**: 20-35% of daily calories for hormone health
        
        **Meal Timing:**
        • **Pre-workout**: Light meal 2-3 hours before
        • **Post-workout**: Protein + carbs within 30 minutes
        • **Hydration**: 8-12 cups of water daily
        
        **Healthy Food Choices:**
        • Lean proteins: chicken, fish, eggs, tofu
        • Complex carbs: oats, brown rice, sweet potatoes
        • Healthy fats: avocados, nuts, olive oil
        • Vegetables: aim for 5+ servings daily
        
        Would you like me to create a meal plan or help with specific nutrition questions?
        """
    }
    
    private func provideEmotionalSupport(_ message: String) -> String {
        let lowercased = message.lowercased()
        
        if lowercased.contains("sad") || lowercased.contains("depressed") || lowercased.contains("down") {
            return """
            💙 **I hear you, and it's okay to feel this way.**
            
            Your feelings are valid, and taking care of yourself right now is the most important thing. Here are some gentle ways to support yourself:
            
            **Gentle Movement Options:**
            • Take a slow, mindful walk outside (even 5 minutes helps)
            • Try some gentle stretching or yoga
            • Dance to your favorite music in your room
            
            **Self-Care Ideas:**
            • Take a warm bath or shower
            • Listen to calming music
            • Write down your thoughts in a journal
            • Call a friend or family member
            
            **Remember:** Exercise releases endorphins that can help improve your mood, but it's also perfectly okay to rest when you need it. Start with something small - even just standing up and stretching counts as movement.
            
            Would you like me to create a very gentle, mood-boosting workout, or would you prefer to talk about something else?
            """
        }
        
        if lowercased.contains("anxious") || lowercased.contains("stressed") || lowercased.contains("worried") {
            return """
            🌸 **I understand anxiety can be really overwhelming.**
            
            Let's focus on some calming techniques that can help:
            
            **Immediate Calming Exercises:**
            • **4-7-8 Breathing**: Inhale for 4, hold for 7, exhale for 8
            • **Progressive Muscle Relaxation**: Tense and release each muscle group
            • **5-4-3-2-1 Grounding**: Name 5 things you see, 4 you feel, 3 you hear, 2 you smell, 1 you taste
            
            **Gentle Movement for Anxiety:**
            • Slow, mindful walking
            • Gentle yoga or stretching
            • Tai chi movements
            • Swimming (if available)
            
            **Remember:** Exercise can be a powerful tool for managing anxiety, but it's important to start gently. Even 10 minutes of movement can help reduce stress hormones.
            
            Would you like me to create a calming, low-intensity workout designed specifically for stress relief?
            """
        }
        
        if lowercased.contains("tired") || lowercased.contains("exhausted") || lowercased.contains("fatigue") {
            return """
            😴 **It sounds like you're really tired, and that's completely normal.**
            
            Sometimes our bodies need rest more than they need intense exercise. Here are some options:
            
            **If You Want Gentle Movement:**
            • Light stretching while sitting or lying down
            • Slow walking around your home
            • Gentle chair exercises
            • Deep breathing exercises
            
            **If You Need Rest:**
            • Listen to your body - rest is just as important as exercise
            • Focus on good sleep hygiene
            • Stay hydrated and eat nourishing foods
            • Be kind to yourself - you don't have to push through exhaustion
            
            **Remember:** Rest days are essential for progress. Your body needs time to recover and rebuild.
            
            Would you like me to create a very gentle, energy-conserving routine, or would you prefer to focus on recovery strategies?
            """
        }
        
        if lowercased.contains("can't") || lowercased.contains("don't want to") || lowercased.contains("give up") {
            return """
            🤗 **I want you to know that it's okay to feel this way.**
            
            Everyone has moments when they feel like they can't or don't want to continue. This doesn't mean you've failed - it means you're human.
            
            **Let's take a step back:**
            • What's making you feel this way right now?
            • Are you being too hard on yourself?
            • What would help you feel better?
            
            **Remember:** Progress isn't linear. Some days will be harder than others, and that's completely normal. The important thing is that you're here and you're trying.
            
            Would you like to talk about what's going on, or would you prefer a very gentle, no-pressure workout option?
            """
        }
        
        return """
        💪 **I'm here to support you on your fitness journey!**
        
        Remember that fitness is about progress, not perfection. Every step you take toward your goals is valuable, no matter how small.
        
        **What would help you most right now?**
        • A gentle, beginner-friendly workout
        • Tips for getting started
        • Motivation and encouragement
        • Just someone to talk to
        
        I'm here for whatever you need! 🌟
        """
    }
    
    func clearConversation() {
        messages = [
            ChatMessage(
                content: "Hey! I'm your Peregrine coach. I can help you with workout plans, answer fitness questions, and keep track of your progress. What would you like to work on today?",
                isFromUser: false,
                timestamp: Date()
            )
        ]
    }
    
    // MARK: - Helper Methods
    private func getIntensity(_ intensity: FitnessLevel) -> String {
        switch intensity {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    
    private func getDuration(_ duration: WorkoutDuration) -> Int {
        switch duration {
        case .short: return 25
        case .medium: return 37
        case .long: return 52
        case .extended: return 75
        }
    }
    
    private func isOffTopic(_ message: String) -> Bool {
        let offTopicKeywords = [
            "weather", "politics", "news", "sports", "music", "movies", "books", "travel",
            "cooking", "recipes", "shopping", "technology", "programming", "math", "science",
            "history", "geography", "art", "literature", "philosophy", "religion", "jokes",
            "riddles", "games", "puzzles", "trivia", "random", "funny", "entertainment"
        ]
        
        return offTopicKeywords.contains { message.contains($0) }
    }
    
    // Add this method to allow dependency injection after initialization
    public func configure(profileManager: ProfileManager, calendarManager: CalendarManager, workoutPlanManager: WorkoutPlanManager) {
        self.profileManager = profileManager
        self.calendarManager = calendarManager
        self.workoutPlanManager = workoutPlanManager
    }
}









