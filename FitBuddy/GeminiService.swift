import Foundation
import SwiftUI
import GoogleGenerativeAI

// MARK: - Context Management Structures
struct PersistentConversationContext: Codable {
    var workoutHistory: [WorkoutPlan] = []
    var userPreferences: WorkoutPreferences = WorkoutPreferences()
    var lastWorkoutType: WorkoutType = .none
    var conversationSummary: String = ""
    var lastInteractionDate: Date = Date()
    var totalWorkoutsCreated: Int = 0
    var favoriteExercises: [String] = []
    var avoidedExercises: [String] = []
    var preferredDuration: Duration = .medium
    var preferredIntensity: Intensity = .medium
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
            userPreferences.targetAreas = Array(Set(userPreferences.targetAreas + workout.targetMuscleGroups))
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
        userPreferences.merge(with: newPreferences)
        lastInteractionDate = Date()
    }
}

struct ConversationContext {
    var lastWorkoutPlan: WorkoutPlan?
    var currentWorkoutType: WorkoutType = .none
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
            if let data = UserDefaults.standard.data(forKey: "FitBuddyPersistentContext"),
               let context = try? JSONDecoder().decode(PersistentConversationContext.self, from: data) {
                return context
            }
            return PersistentConversationContext()
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "FitBuddyPersistentContext")
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
        if sessionContext.currentWorkoutType != .none {
            context.currentWorkoutType = sessionContext.currentWorkoutType
        }
        if !sessionContext.currentPreferences.targetAreas.isEmpty {
            context.currentPreferences.merge(with: sessionContext.currentPreferences)
        }
        return context
    }
    
    private var lastCreatedWorkoutPlan: WorkoutPlan?
    
    init() {
        loadPersistentContext()
        print("🤖 GeminiService: Initialized with persistent context")
        print("🤖 - Previous workout plans: \(persistentContext.workoutHistory.count)")
        print("🤖 - User preferences: \(persistentContext.userPreferences.targetAreas)")
        print("🤖 - Last workout type: \(persistentContext.lastWorkoutType.displayName)")
    }
    
    private func loadPersistentContext() {
        let context = persistentContext
        print("🤖 Loading persistent context:")
        print("🤖 - Workout history: \(context.workoutHistory.count) plans")
        print("🤖 - User preferences: \(context.userPreferences.targetAreas)")
        print("🤖 - Last workout type: \(context.lastWorkoutType.displayName)")
        
        // If we have previous context, create a welcome message that builds upon it
        if !context.workoutHistory.isEmpty || !context.userPreferences.targetAreas.isEmpty {
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
            • **Build on your preferences** - I remember you like \(context.userPreferences.targetAreas.isEmpty ? "general workouts" : context.userPreferences.targetAreas.joined(separator: ", "))
            
            I'm here to help you build on your fitness journey! 💪
            """
        } else if !context.userPreferences.targetAreas.isEmpty {
            return """
            **Welcome back!** 👋
            
            I remember your preferences:
            - You like to focus on: \(context.userPreferences.targetAreas.joined(separator: ", "))
            - Preferred workout type: \(context.lastWorkoutType.displayName)
            - Equipment available: \(context.userPreferences.equipmentList.joined(separator: ", "))
            
            **Let's create a workout that builds on what you enjoy!**
            Say something like "give me a workout" or "create something for me"
            """
        } else {
            return """
            **Welcome to FitBuddy!** 💪
            
            I'm your AI fitness coach. Let's start by understanding your preferences!
            
            **Tell me:**
            • What type of workouts do you enjoy? (strength, cardio, yoga, etc.)
            • What areas do you want to focus on? (legs, arms, core, etc.)
            • What equipment do you have? (dumbbells, none, etc.)
            
            I'll remember your preferences and build better workouts over time!
            """
        }
    }
    
    private func initializeModel() {
        // Initialize the local intelligence system
        print("🤖 Local intelligence system initialized successfully")
    }
    
    func configure(profileManager: ProfileManager, calendarManager: CalendarManager, workoutPlanManager: WorkoutPlanManager) {
        print("🔧 GeminiService: Configuring with dependencies...")
        self.profileManager = profileManager
        self.calendarManager = calendarManager
        self.workoutPlanManager = workoutPlanManager
        print("🔧 GeminiService: Configuration complete. calendarManager is \(self.calendarManager != nil ? "set" : "NOT set")")
    }
    
    func sendMessage(_ message: String) {
        let userMessage = ChatMessage(
            content: message,
            isFromUser: true,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.messages.append(userMessage)
            self.isTyping = true
        }
        
        // Update context with new information
        updateIntelligentContext(with: message)
        
        // Generate intelligent response
        let response = generateIntelligentResponse(message)
        let aiMessage = ChatMessage(
            content: response,
            isFromUser: false,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.messages.append(aiMessage)
            self.isTyping = false
        }
    }
    
    private func updateIntelligentContext(with message: String) {
        let lowercased = message.lowercased()
        
        // Update equipment availability
        if lowercased.contains("dumbbell") || lowercased.contains("weight") {
            sessionContext.currentPreferences.hasDumbbells = true
            sessionContext.currentPreferences.bodyweightOnly = false
        }
        if lowercased.contains("no equipment") || lowercased.contains("bodyweight") || lowercased.contains("don't have") {
            sessionContext.currentPreferences.bodyweightOnly = true
            sessionContext.currentPreferences.hasDumbbells = false
        }
        
        // Update physical limitations and soreness
        if lowercased.contains("sore") || lowercased.contains("hurt") || lowercased.contains("pain") {
            sessionContext.currentPreferences.isSore = true
            sessionContext.currentPreferences.intensity = .low
        }
        if lowercased.contains("knee") || lowercased.contains("back") || lowercased.contains("shoulder") {
            sessionContext.currentPreferences.injuries.append(contentsOf: extractInjuries(from: lowercased))
        }
        if lowercased.contains("tired") || lowercased.contains("exhausted") || lowercased.contains("fatigue") {
            sessionContext.currentPreferences.energyLevel = .low
        }
        
        // Update workout preferences
        if lowercased.contains("cardio") || lowercased.contains("running") || lowercased.contains("jumping") {
            sessionContext.currentPreferences.workoutType = .cardio
        }
        if lowercased.contains("strength") || lowercased.contains("lifting") || lowercased.contains("muscle") {
            sessionContext.currentPreferences.workoutType = .strength
        }
        if lowercased.contains("yoga") || lowercased.contains("stretch") || lowercased.contains("flexibility") {
            sessionContext.currentPreferences.workoutType = .yoga
        }
        
        // Update target areas
        if lowercased.contains("leg") || lowercased.contains("thigh") || lowercased.contains("calf") {
            sessionContext.currentPreferences.targetAreas.append("Legs")
        }
        if lowercased.contains("arm") || lowercased.contains("bicep") || lowercased.contains("tricep") {
            sessionContext.currentPreferences.targetAreas.append("Arms")
        }
        if lowercased.contains("core") || lowercased.contains("abs") || lowercased.contains("stomach") {
            sessionContext.currentPreferences.targetAreas.append("Core")
        }
        
        // Remove duplicates
        sessionContext.currentPreferences.targetAreas = Array(Set(sessionContext.currentPreferences.targetAreas))
        sessionContext.currentPreferences.injuries = Array(Set(sessionContext.currentPreferences.injuries))
        
        print("🤖 Intelligent Context Updated:")
        print("🤖 - Equipment: \(sessionContext.currentPreferences.bodyweightOnly ? "Bodyweight only" : "Has equipment")")
        print("🤖 - Soreness: \(sessionContext.currentPreferences.isSore ? "Yes" : "No")")
        print("🤖 - Injuries: \(sessionContext.currentPreferences.injuries)")
        print("🤖 - Energy: \(sessionContext.currentPreferences.energyLevel)")
        print("🤖 - Preferences: \(sessionContext.currentPreferences.targetAreas)")
    }
    
    private func extractInjuries(from message: String) -> [String] {
        var injuries: [String] = []
        if message.contains("knee") { injuries.append("Knee") }
        if message.contains("back") { injuries.append("Back") }
        if message.contains("shoulder") { injuries.append("Shoulder") }
        if message.contains("ankle") { injuries.append("Ankle") }
        if message.contains("wrist") { injuries.append("Wrist") }
        if message.contains("hip") { injuries.append("Hip") }
        return injuries
    }
    
    private func generateIntelligentResponse(_ message: String) -> String {
        // Check if this is a modification request for existing workout
        if let currentPlan = combinedContext.lastWorkoutPlan {
            let modifications = parseIntelligentModifications(message, currentPlan: currentPlan)
            if !modifications.isEmpty {
                // Check if this is a workout type change request
                if modifications.contains(.changeWorkoutType) {
                    print("🤖 Detected workout type change request, creating new workout")
                    // Create new workout based on the requested type
                    let workout = generateWorkoutPlan(message)
                    sessionContext.lastWorkoutPlan = workout
                    lastCreatedWorkoutPlan = workout
                    
                    // Save to persistent context
                    var persistentContext = self.persistentContext
                    persistentContext.workoutHistory.append(workout)
                    persistentContext.lastWorkoutPlan = workout
                    self.persistentContext = persistentContext
                    
                    return formatIntelligentWorkoutResponse(workout)
                } else {
                    // Apply regular modifications to existing workout
                    let updatedPlan = applyIntelligentModifications(currentPlan, modifications: modifications)
                    sessionContext.lastWorkoutPlan = updatedPlan
                    lastCreatedWorkoutPlan = updatedPlan
                    
                    // Save to persistent context
                    var persistentContext = self.persistentContext
                    persistentContext.workoutHistory.append(updatedPlan)
                    persistentContext.lastWorkoutPlan = updatedPlan
                    self.persistentContext = persistentContext
                    
                    return formatIntelligentUpdateResponse(updatedPlan, modifications: modifications)
                }
            }
        }
        
        // Create new intelligent workout
        let workout = generateWorkoutPlan(message)
        sessionContext.lastWorkoutPlan = workout
        lastCreatedWorkoutPlan = workout
        
        // Save to persistent context
        var persistentContext = self.persistentContext
        persistentContext.workoutHistory.append(workout)
        persistentContext.lastWorkoutPlan = workout
        self.persistentContext = persistentContext
        
        return formatIntelligentWorkoutResponse(workout)
    }
    
    private func parseIntelligentModifications(_ message: String, currentPlan: WorkoutPlan) -> [IntelligentModification] {
        let lowercased = message.lowercased()
        var modifications: [IntelligentModification] = []
        
        print("🤖 Parsing intelligent modifications from: '\(message)'")
        
        // Check for workout type change requests first
        if lowercased.contains("mma") || lowercased.contains("mixed martial arts") {
            print("🤖 Detected MMA workout type change request")
            return [.changeWorkoutType] // Special case to trigger new workout creation
        }
        if lowercased.contains("boxing") {
            print("🤖 Detected Boxing workout type change request")
            return [.changeWorkoutType]
        }
        if lowercased.contains("kickboxing") {
            print("🤖 Detected Kickboxing workout type change request")
            return [.changeWorkoutType]
        }
        if lowercased.contains("strength") || lowercased.contains("lifting") {
            print("🤖 Detected Strength workout type change request")
            return [.changeWorkoutType]
        }
        if lowercased.contains("cardio") || lowercased.contains("running") {
            print("🤖 Detected Cardio workout type change request")
            return [.changeWorkoutType]
        }
        if lowercased.contains("yoga") || lowercased.contains("stretch") {
            print("🤖 Detected Yoga workout type change request")
            return [.changeWorkoutType]
        }
        if lowercased.contains("hiit") || lowercased.contains("high intensity") {
            print("🤖 Detected HIIT workout type change request")
            return [.changeWorkoutType]
        }
        
        // Equipment-based modifications
        if lowercased.contains("no equipment") || lowercased.contains("bodyweight") {
            modifications.append(.adaptToBodyweight)
        }
        if lowercased.contains("dumbbell") || lowercased.contains("weight") {
            modifications.append(.addWeights)
        }
        
        // Physical limitation modifications
        if lowercased.contains("sore") || lowercased.contains("hurt") {
            modifications.append(.reduceIntensity)
            modifications.append(.addRecoveryExercises)
        }
        if lowercased.contains("knee") || lowercased.contains("back") || lowercased.contains("shoulder") {
            modifications.append(.avoidInjuredAreas)
        }
        if lowercased.contains("tired") || lowercased.contains("exhausted") {
            modifications.append(.reduceDuration)
            modifications.append(.reduceIntensity)
        }
        
        // Preference modifications
        if lowercased.contains("easier") || lowercased.contains("gentle") {
            modifications.append(.reduceIntensity)
        }
        if lowercased.contains("harder") || lowercased.contains("challenge") {
            modifications.append(.increaseIntensity)
        }
        if lowercased.contains("longer") || lowercased.contains("more time") {
            modifications.append(.increaseDuration)
        }
        if lowercased.contains("shorter") || lowercased.contains("quick") {
            modifications.append(.reduceDuration)
        }
        
        // Focus area modifications
        if lowercased.contains("leg") || lowercased.contains("lower body") {
            modifications.append(.focusOnLegs)
        }
        if lowercased.contains("arm") || lowercased.contains("upper body") {
            modifications.append(.focusOnArms)
        }
        if lowercased.contains("core") || lowercased.contains("abs") {
            modifications.append(.focusOnCore)
        }
        
        print("🤖 Detected \(modifications.count) intelligent modifications")
        return modifications
    }
    
    private func applyIntelligentModifications(_ plan: WorkoutPlan, modifications: [IntelligentModification]) -> WorkoutPlan {
        var updatedExercises = plan.exercises
        var updatedDuration = plan.duration
        var updatedDifficulty = plan.difficulty
        var updatedEquipment = plan.equipment
        var updatedTargetAreas = plan.targetMuscleGroups
        
        print("🤖 Applying intelligent modifications to workout")
        
        for modification in modifications {
            switch modification {
            case .changeWorkoutType:
                // This case is handled in generateIntelligentResponse, not here
                print("🤖 Workout type change detected - handled separately")
                
            case .adaptToBodyweight:
                updatedExercises = updatedExercises.map { adaptExerciseToBodyweight($0) }
                updatedEquipment = updatedExercises.compactMap { $0.equipment == "None" ? nil : $0.equipment }.uniqued()
                print("🤖 Adapted exercises to bodyweight")
                
            case .addWeights:
                updatedExercises = updatedExercises.map { addWeightsToExercise($0) }
                updatedEquipment = updatedExercises.compactMap { $0.equipment }.uniqued()
                print("🤖 Added weights to exercises")
                
            case .reduceIntensity:
                updatedExercises = updatedExercises.map { reduceExerciseIntensity($0) }
                updatedDifficulty = reduceDifficulty(updatedDifficulty)
                print("🤖 Reduced workout intensity")
                
            case .increaseIntensity:
                updatedExercises = updatedExercises.map { increaseExerciseIntensity($0) }
                updatedDifficulty = increaseDifficulty(updatedDifficulty)
                print("🤖 Increased workout intensity")
                
            case .addRecoveryExercises:
                let recoveryExercises = generateRecoveryExercises()
                updatedExercises.append(contentsOf: recoveryExercises)
                print("🤖 Added recovery exercises")
                
            case .avoidInjuredAreas:
                updatedExercises = updatedExercises.filter { !shouldAvoidExercise($0) }
                if updatedExercises.isEmpty {
                    updatedExercises = generateSafeAlternativeExercises()
                }
                print("🤖 Avoided exercises for injured areas")
                
            case .reduceDuration:
                updatedDuration = max(15, updatedDuration - 15)
                updatedExercises = Array(updatedExercises.prefix(max(3, updatedExercises.count - 1)))
                print("🤖 Reduced workout duration")
                
            case .increaseDuration:
                updatedDuration = min(90, updatedDuration + 15)
                let additionalExercises = generateAdditionalExercises(for: updatedTargetAreas)
                updatedExercises.append(contentsOf: additionalExercises)
                print("🤖 Increased workout duration")
                
            case .focusOnLegs:
                updatedExercises = generateLegFocusedExercises()
                updatedTargetAreas = ["Legs"]
                print("🤖 Focused workout on legs")
                
            case .focusOnArms:
                updatedExercises = generateArmFocusedExercises()
                updatedTargetAreas = ["Arms"]
                print("🤖 Focused workout on arms")
                
            case .focusOnCore:
                updatedExercises = generateCoreFocusedExercises()
                updatedTargetAreas = ["Core"]
                print("🤖 Focused workout on core")
            }
        }
        
        return WorkoutPlan(
            title: "Adapted \(plan.title)",
            description: "Intelligently modified based on your needs and preferences",
            exercises: updatedExercises,
            duration: updatedDuration,
            difficulty: updatedDifficulty,
            equipment: updatedEquipment,
            targetMuscleGroups: updatedTargetAreas
        )
    }
    
    private func adaptExerciseToBodyweight(_ exercise: Exercise) -> Exercise {
        let bodyweightAlternatives: [String: Exercise] = [
            "Dumbbell Squats": Exercise(
                name: "Bodyweight Squats",
                sets: exercise.sets,
                reps: exercise.reps + 5,
                weight: nil,
                duration: exercise.duration,
                restTime: exercise.restTime,
                instructions: "Stand with feet shoulder-width apart, lower into squat position, then return to standing",
                muscleGroup: exercise.muscleGroup,
                equipment: "None"
            ),
            "Dumbbell Bench Press": Exercise(
                name: "Push-ups",
                sets: exercise.sets,
                reps: exercise.reps,
                weight: nil,
                duration: exercise.duration,
                restTime: exercise.restTime,
                instructions: "Start in plank position, lower chest to ground, then push back up",
                muscleGroup: exercise.muscleGroup,
                equipment: "None"
            ),
            "Dumbbell Rows": Exercise(
                name: "Inverted Rows",
                sets: exercise.sets,
                reps: exercise.reps,
                weight: nil,
                duration: exercise.duration,
                restTime: exercise.restTime,
                instructions: "Use a low bar or table edge, pull chest to bar while keeping body straight",
                muscleGroup: exercise.muscleGroup,
                equipment: "Pull-up Bar or Table"
            )
        ]
        
        return bodyweightAlternatives[exercise.name] ?? Exercise(
            name: "Bodyweight \(exercise.name)",
            sets: exercise.sets,
            reps: exercise.reps,
            weight: nil,
            duration: exercise.duration,
            restTime: exercise.restTime,
            instructions: "Bodyweight version: \(exercise.instructions)",
            muscleGroup: exercise.muscleGroup,
            equipment: "None"
        )
    }
    
    private func addWeightsToExercise(_ exercise: Exercise) -> Exercise {
        if exercise.equipment == "None" {
            return Exercise(
                name: "Weighted \(exercise.name)",
                sets: exercise.sets,
                reps: max(1, exercise.reps - 3),
                weight: 5.0,
                duration: exercise.duration,
                restTime: exercise.restTime,
                instructions: "Add light dumbbells to increase resistance: \(exercise.instructions)",
                muscleGroup: exercise.muscleGroup,
                equipment: "Dumbbells"
            )
        }
        return exercise
    }
    
    private func reduceExerciseIntensity(_ exercise: Exercise) -> Exercise {
        return Exercise(
            name: exercise.name,
            sets: max(1, exercise.sets - 1),
            reps: exercise.reps,
            weight: exercise.weight,
            duration: exercise.duration.map { max(30, $0 - 30) },
            restTime: min(120, exercise.restTime + 30),
            instructions: "Modified for lower intensity: \(exercise.instructions)",
            muscleGroup: exercise.muscleGroup,
            equipment: exercise.equipment
        )
    }
    
    private func increaseExerciseIntensity(_ exercise: Exercise) -> Exercise {
        return Exercise(
            name: exercise.name,
            sets: exercise.sets + 1,
            reps: exercise.reps,
            weight: exercise.weight,
            duration: exercise.duration.map { $0 + 30 },
            restTime: max(30, exercise.restTime - 15),
            instructions: "Modified for higher intensity: \(exercise.instructions)",
            muscleGroup: exercise.muscleGroup,
            equipment: exercise.equipment
        )
    }
    
    private func generateRecoveryExercises() -> [Exercise] {
        return [
            Exercise(
                name: "Gentle Stretching",
                sets: 1,
                reps: 1,
                weight: nil,
                duration: 300,
                restTime: 0,
                instructions: "Hold each stretch for 30 seconds, focus on breathing and relaxation",
                muscleGroup: "Recovery",
                equipment: "None"
            ),
            Exercise(
                name: "Foam Rolling",
                sets: 1,
                reps: 1,
                weight: nil,
                duration: 180,
                restTime: 0,
                instructions: "Gently roll over major muscle groups to release tension",
                muscleGroup: "Recovery",
                equipment: "Foam Roller"
            )
        ]
    }
    
    private func shouldAvoidExercise(_ exercise: Exercise) -> Bool {
        let injuries = sessionContext.currentPreferences.injuries
        let exerciseName = exercise.name.lowercased()
        
        for injury in injuries {
            switch injury.lowercased() {
            case "knee":
                if exerciseName.contains("squat") || exerciseName.contains("lunge") || exerciseName.contains("jump") {
                    return true
                }
            case "back":
                if exerciseName.contains("deadlift") || exerciseName.contains("bend") || exerciseName.contains("twist") {
                    return true
                }
            case "shoulder":
                if exerciseName.contains("press") || exerciseName.contains("push") || exerciseName.contains("overhead") {
                    return true
                }
            default:
                break
            }
        }
        return false
    }
    
    private func generateSafeAlternativeExercises() -> [Exercise] {
        return [
            Exercise(
                name: "Gentle Walking",
                sets: 1,
                reps: 1,
                weight: nil,
                duration: 600,
                restTime: 0,
                instructions: "Walk at a comfortable pace, focusing on good posture",
                muscleGroup: "Cardio",
                equipment: "None"
            ),
            Exercise(
                name: "Seated Stretches",
                sets: 3,
                reps: 1,
                weight: nil,
                duration: 60,
                restTime: 30,
                instructions: "Gentle stretches that can be done while seated",
                muscleGroup: "Flexibility",
                equipment: "Chair"
            )
        ]
    }
    
    private func reduceDifficulty(_ difficulty: String) -> String {
        switch difficulty {
        case "Advanced": return "Intermediate"
        case "Intermediate": return "Beginner"
        default: return "Beginner"
        }
    }
    
    private func increaseDifficulty(_ difficulty: String) -> String {
        switch difficulty {
        case "Beginner": return "Intermediate"
        case "Intermediate": return "Advanced"
        default: return "Advanced"
        }
    }
    
    private func generateAdditionalExercises(for targetAreas: [String]) -> [Exercise] {
        var exercises: [Exercise] = []
        
        for area in targetAreas {
            switch area {
            case "Legs":
                exercises.append(Exercise(
                    name: "Wall Sit",
                    sets: 2,
                    reps: 1,
                    weight: nil,
                    duration: 45,
                    restTime: 60,
                    instructions: "Lean against wall, slide down until thighs are parallel to ground",
                    muscleGroup: "Legs",
                    equipment: "Wall"
                ))
            case "Arms":
                exercises.append(Exercise(
                    name: "Tricep Dips",
                    sets: 2,
                    reps: 8,
                    weight: nil,
                    duration: nil,
                    restTime: 60,
                    instructions: "Use chair or bench, lower body by bending elbows",
                    muscleGroup: "Arms",
                    equipment: "Chair"
                ))
            case "Core":
                exercises.append(Exercise(
                    name: "Plank Hold",
                    sets: 2,
                    reps: 1,
                    weight: nil,
                    duration: 45,
                    restTime: 60,
                    instructions: "Hold plank position with straight body line",
                    muscleGroup: "Core",
                    equipment: "None"
                ))
            default:
                break
            }
        }
        
        return exercises
    }
    
    private func generateLegFocusedExercises() -> [Exercise] {
        return [
            Exercise(
                name: "Bodyweight Squats",
                sets: 3,
                reps: 15,
                weight: nil,
                duration: nil,
                restTime: 60,
                instructions: "Stand with feet shoulder-width apart, lower into squat position",
                muscleGroup: "Legs",
                equipment: "None"
            ),
            Exercise(
                name: "Lunges",
                sets: 3,
                reps: 12,
                weight: nil,
                duration: nil,
                restTime: 60,
                instructions: "Step forward into lunge position, alternate legs",
                muscleGroup: "Legs",
                equipment: "None"
            ),
            Exercise(
                name: "Calf Raises",
                sets: 3,
                reps: 20,
                weight: nil,
                duration: nil,
                restTime: 45,
                instructions: "Stand on edge of step, raise heels up and down",
                muscleGroup: "Legs",
                equipment: "Step"
            )
        ]
    }
    
    private func generateArmFocusedExercises() -> [Exercise] {
        return [
            Exercise(
                name: "Push-ups",
                sets: 3,
                reps: 10,
                weight: nil,
                duration: nil,
                restTime: 60,
                instructions: "Start in plank position, lower chest to ground",
                muscleGroup: "Arms",
                equipment: "None"
            ),
            Exercise(
                name: "Tricep Dips",
                sets: 3,
                reps: 12,
                weight: nil,
                duration: nil,
                restTime: 60,
                instructions: "Use chair or bench, lower body by bending elbows",
                muscleGroup: "Arms",
                equipment: "Chair"
            ),
            Exercise(
                name: "Arm Circles",
                sets: 2,
                reps: 1,
                weight: nil,
                duration: 60,
                restTime: 30,
                instructions: "Make circular motions with arms, forward and backward",
                muscleGroup: "Arms",
                equipment: "None"
            )
        ]
    }
    
    private func generateCoreFocusedExercises() -> [Exercise] {
        return [
            Exercise(
                name: "Plank Hold",
                sets: 3,
                reps: 1,
                weight: nil,
                duration: 45,
                restTime: 60,
                instructions: "Hold plank position with straight body line",
                muscleGroup: "Core",
                equipment: "None"
            ),
            Exercise(
                name: "Crunches",
                sets: 3,
                reps: 15,
                weight: nil,
                duration: nil,
                restTime: 45,
                instructions: "Lie on back, lift shoulders off ground using core",
                muscleGroup: "Core",
                equipment: "None"
            ),
            Exercise(
                name: "Russian Twists",
                sets: 3,
                reps: 20,
                weight: nil,
                duration: nil,
                restTime: 45,
                instructions: "Sit with knees bent, twist torso side to side",
                muscleGroup: "Core",
                equipment: "None"
            )
        ]
    }
    
    private func formatIntelligentUpdateResponse(_ workout: WorkoutPlan, modifications: [IntelligentModification]) -> String {
        let exercisesFormatted = formatExercises(workout.exercises)
        
        var modificationSummary = ""
        for modification in modifications {
            switch modification {
            case .changeWorkoutType:
                modificationSummary += "• Changed workout type based on your request\n"
            case .adaptToBodyweight:
                modificationSummary += "• Adapted to bodyweight exercises\n"
            case .addWeights:
                modificationSummary += "• Added weight resistance\n"
            case .reduceIntensity:
                modificationSummary += "• Reduced intensity for recovery\n"
            case .increaseIntensity:
                modificationSummary += "• Increased intensity for challenge\n"
            case .addRecoveryExercises:
                modificationSummary += "• Added recovery and stretching\n"
            case .avoidInjuredAreas:
                modificationSummary += "• Avoided exercises for injured areas\n"
            case .reduceDuration:
                modificationSummary += "• Shortened workout duration\n"
            case .increaseDuration:
                modificationSummary += "• Extended workout duration\n"
            case .focusOnLegs:
                modificationSummary += "• Focused on leg strengthening\n"
            case .focusOnArms:
                modificationSummary += "• Focused on arm strengthening\n"
            case .focusOnCore:
                modificationSummary += "• Focused on core strengthening\n"
            }
        }
        
        return """
        **Intelligent Workout Adaptation** 🧠💪
        
        I've intelligently modified your workout based on your needs and preferences:
        
        **🎯 \(workout.title)**
        \(workout.description)
        
        **⏱️ Duration**: \(workout.duration) minutes
        **💪 Difficulty**: \(workout.difficulty)
        **🏋️ Equipment**: \(workout.equipment.joined(separator: ", "))
        **🎯 Target Areas**: \(workout.targetMuscleGroups.joined(separator: ", "))
        
        **📋 Exercises:**
        \(exercisesFormatted)
        
        **🧠 Intelligent Adaptations Made:**
        \(modificationSummary)
        
        **💡 Why These Changes:**
        • Equipment available: \(sessionContext.currentPreferences.bodyweightOnly ? "Bodyweight only" : "Has equipment")
        • Physical condition: \(sessionContext.currentPreferences.isSore ? "Recovery mode" : "Ready to work")
        • Energy level: \(sessionContext.currentPreferences.energyLevel.rawValue)
        • Focus areas: \(sessionContext.currentPreferences.targetAreas.joined(separator: ", "))
        
        Would you like me to make any other intelligent adjustments?
        """
    }
    
    private func formatIntelligentWorkoutResponse(_ workout: WorkoutPlan) -> String {
        let exercisesFormatted = formatExercises(workout.exercises)
        
        return """
        **Intelligent Workout Created** 🧠💪
        
        I've created a personalized workout based on your needs and preferences:
        
        **🎯 \(workout.title)**
        \(workout.description)
        
        **⏱️ Duration**: \(workout.duration) minutes
        **💪 Difficulty**: \(workout.difficulty)
        **🏋️ Equipment**: \(workout.equipment.joined(separator: ", "))
        **🎯 Target Areas**: \(workout.targetMuscleGroups.joined(separator: ", "))
        
        **📋 Exercises:**
        \(exercisesFormatted)
        
        **🧠 Why This Workout:**
        • Equipment available: \(sessionContext.currentPreferences.bodyweightOnly ? "Bodyweight only" : "Has equipment")
        • Physical condition: \(sessionContext.currentPreferences.isSore ? "Recovery mode" : "Ready to work")
        • Energy level: \(sessionContext.currentPreferences.energyLevel.rawValue)
        • Focus areas: \(sessionContext.currentPreferences.targetAreas.joined(separator: ", "))
        
        **💡 How to Adapt:**
        • Say "make it easier" if it's too challenging
        • Say "add weights" if you have dumbbells
        • Say "focus on [area]" to target specific muscles
        • Say "I'm sore" to get recovery-focused exercises
        
        Ready to start? Just tell me what you'd like to adjust!
        """
    }
    
    // MARK: - Context Management
    private func updateContext(with message: String) {
        let lowercased = message.lowercased()
        
        // Add to conversation history
        sessionContext.addToMemory(message)
        
        // Parse and merge preferences
        let newPreferences = parseWorkoutPreferences(lowercased)
        sessionContext.currentPreferences.merge(with: newPreferences)
        
        print("🤖 updateContext: Updated preferences with new input")
    }
    
    private func getContextualResponse(_ userMessage: String) -> String {
        print("🤖 getContextualResponse: Processing message: '\(userMessage)'")
        print("🤖 getContextualResponse: Has current plan: \(combinedContext.lastWorkoutPlan != nil)")
        
        // If we have a current workout plan, ALWAYS try to modify it based on user request
        if let currentPlan = combinedContext.lastWorkoutPlan {
            print("🤖 getContextualResponse: Found current plan to modify: \(currentPlan.title)")
            
            // Parse what the user wants to change
            let modifications = parseUserModifications(userMessage, currentPlan: currentPlan)
            
            if !modifications.isEmpty {
                print("🤖 getContextualResponse: Applying modifications: \(modifications)")
                let updatedPlan = applyModificationsToPlan(currentPlan, modifications: modifications)
                sessionContext.lastWorkoutPlan = updatedPlan
                lastCreatedWorkoutPlan = updatedPlan
                return formatUpdatedPlanResponse(updatedPlan)
            }
        }
        
        // No current plan or no modifications detected, create new workout
        print("🤖 getContextualResponse: Creating new workout")
        let workout = generateWorkoutPlan(userMessage)
        return formatWorkoutPlanResponse(workout)
    }
    

    
    private func isExplicitNewWorkoutRequest(_ message: String) -> Bool {
        let explicitNewKeywords = [
            "new workout", "create new", "start over", "different workout", "another workout",
            "give me a new", "make me a new", "i want a new", "need a new"
        ]
        
        return explicitNewKeywords.contains { message.lowercased().contains($0) }
    }
    
    private func updateExistingWorkout(_ userMessage: String) -> String {
        guard let lastWorkout = sessionContext.lastWorkoutPlan else {
            return "I don't have a previous workout to update. Let me create a new one for you!"
        }
        
        let lowercased = userMessage.lowercased()
        var updatedExercises = lastWorkout.exercises
        
        // Handle equipment removal requests
        if lowercased.contains("without") || lowercased.contains("no") {
            if lowercased.contains("bag") || lowercased.contains("punching") {
                // Remove bag-related exercises and replace with shadow boxing
                updatedExercises = updatedExercises.compactMap { exercise in
                    if let equipment = exercise.equipment, equipment.contains("Bag") || equipment.contains("Gloves") {
                        // Replace with shadow boxing equivalent
                        return Exercise(
                            name: "Shadow Boxing - \(exercise.name)",
                            sets: exercise.sets,
                            reps: exercise.reps,
                            weight: exercise.weight,
                            duration: exercise.duration,
                            restTime: exercise.restTime,
                            instructions: "Shadow boxing version: \(exercise.instructions)",
                            muscleGroup: exercise.muscleGroup,
                            equipment: "None"
                        )
                    }
                    return exercise
                }
            }
            
            if lowercased.contains("dumbbell") || lowercased.contains("weight") {
                // Replace weight exercises with bodyweight alternatives
                updatedExercises = updatedExercises.compactMap { exercise in
                    if let equipment = exercise.equipment, equipment.contains("Dumbbell") || equipment.contains("Barbell") {
                        return getBodyweightAlternative(for: exercise)
                    }
                    return exercise
                }
            }
        }
        
        // Handle intensity changes
        if lowercased.contains("easier") || lowercased.contains("gentle") {
            updatedExercises = updatedExercises.map { exercise in
                Exercise(
                    name: exercise.name,
                    sets: max(1, exercise.sets - 1),
                    reps: exercise.reps,
                    weight: exercise.weight,
                    duration: exercise.duration.map { max(30, $0 - 30) },
                    restTime: min(120, exercise.restTime + 30),
                    instructions: exercise.instructions,
                    muscleGroup: exercise.muscleGroup,
                    equipment: exercise.equipment
                )
            }
        }
        
        if lowercased.contains("harder") || lowercased.contains("intense") {
            updatedExercises = updatedExercises.map { exercise in
                Exercise(
                    name: exercise.name,
                    sets: exercise.sets + 1,
                    reps: exercise.reps,
                    weight: exercise.weight,
                    duration: exercise.duration.map { $0 + 30 },
                    restTime: max(30, exercise.restTime - 15),
                    instructions: exercise.instructions,
                    muscleGroup: exercise.muscleGroup,
                    equipment: exercise.equipment
                )
            }
        }
        
        // Create updated workout plan
        let updatedWorkout = WorkoutPlan(
            title: "Updated \(lastWorkout.title)",
            description: "Modified version of your previous workout based on your feedback",
            exercises: updatedExercises,
            duration: lastWorkout.duration,
            difficulty: lastWorkout.difficulty,
            equipment: updatedExercises.compactMap { $0.equipment == "None" ? nil : $0.equipment }.uniqued(),
            targetMuscleGroups: lastWorkout.targetMuscleGroups
        )
        
        // Automatically schedule the updated workout to calendar
        let (date, time) = getDefaultScheduleTime()
        calendarManager?.scheduleWorkout(updatedWorkout, date: date, time: time)
        
        // Update context and return response
        sessionContext.lastWorkoutPlan = updatedWorkout
        sessionContext.isUpdatingWorkout = false
        lastCreatedWorkoutPlan = updatedWorkout
        awaitingSchedulingResponse = true
        
        return """
        **Updated \(updatedWorkout.title)** ✅
        
        I've modified your previous workout based on your feedback! Here are the changes:
        
        **Equipment Needed**: \(updatedWorkout.equipment.joined(separator: ", "))
        **Target Areas**: \(updatedWorkout.targetMuscleGroups.joined(separator: ", "))
        **Duration**: \(updatedWorkout.duration) minutes
        **Difficulty**: \(updatedWorkout.difficulty)
        
        **Updated Workout Breakdown:**
        \(formatExercises(updatedWorkout.exercises))
        
        **What would you like to do next?**
        • **Edit more** - Say "add more core", "make it easier", etc.
        • **Schedule it** - Say "yes" or "schedule it" and I'll ask when
        • **Create another** - Ask for a different type of workout
        
        Just tell me what you'd like to do!
        """
    }
    
    private func getBodyweightAlternative(for exercise: Exercise) -> Exercise {
        let alternatives: [String: Exercise] = [
            "Dumbbell Squats": Exercise(name: "Bodyweight Squats", sets: exercise.sets, reps: exercise.reps + 5, weight: nil, duration: exercise.duration, restTime: exercise.restTime, instructions: "Bodyweight squat variation", muscleGroup: exercise.muscleGroup, equipment: "None"),
            "Dumbbell Bench Press": Exercise(name: "Push-ups", sets: exercise.sets, reps: exercise.reps, weight: nil, duration: exercise.duration, restTime: exercise.restTime, instructions: "Bodyweight chest exercise", muscleGroup: exercise.muscleGroup, equipment: "None"),
            "Dumbbell Rows": Exercise(name: "Inverted Rows", sets: exercise.sets, reps: exercise.reps, weight: nil, duration: exercise.duration, restTime: exercise.restTime, instructions: "Bodyweight back exercise", muscleGroup: exercise.muscleGroup, equipment: "Pull-up Bar"),
            "Barbell Squats": Exercise(name: "Pistol Squats", sets: exercise.sets, reps: max(1, exercise.reps - 5), weight: nil, duration: exercise.duration, restTime: exercise.restTime, instructions: "Advanced bodyweight squat", muscleGroup: exercise.muscleGroup, equipment: "None"),
            "Bench Press": Exercise(name: "Diamond Push-ups", sets: exercise.sets, reps: exercise.reps, weight: nil, duration: exercise.duration, restTime: exercise.restTime, instructions: "Advanced push-up variation", muscleGroup: exercise.muscleGroup, equipment: "None")
        ]
        
        return alternatives[exercise.name] ?? Exercise(
            name: "Bodyweight \(exercise.name)",
            sets: exercise.sets,
            reps: exercise.reps,
            weight: nil,
            duration: exercise.duration,
            restTime: exercise.restTime,
            instructions: "Bodyweight version of \(exercise.name)",
            muscleGroup: exercise.muscleGroup,
            equipment: "None"
        )
    }
    
    private func generateSmartResponse(_ userMessage: String) -> String {
        let lowercased = userMessage.lowercased()
        
        // Use combined context for decision making
        let context = combinedContext
        
        print("🤖 generateSmartResponse: Using combined context")
        print("🤖 - Persistent workout history: \(persistentContext.workoutHistory.count)")
        print("🤖 - Session workout plan: \(sessionContext.lastWorkoutPlan?.title ?? "None")")
        print("🤖 - User preferences: \(context.currentPreferences.targetAreas)")
        
        // Check for emotional/mental health support
        if isEmotionalSupportRequest(lowercased) {
            return generateEmotionalSupportResponse(userMessage)
        }
        
        // Check for scheduling response
        if awaitingSchedulingResponse {
            return handleSchedulingResponse(userMessage)
        }
        
        // Check for workout-related keywords
        let workoutKeywords = ["workout", "exercise", "training", "fitness", "gym", "strength", "cardio", "yoga", "pilates", "boxing", "kickboxing", "calisthenics", "hiit", "crossfit", "legs", "arms", "core", "chest", "back", "shoulders", "abs", "glutes", "squat", "push", "pull", "plank", "burpee", "lunge", "deadlift", "bench", "dumbbell", "barbell", "equipment", "bodyweight", "intensity", "duration", "sets", "reps", "schedule", "plan", "routine"]
        
        if workoutKeywords.contains(where: { lowercased.contains($0) }) {
            let response = getContextualResponse(userMessage)
            
            // If a new workout was created, save it to persistent context
            if let workoutPlan = lastCreatedWorkoutPlan {
                var persistentContext = self.persistentContext
                persistentContext.updateWithNewWorkout(workoutPlan)
                self.persistentContext = persistentContext
                
                print("🤖 Saved workout to persistent context: \(workoutPlan.title)")
            }
            
            return response
        }
        
        // Check for profile-related keywords
        let profileKeywords = ["profile", "name", "age", "weight", "height", "goal", "preference", "setting", "edit"]
        if profileKeywords.contains(where: { lowercased.contains($0) }) {
            return generateProfileResponse(userMessage)
        }
        
        // Check for calendar-related keywords
        let calendarKeywords = ["calendar", "schedule", "date", "time", "appointment", "event", "reminder"]
        if calendarKeywords.contains(where: { lowercased.contains($0) }) {
            return generateCalendarResponse(userMessage)
        }
        
        // Default response with context awareness
        return generateContextualDefaultResponse(userMessage)
    }
    
    private func isRespondingToSchedulingQuestion(_ message: String) -> Bool {
        return awaitingSchedulingResponse && (
            message.contains("yes") || message.contains("yeah") || message.contains("sure") || 
            message.contains("ok") || message.contains("okay") || message.contains("schedule") ||
            message.contains("book") || message.contains("calendar") || message.contains("when") ||
            message.contains("today") || message.contains("tomorrow") || message.contains("morning") ||
            message.contains("afternoon") || message.contains("evening") || message.contains("night")
        )
    }
    
    private func handleSchedulingResponse(_ userMessage: String) -> String {
        let lowercased = userMessage.lowercased()
        
        print("🤖 GeminiService: Handling scheduling response: '\(userMessage)'")
        print("🤖 GeminiService: calendarManager is \(calendarManager != nil ? "configured" : "NOT configured")")
        
        // Check for confirmation
        let isConfirmed = lowercased.contains("yes") || lowercased.contains("sure") || lowercased.contains("ok") || lowercased.contains("schedule") || lowercased.contains("add") || lowercased.contains("book")
        
        if isConfirmed {
            // Parse date and time from user message
            let (date, time) = parseDateAndTime(from: userMessage)
            let scheduledDateTime = parseDateTime(date: date, time: time)
            
            print("🤖 GeminiService: Parsed date: \(date), time: \(time), scheduledDateTime: \(scheduledDateTime)")
            
            // Actually schedule the workout
            if let plan = lastCreatedWorkoutPlan {
                print("🤖 GeminiService: Scheduling workout plan: \(plan.title)")
                
                // Ensure calendar manager is configured
                guard let calendarManager = self.calendarManager else {
                    print("🤖 GeminiService: ERROR - Calendar manager not configured!")
                    return "I'm sorry, but I can't schedule workouts right now. Please try again later."
                }
                
                // Add to calendar manager
                calendarManager.scheduleWorkout(plan, date: date, time: time)
                
                // Also add to workout plans for dashboard
                calendarManager.addWorkoutPlan(plan)
                
                // Update persistent context with scheduled workout
                var persistentContext = self.persistentContext
                persistentContext.lastInteractionDate = Date()
                self.persistentContext = persistentContext
                
                awaitingSchedulingResponse = false // Reset the state
                
                return """
                **✅ Workout Scheduled Successfully!**
                
                I've added **\(plan.title)** to your calendar for **\(DateFormatter.prettyDate.string(from: scheduledDateTime))**.
                
                **Scheduled Details:**
                📅 Date: \(DateFormatter.prettyDate.string(from: scheduledDateTime))
                ⏰ Time: \(time)
                🏋️ Workout: \(plan.title)
                ⏱️ Duration: \(plan.duration) minutes
                🎯 Target Areas: \(plan.targetMuscleGroups.joined(separator: ", "))
                
                **What's Next?**
                • Check your Calendar tab to see your scheduled workout
                • Ask me to create another workout plan
                • Get nutrition advice for your fitness goals
                • Need motivation or emotional support? I'm here for you!
                
                What would you like to do next?
                """
            } else {
                print("🤖 GeminiService: ERROR - No workout plan to schedule!")
                return "I'm sorry, but I don't have a workout plan ready to schedule. Let me create one for you first!"
            }
        }
        
        // If not confirmed, ask for clarification
        return """
        **Scheduling Your Workout**
        
        I have a great workout ready for you! When would you like to do it?
        
        **Quick Options:**
        • "Yes" - Schedule for today at 6 PM
        • "Tomorrow at 7 AM" - Schedule for tomorrow morning
        • "Monday at 5 PM" - Schedule for specific day/time
        • "Not now" - I'll save it for later
        
        **Examples:**
        • "Schedule it for tomorrow at 7 AM"
        • "Yes, Monday at 5 PM"
        • "Add it to my calendar for Friday at 6 PM"
        
        Just tell me when works best for you!
        """
    }
    
    private func parseDateAndTime(from message: String) -> (Date, String) {
        let lowercased = message.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        // Default to today at 6 PM
        var targetDate = now
        var timeString = "6:00 PM"
        
        // Parse specific days
        if lowercased.contains("tomorrow") {
            targetDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        } else if lowercased.contains("monday") || lowercased.contains("mon") {
            targetDate = getNextWeekday(2)
        } else if lowercased.contains("tuesday") || lowercased.contains("tue") {
            targetDate = getNextWeekday(3)
        } else if lowercased.contains("wednesday") || lowercased.contains("wed") {
            targetDate = getNextWeekday(4)
        } else if lowercased.contains("thursday") || lowercased.contains("thu") {
            targetDate = getNextWeekday(5)
        } else if lowercased.contains("friday") || lowercased.contains("fri") {
            targetDate = getNextWeekday(6)
        } else if lowercased.contains("saturday") || lowercased.contains("sat") {
            targetDate = getNextWeekday(7)
        } else if lowercased.contains("sunday") || lowercased.contains("sun") {
            targetDate = getNextWeekday(1)
        }
        
        // Parse time
        if lowercased.contains("morning") || lowercased.contains("am") {
            timeString = "7:00 AM"
        } else if lowercased.contains("afternoon") {
            timeString = "2:00 PM"
        } else if lowercased.contains("evening") || lowercased.contains("pm") {
            timeString = "6:00 PM"
        } else if lowercased.contains("night") {
            timeString = "8:00 PM"
        }
        
        // Parse specific times
        let timePattern = try? NSRegularExpression(pattern: "(\\d{1,2}):?(\\d{2})?\\s*(am|pm)?", options: .caseInsensitive)
        if let match = timePattern?.firstMatch(in: message, options: [], range: NSRange(message.startIndex..., in: message)) {
            let hourRange = Range(match.range(at: 1), in: message)!
            let hour = Int(message[hourRange]) ?? 6
            
            var minute = 0
            if match.range(at: 2).location != NSNotFound {
                let minuteRange = Range(match.range(at: 2), in: message)!
                minute = Int(message[minuteRange]) ?? 0
            }
            
            var ampm = "PM"
            if match.range(at: 3).location != NSNotFound {
                let ampmRange = Range(match.range(at: 3), in: message)!
                ampm = String(message[ampmRange]).uppercased()
            }
            
            timeString = "\(hour):\(String(format: "%02d", minute)) \(ampm)"
        }
        
        return (targetDate, timeString)
    }
    
    private func getNextWeekday(_ weekday: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        let daysToAdd = (weekday - currentWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysToAdd, to: now) ?? now
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
        
        // Default to 6 PM if parsing fails
        return (18, 0)
    }
    
    private func generateWorkoutPlan(_ userMessage: String) -> WorkoutPlan {
        let lowercased = userMessage.lowercased()
        
        // Use combined context for better personalization
        let context = combinedContext
        var preferences = context.currentPreferences
        
        // Parse new preferences from the message
        let newPreferences = parseWorkoutPreferences(lowercased)
        preferences.merge(with: newPreferences)
        
        print("🤖 generateWorkoutPlan: Creating workout with preferences:")
        print("🤖 - Workout type: \(preferences.workoutType.displayName)")
        print("🤖 - Target areas: \(preferences.targetAreas)")
        print("🤖 - Equipment: \(preferences.equipmentList)")
        print("🤖 - Intensity: \(preferences.intensity)")
        print("🤖 - Previous workouts: \(persistentContext.workoutHistory.count)")
        
        // If we have previous workouts, try to build upon them
        if !persistentContext.workoutHistory.isEmpty {
            let lastWorkout = persistentContext.workoutHistory.last!
            print("🤖 Building upon last workout: \(lastWorkout.title)")
            
            // If user wants similar workout, use the same type
            if lowercased.contains("similar") || lowercased.contains("same") || lowercased.contains("continue") {
                preferences.workoutType = lastWorkout.title.contains("Boxing") ? .boxing :
                                        lastWorkout.title.contains("Kickboxing") ? .kickboxing :
                                        lastWorkout.title.contains("Strength") ? .strength :
                                        lastWorkout.title.contains("Cardio") ? .cardio : .none
            }
            
            // Use target areas from last workout if none specified
            if preferences.targetAreas.isEmpty {
                preferences.targetAreas = lastWorkout.targetMuscleGroups
            }
        }
        
        // Create workout based on type
        let workout: WorkoutPlan
        
        switch preferences.workoutType {
        case .boxing:
            workout = createBoxingWorkout(preferences: preferences)
        case .kickboxing:
            workout = createKickboxingWorkout(preferences: preferences)
        case .mma:
            workout = createMMAWorkout(preferences: preferences)
        case .strength:
            workout = createStrengthWorkout(preferences: preferences)
        case .cardio:
            workout = createCardioWorkout(preferences: preferences)
        case .yoga:
            workout = createYogaWorkout(preferences: preferences)
        case .pilates:
            workout = createPilatesWorkout(preferences: preferences)
        case .crossfit:
            workout = createCrossfitWorkout(preferences: preferences)
        case .calisthenics:
            workout = createCalisthenicsWorkout(preferences: preferences)
        case .hiit:
            workout = createHIITWorkout(preferences: preferences)
        case .none:
            // Default to strength if no specific type requested
            workout = createStrengthWorkout(preferences: preferences)
        }
        
        // Update session context
        sessionContext.lastWorkoutPlan = workout
        sessionContext.currentWorkoutType = preferences.workoutType
        sessionContext.currentPreferences = preferences
        lastCreatedWorkoutPlan = workout
        
        // Save to persistent context
        var persistentContext = self.persistentContext
        persistentContext.updateWithNewWorkout(workout)
        persistentContext.lastWorkoutType = preferences.workoutType
        self.persistentContext = persistentContext
        
        print("🤖 Created workout: \(workout.title)")
        return workout
    }
    
    private func createBoxingWorkout(preferences: WorkoutPreferences) -> WorkoutPlan {
        let duration = getDuration(preferences.duration)
        let intensity = getIntensity(preferences.intensity)
        
        let exercises = [
            Exercise(name: "Shadow Boxing", sets: 3, reps: 1, weight: nil, duration: 120, restTime: 30, instructions: "Basic boxing combinations in the air", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Jab-Cross Combos", sets: 4, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Fast jab-cross combinations", muscleGroup: "Arms", equipment: "None"),
            Exercise(name: "Hook-Uppercut Combos", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 45, instructions: "Power hook followed by uppercut", muscleGroup: "Arms", equipment: "None"),
            Exercise(name: "Footwork Drills", sets: 3, reps: 1, weight: nil, duration: 120, restTime: 30, instructions: "Boxing stance and movement", muscleGroup: "Legs", equipment: "None"),
            Exercise(name: "Speed Bag Work", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Rhythm and timing practice", muscleGroup: "Arms", equipment: "Speed Bag"),
            Exercise(name: "Heavy Bag Work", sets: 4, reps: 1, weight: nil, duration: 120, restTime: 60, instructions: "Power punching combinations", muscleGroup: "Full Body", equipment: "Heavy Bag"),
            Exercise(name: "Defense Drills", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Slipping, blocking, and weaving", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Boxing Burpees", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Cardio with boxing stance", muscleGroup: "Full Body", equipment: "None")
        ]
        
        return WorkoutPlan(
            title: "Boxing Power Workout",
            description: "High-intensity boxing training with focus on technique, power, and cardio",
            exercises: exercises,
            duration: duration,
            difficulty: intensity,
            equipment: ["Boxing Gloves", "Heavy Bag", "Speed Bag"],
            targetMuscleGroups: ["Full Body", "Cardio", "Core"]
        )
    }
    
    private func createKickboxingWorkout(preferences: WorkoutPreferences) -> WorkoutPlan {
        let duration = getDuration(preferences.duration)
        let intensity = getIntensity(preferences.intensity)
        
        let exercises = [
            Exercise(name: "Kickboxing Stance", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Basic stance and footwork", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Jab-Cross-Kick Combos", sets: 4, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Punch-kick combinations", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Roundhouse Kicks", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 45, instructions: "Power roundhouse kicks", muscleGroup: "Legs", equipment: "None"),
            Exercise(name: "Knee Strikes", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Close-range knee attacks", muscleGroup: "Legs", equipment: "None"),
            Exercise(name: "Elbow Strikes", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Close-range elbow techniques", muscleGroup: "Arms", equipment: "None"),
            Exercise(name: "Kickboxing Burpees", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Cardio with kickboxing moves", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Shadow Kickboxing", sets: 3, reps: 1, weight: nil, duration: 120, restTime: 45, instructions: "Full combination practice", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Bag Work", sets: 4, reps: 1, weight: nil, duration: 120, restTime: 60, instructions: "Heavy bag combinations", muscleGroup: "Full Body", equipment: "Heavy Bag")
        ]
        
        return WorkoutPlan(
            title: "Kickboxing Warrior",
            description: "Dynamic kickboxing workout combining punches, kicks, knees, and elbows",
            exercises: exercises,
            duration: duration,
            difficulty: intensity,
            equipment: ["Kickboxing Gloves", "Heavy Bag", "Shin Guards"],
            targetMuscleGroups: ["Full Body", "Cardio", "Legs", "Core"]
        )
    }
    
    private func createMMAWorkout(preferences: WorkoutPreferences) -> WorkoutPlan {
        let duration = getDuration(preferences.duration)
        let intensity = getIntensity(preferences.intensity)
        
        let exercises = [
            Exercise(name: "Muay Thai Kickboxing", sets: 3, reps: 1, weight: nil, duration: 120, restTime: 30, instructions: "Focus on kicks and punches", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Jiu-Jitsu Takedowns", sets: 4, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Learn basic takedowns and submissions", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Boxing Drills", sets: 3, reps: 1, weight: nil, duration: 120, restTime: 30, instructions: "Practice boxing combinations and footwork", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Kickboxing Sparring", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Simulated sparring with focus on striking", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Jiu-Jitsu Groundwork", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Learn ground fighting techniques", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Muay Thai Pad Work", sets: 4, reps: 1, weight: nil, duration: 120, restTime: 60, instructions: "Focus on kicks and punches with pads", muscleGroup: "Full Body", equipment: "Pads"),
            Exercise(name: "Boxing Bag Work", sets: 3, reps: 1, weight: nil, duration: 120, restTime: 60, instructions: "Practice boxing combinations with heavy bags", muscleGroup: "Full Body", equipment: "Heavy Bag"),
            Exercise(name: "Kickboxing Sparring Drills", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Practice sparring drills with focus on striking", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Jiu-Jitsu Groundwork Drills", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Practice ground fighting drills", muscleGroup: "Full Body", equipment: "None")
        ]
        
        return WorkoutPlan(
            title: "MMA Training",
            description: "Comprehensive MMA training focusing on striking, grappling, and groundwork",
            exercises: exercises,
            duration: duration,
            difficulty: intensity,
            equipment: ["MMA Gloves", "Pads", "Heavy Bag"],
            targetMuscleGroups: ["Full Body", "Cardio", "Legs", "Core", "Arms"]
        )
    }
    
    private func createStrengthWorkout(preferences: WorkoutPreferences) -> WorkoutPlan {
        let duration = getDuration(preferences.duration)
        let intensity = getIntensity(preferences.intensity)
        var exercises: [Exercise] = []
        var equipment: [String] = []
        
        if preferences.hasBarbell {
            exercises += [
                Exercise(name: "Barbell Squats", sets: 4, reps: 10, weight: nil, duration: nil, restTime: 120, instructions: "Compound leg exercise", muscleGroup: "Legs", equipment: "Barbell"),
                Exercise(name: "Deadlifts", sets: 4, reps: 8, weight: nil, duration: nil, restTime: 180, instructions: "Posterior chain strength", muscleGroup: "Back", equipment: "Barbell"),
                Exercise(name: "Bench Press", sets: 4, reps: 10, weight: nil, duration: nil, restTime: 120, instructions: "Chest and triceps", muscleGroup: "Chest", equipment: "Barbell"),
                Exercise(name: "Overhead Press", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 120, instructions: "Shoulder strength", muscleGroup: "Shoulders", equipment: "Barbell")
            ]
            equipment.append("Barbell")
        } else if preferences.hasDumbbells {
            exercises += [
                Exercise(name: "Dumbbell Squats", sets: 4, reps: 12, weight: nil, duration: nil, restTime: 90, instructions: "Leg strength", muscleGroup: "Legs", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Deadlifts", sets: 4, reps: 10, weight: nil, duration: nil, restTime: 120, instructions: "Hip hinge movement", muscleGroup: "Back", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Bench Press", sets: 4, reps: 10, weight: nil, duration: nil, restTime: 120, instructions: "Chest development", muscleGroup: "Chest", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Rows", sets: 4, reps: 10, weight: nil, duration: nil, restTime: 90, instructions: "Back strength", muscleGroup: "Back", equipment: "Dumbbells")
            ]
            equipment.append("Dumbbells")
        } else {
            exercises += [
                Exercise(name: "Pistol Squats", sets: 3, reps: 6, weight: nil, duration: nil, restTime: 90, instructions: "Advanced leg strength", muscleGroup: "Legs", equipment: "None"),
                Exercise(name: "Push-ups", sets: 4, reps: 12, weight: nil, duration: nil, restTime: 90, instructions: "Chest and triceps", muscleGroup: "Chest", equipment: "None"),
                Exercise(name: "Pull-ups", sets: 4, reps: 8, weight: nil, duration: nil, restTime: 120, instructions: "Back and biceps", muscleGroup: "Back", equipment: "Pull-up Bar"),
                Exercise(name: "Handstand Push-ups", sets: 3, reps: 6, weight: nil, duration: nil, restTime: 120, instructions: "Shoulder strength", muscleGroup: "Shoulders", equipment: "None")
            ]
            equipment.append("Pull-up Bar")
        }
        
        exercises += [
            Exercise(name: "Planks", sets: 3, reps: 1, weight: nil, duration: 45, restTime: 60, instructions: "Core stability", muscleGroup: "Core", equipment: "None"),
            Exercise(name: "Side Planks", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 60, instructions: "Lateral core", muscleGroup: "Core", equipment: "None")
        ]
        
        return WorkoutPlan(
            title: "Strength Builder",
            description: "Progressive strength training focusing on compound movements",
            exercises: exercises,
            duration: duration,
            difficulty: intensity,
            equipment: equipment,
            targetMuscleGroups: preferences.targetAreas.isEmpty ? ["Full Body"] : preferences.targetAreas
        )
    }
    
    private func createCardioWorkout(preferences: WorkoutPreferences) -> WorkoutPlan {
        let duration = getDuration(preferences.duration)
        let intensity = getIntensity(preferences.intensity)
        let cardioIntensity = preferences.cardioIntensity
        
        var exercises: [Exercise] = []
        
        switch cardioIntensity {
        case .high:
            exercises = [
                Exercise(name: "Sprint Intervals", sets: 8, reps: 1, weight: nil, duration: 30, restTime: 90, instructions: "High-intensity sprint intervals", muscleGroup: "Cardio", equipment: "None"),
                Exercise(name: "Burpees", sets: 4, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Full-body cardio", muscleGroup: "Full Body", equipment: "None"),
                Exercise(name: "Mountain Climbers", sets: 4, reps: 1, weight: nil, duration: 45, restTime: 30, instructions: "Dynamic cardio", muscleGroup: "Full Body", equipment: "None"),
                Exercise(name: "Jump Squats", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Explosive leg cardio", muscleGroup: "Legs", equipment: "None"),
                Exercise(name: "High Knees", sets: 4, reps: 1, weight: nil, duration: 45, restTime: 30, instructions: "Running in place", muscleGroup: "Cardio", equipment: "None")
            ]
        case .medium:
            exercises = [
                Exercise(name: "Jogging", sets: 1, reps: 1, weight: nil, duration: 600, restTime: 0, instructions: "Steady-state cardio", muscleGroup: "Cardio", equipment: "None"),
                Exercise(name: "Jumping Jacks", sets: 3, reps: 1, weight: nil, duration: 120, restTime: 30, instructions: "Classic cardio", muscleGroup: "Full Body", equipment: "None"),
                Exercise(name: "Step-ups", sets: 3, reps: 1, weight: nil, duration: 120, restTime: 30, instructions: "Stair climbing motion", muscleGroup: "Legs", equipment: "None"),
                Exercise(name: "Butterfly Kicks", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Core cardio", muscleGroup: "Core", equipment: "None")
            ]
        case .low:
            exercises = [
                Exercise(name: "Brisk Walking", sets: 1, reps: 1, weight: nil, duration: 900, restTime: 0, instructions: "Low-impact cardio", muscleGroup: "Cardio", equipment: "None"),
                Exercise(name: "Marching in Place", sets: 3, reps: 1, weight: nil, duration: 180, restTime: 30, instructions: "Gentle movement", muscleGroup: "Cardio", equipment: "None"),
                Exercise(name: "Arm Circles", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Upper body mobility", muscleGroup: "Arms", equipment: "None")
            ]
        }
        
        return WorkoutPlan(
            title: "Cardio Blast",
            description: "Cardiovascular endurance training with \(cardioIntensity) intensity",
            exercises: exercises,
            duration: duration,
            difficulty: intensity,
            equipment: [],
            targetMuscleGroups: ["Cardio", "Full Body"]
        )
    }
    
    private func createHIITWorkout(preferences: WorkoutPreferences) -> WorkoutPlan {
        let duration = getDuration(preferences.duration)
        let intensity = getIntensity(preferences.intensity)
        
        let exercises = [
            Exercise(name: "Burpees", sets: 4, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Full-body explosive movement", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Mountain Climbers", sets: 4, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Dynamic core cardio", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Jump Squats", sets: 4, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Explosive leg power", muscleGroup: "Legs", equipment: "None"),
            Exercise(name: "Push-up to Renegade Row", sets: 4, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Upper body strength", muscleGroup: "Arms", equipment: "None"),
            Exercise(name: "Plank Jacks", sets: 4, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Core stability cardio", muscleGroup: "Core", equipment: "None"),
            Exercise(name: "High Knees", sets: 4, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Running cardio", muscleGroup: "Cardio", equipment: "None"),
            Exercise(name: "Spider-Man Push-ups", sets: 4, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Advanced push-up variation", muscleGroup: "Chest", equipment: "None"),
            Exercise(name: "Tuck Jumps", sets: 4, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Explosive jumping", muscleGroup: "Legs", equipment: "None")
        ]
        
        return WorkoutPlan(
            title: "HIIT Inferno",
            description: "High-intensity interval training for maximum calorie burn",
            exercises: exercises,
            duration: duration,
            difficulty: intensity,
            equipment: [],
            targetMuscleGroups: ["Full Body", "Cardio"]
        )
    }
    
    private func createYogaWorkout(preferences: WorkoutPreferences) -> WorkoutPlan {
        let duration = getDuration(preferences.duration)
        let intensity = getIntensity(preferences.intensity)
        
        let exercises = [
            Exercise(name: "Sun Salutation A", sets: 3, reps: 5, weight: nil, duration: nil, restTime: 30, instructions: "Dynamic flow sequence", muscleGroup: "Full Body", equipment: "Yoga Mat"),
            Exercise(name: "Warrior Poses", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 15, instructions: "Strength and balance", muscleGroup: "Full Body", equipment: "Yoga Mat"),
            Exercise(name: "Tree Pose", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 15, instructions: "Balance and focus", muscleGroup: "Full Body", equipment: "Yoga Mat"),
            Exercise(name: "Downward Dog", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Shoulder and hamstring stretch", muscleGroup: "Full Body", equipment: "Yoga Mat"),
            Exercise(name: "Child's Pose", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Gentle back stretch", muscleGroup: "Back", equipment: "Yoga Mat"),
            Exercise(name: "Cobra Pose", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Back strength and flexibility", muscleGroup: "Back", equipment: "Yoga Mat"),
            Exercise(name: "Seated Forward Fold", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 30, instructions: "Hamstring flexibility", muscleGroup: "Legs", equipment: "Yoga Mat"),
            Exercise(name: "Corpse Pose", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Final relaxation", muscleGroup: "Full Body", equipment: "Yoga Mat")
        ]
        
        return WorkoutPlan(
            title: "Yoga Flow",
            description: "Mindful movement combining strength, flexibility, and breath",
            exercises: exercises,
            duration: duration,
            difficulty: intensity,
            equipment: ["Yoga Mat"],
            targetMuscleGroups: ["Full Body", "Flexibility"]
        )
    }
    
    private func createPilatesWorkout(preferences: WorkoutPreferences) -> WorkoutPlan {
        let duration = getDuration(preferences.duration)
        let intensity = getIntensity(preferences.intensity)
        
        let exercises = [
            Exercise(name: "Hundred", sets: 1, reps: 1, weight: nil, duration: 100, restTime: 30, instructions: "Core activation and breathing", muscleGroup: "Core", equipment: "Pilates Mat"),
            Exercise(name: "Roll Up", sets: 3, reps: 8, weight: nil, duration: nil, restTime: 30, instructions: "Spinal articulation", muscleGroup: "Core", equipment: "Pilates Mat"),
            Exercise(name: "Single Leg Stretch", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 30, instructions: "Core control", muscleGroup: "Core", equipment: "Pilates Mat"),
            Exercise(name: "Double Leg Stretch", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 30, instructions: "Advanced core work", muscleGroup: "Core", equipment: "Pilates Mat"),
            Exercise(name: "Scissors", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 30, instructions: "Leg and core coordination", muscleGroup: "Core", equipment: "Pilates Mat"),
            Exercise(name: "Teaser", sets: 3, reps: 5, weight: nil, duration: nil, restTime: 45, instructions: "Advanced balance and control", muscleGroup: "Core", equipment: "Pilates Mat"),
            Exercise(name: "Swan Dive", sets: 3, reps: 8, weight: nil, duration: nil, restTime: 30, instructions: "Back extension", muscleGroup: "Back", equipment: "Pilates Mat"),
            Exercise(name: "Side Kick Series", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 30, instructions: "Lateral movement", muscleGroup: "Core", equipment: "Pilates Mat")
        ]
        
        return WorkoutPlan(
            title: "Pilates Power",
            description: "Core-focused movement system for strength and control",
            exercises: exercises,
            duration: duration,
            difficulty: intensity,
            equipment: ["Pilates Mat"],
            targetMuscleGroups: ["Core", "Full Body"]
        )
    }
    
    private func createCrossfitWorkout(preferences: WorkoutPreferences) -> WorkoutPlan {
        let duration = getDuration(preferences.duration)
        let intensity = getIntensity(preferences.intensity)
        
        let exercises = [
            Exercise(name: "Air Squats", sets: 3, reps: 15, weight: nil, duration: nil, restTime: 30, instructions: "Functional leg movement", muscleGroup: "Legs", equipment: "None"),
            Exercise(name: "Push-ups", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 30, instructions: "Bodyweight chest exercise", muscleGroup: "Chest", equipment: "None"),
            Exercise(name: "Pull-ups", sets: 3, reps: 8, weight: nil, duration: nil, restTime: 60, instructions: "Upper body pull", muscleGroup: "Back", equipment: "Pull-up Bar"),
            Exercise(name: "Burpees", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 45, instructions: "Full-body conditioning", muscleGroup: "Full Body", equipment: "None"),
            Exercise(name: "Box Jumps", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 45, instructions: "Explosive leg power", muscleGroup: "Legs", equipment: "Box"),
            Exercise(name: "Wall Balls", sets: 3, reps: 15, weight: nil, duration: nil, restTime: 45, instructions: "Functional fitness", muscleGroup: "Full Body", equipment: "Medicine Ball"),
            Exercise(name: "Kettlebell Swings", sets: 3, reps: 15, weight: nil, duration: nil, restTime: 45, instructions: "Hip hinge movement", muscleGroup: "Legs", equipment: "Kettlebell"),
            Exercise(name: "Thrusters", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 60, instructions: "Compound movement", muscleGroup: "Full Body", equipment: "Barbell")
        ]
        
        return WorkoutPlan(
            title: "CrossFit WOD",
            description: "Functional fitness workout of the day",
            exercises: exercises,
            duration: duration,
            difficulty: intensity,
            equipment: ["Pull-up Bar", "Kettlebell", "Box"],
            targetMuscleGroups: ["Full Body", "Functional"]
        )
    }
    
    private func createCalisthenicsWorkout(preferences: WorkoutPreferences) -> WorkoutPlan {
        let duration = getDuration(preferences.duration)
        let intensity = getIntensity(preferences.intensity)
        
        let exercises = [
            Exercise(name: "Pull-ups", sets: 4, reps: 8, weight: nil, duration: nil, restTime: 90, instructions: "Upper body pull strength", muscleGroup: "Back", equipment: "Pull-up Bar"),
            Exercise(name: "Push-ups", sets: 4, reps: 15, weight: nil, duration: nil, restTime: 60, instructions: "Upper body push strength", muscleGroup: "Chest", equipment: "None"),
            Exercise(name: "Dips", sets: 4, reps: 12, weight: nil, duration: nil, restTime: 90, instructions: "Tricep and chest strength", muscleGroup: "Arms", equipment: "Parallel Bars"),
            Exercise(name: "Pistol Squats", sets: 3, reps: 6, weight: nil, duration: nil, restTime: 90, instructions: "Advanced leg strength", muscleGroup: "Legs", equipment: "None"),
            Exercise(name: "Handstand Hold", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 60, instructions: "Shoulder stability", muscleGroup: "Shoulders", equipment: "None"),
            Exercise(name: "L-Sit", sets: 3, reps: 1, weight: nil, duration: 20, restTime: 60, instructions: "Core and shoulder strength", muscleGroup: "Core", equipment: "Parallel Bars"),
            Exercise(name: "Muscle-ups", sets: 3, reps: 4, weight: nil, duration: nil, restTime: 120, instructions: "Advanced compound movement", muscleGroup: "Full Body", equipment: "Pull-up Bar"),
            Exercise(name: "Planche Progressions", sets: 3, reps: 1, weight: nil, duration: 15, restTime: 90, instructions: "Advanced skill work", muscleGroup: "Shoulders", equipment: "None")
        ]
        
        return WorkoutPlan(
            title: "Calisthenics Master",
            description: "Bodyweight strength and skill training",
            exercises: exercises,
            duration: duration,
            difficulty: intensity,
            equipment: ["Pull-up Bar", "Parallel Bars"],
            targetMuscleGroups: ["Full Body", "Strength"]
        )
    }
    
    private func createFullBodyWorkout(preferences: WorkoutPreferences) -> WorkoutPlan {
        let duration = getDuration(preferences.duration)
        let intensity = getIntensity(preferences.intensity)
        
        var exercises: [Exercise] = []
        var equipment: [String] = []
        
        if preferences.hasDumbbells {
            exercises = [
                Exercise(name: "Dumbbell Squats", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 60, instructions: "Leg strength", muscleGroup: "Legs", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Rows", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 60, instructions: "Back strength", muscleGroup: "Back", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Press", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 60, instructions: "Shoulder strength", muscleGroup: "Shoulders", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Deadlifts", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 90, instructions: "Hip hinge movement", muscleGroup: "Back", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Lunges", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 60, instructions: "Unilateral leg work", muscleGroup: "Legs", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Curls", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 45, instructions: "Bicep isolation", muscleGroup: "Arms", equipment: "Dumbbells"),
                Exercise(name: "Planks", sets: 3, reps: 1, weight: nil, duration: 45, restTime: 45, instructions: "Core stability", muscleGroup: "Core", equipment: "None")
            ]
            equipment.append("Dumbbells")
        } else {
            exercises = [
                Exercise(name: "Bodyweight Squats", sets: 3, reps: 15, weight: nil, duration: nil, restTime: 60, instructions: "Leg strength", muscleGroup: "Legs", equipment: "None"),
                Exercise(name: "Push-ups", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 60, instructions: "Chest and triceps", muscleGroup: "Chest", equipment: "None"),
                Exercise(name: "Pull-ups", sets: 3, reps: 8, weight: nil, duration: nil, restTime: 90, instructions: "Back and biceps", muscleGroup: "Back", equipment: "Pull-up Bar"),
                Exercise(name: "Lunges", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 60, instructions: "Unilateral leg work", muscleGroup: "Legs", equipment: "None"),
                Exercise(name: "Dips", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 60, instructions: "Tricep strength", muscleGroup: "Arms", equipment: "Parallel Bars"),
                Exercise(name: "Burpees", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 60, instructions: "Full-body cardio", muscleGroup: "Full Body", equipment: "None"),
                Exercise(name: "Planks", sets: 3, reps: 1, weight: nil, duration: 45, restTime: 45, instructions: "Core stability", muscleGroup: "Core", equipment: "None")
            ]
            equipment.append("Pull-up Bar")
        }
        
        return WorkoutPlan(
            title: "Full Body Blast",
            description: "Complete body workout targeting all major muscle groups",
            exercises: exercises,
            duration: duration,
            difficulty: intensity,
            equipment: equipment,
            targetMuscleGroups: ["Full Body"]
        )
    }
    
    private func getDuration(_ duration: Duration) -> Int {
        switch duration {
        case .short: return 20
        case .medium: return 45
        case .long: return 75
        }
    }
    
    private func getIntensity(_ intensity: Intensity) -> String {
        switch intensity {
        case .low: return "Beginner"
        case .medium: return "Intermediate"
        case .high: return "Advanced"
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
    
    func clearConversation() {
        messages = [
            ChatMessage(
                content: "Hey! I'm your FitBuddy coach. I can help you with workout plans, answer fitness questions, and keep track of your progress. What would you like to work on today?",
                isFromUser: false,
                timestamp: Date()
            )
        ]
    }
    
    private func handleProfileUpdate(_ userMessage: String) -> String {
        // Use the ProfileManager's updateProfile method which can parse the message
        profileManager?.updateProfile(userMessage)
        
        let lowercased = userMessage.lowercased()
        
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
    
    private func generateNutritionAdvice(_ userMessage: String) -> String {
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
    
    private func provideEmotionalSupport(_ userMessage: String) -> String {
        let lowercased = userMessage.lowercased()
        
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
            • Maybe we need to adjust your approach?
            
            **Remember:** Fitness is a journey, not a destination. It's okay to:
            • Take breaks when you need them
            • Adjust your goals to be more realistic
            • Start small and build gradually
            • Celebrate every small step forward
            
            **Small Wins Count:**
            • Standing up and stretching
            • Taking a short walk
            • Drinking water
            • Getting enough sleep
            
            Would you like to talk about what's challenging you, or should we create a much simpler, more achievable plan?
            """
        }
        
        // Default emotional support response
        return """
        💝 **I'm here for you, and I want you to know that your feelings matter.**
        
        Sometimes the hardest part of fitness isn't the physical work - it's dealing with our emotions, stress, and mental health. You're not alone in this.
        
        **What I can help with:**
        • Creating gentle, mood-boosting workouts
        • Suggesting stress-relief exercises
        • Adjusting plans to fit your current energy and mood
        • Supporting you through difficult times
        
        **Remember:** Your mental health is just as important as your physical health. It's okay to prioritize feeling better emotionally.
        
        What would be most helpful for you right now? We can take this at your own pace.
        """
    }
    
    private func provideMotivation(_ userMessage: String) -> String {
        let lowercased = userMessage.lowercased()
        
        if lowercased.contains("lazy") || lowercased.contains("no motivation") {
            return """
            💪 **Hey, let's reframe this!**
            
            What you're calling "lazy" might actually be:
            • Your body asking for rest
            • Burnout from pushing too hard
            • Needing a different approach
            • Simply having an off day (which is totally normal!)
            
            **Instead of "lazy," let's think:**
            • "I'm conserving energy"
            • "I'm listening to my body"
            • "I'm taking care of myself"
            
            **Motivation Tips:**
            • Start with just 5 minutes - you can always do more
            • Put on your favorite upbeat music
            • Change into workout clothes (even if you don't feel like it)
            • Remember why you started this journey
            
            **Remember:** Motivation follows action, not the other way around. The hardest part is often just starting.
            
            Want to try a super short, fun workout that might get you moving?
            """
        }
        
        if lowercased.contains("tired") || lowercased.contains("don't feel like") {
            return """
            🌟 **I get it - sometimes we just don't feel like it.**
            
            But here's the thing: you don't have to feel motivated to take action. And often, once you start moving, you'll feel better.
            
            **Try this approach:**
            • Tell yourself you'll just do 5 minutes
            • Start with something you actually enjoy
            • Focus on how you'll feel AFTER the workout
            • Remember past workouts where you felt great afterward
            
            **Low-Energy Options:**
            • Gentle yoga or stretching
            • Walking while listening to a podcast
            • Dancing to your favorite songs
            • Simple bodyweight exercises
            
            **Remember:** Every workout you do, no matter how small, is a win. You're building consistency, and that's what matters most.
            
            Should we create a really enjoyable, low-effort workout that might help you get started?
            """
        }
        
        if lowercased.contains("hard") || lowercased.contains("difficult") {
            return """
            🎯 **You're right - fitness can be challenging, but that's also what makes it rewarding!**
            
            **Let's make it easier:**
            • Break it down into smaller, manageable steps
            • Start with what feels comfortable
            • Celebrate every small victory
            • Remember that progress takes time
            
            **Remember:** The most successful people in fitness aren't the ones who never struggle - they're the ones who keep going even when it's hard.
            
            **You're stronger than you think.** Every time you show up, even when it's difficult, you're building mental toughness along with physical strength.
            
            Would you like me to create a more manageable workout plan that builds gradually?
            """
        }
        
        // Default motivation response
        return """
        🚀 **Let's find your "why" and get you moving!**
        
        **Quick Motivation Boost:**
        • Think about how you want to feel in 1 month, 6 months, 1 year
        • Remember that every expert was once a beginner
        • Focus on progress, not perfection
        • Celebrate small wins every day
        
        **Remember:** You don't have to be great to start, but you have to start to be great.
        
        **What would help you most right now?**
        • A super simple, 10-minute workout
        • A fun, dance-based routine
        • A gentle, stress-relief session
        • Just talking about your goals
        
        Let's find what works for YOU!
        """
    }
    
    private func provideStressRelief(_ userMessage: String) -> String {
        let lowercased = userMessage.lowercased()
        
        if lowercased.contains("stress") || lowercased.contains("overwhelmed") {
            return """
            🧘‍♀️ **Stress is your body's way of saying "I need attention."**
            
            Let's give your body and mind what they need:
            
            **Immediate Stress Relief:**
            • **Deep Breathing**: 5 minutes of slow, deep breaths
            • **Progressive Relaxation**: Tense and release each muscle group
            • **Mindful Walking**: Focus on each step and your surroundings
            
            **Exercise for Stress:**
            • **Yoga**: Gentle poses that release tension
            • **Walking**: Especially in nature if possible
            • **Swimming**: The water can be very calming
            • **Tai Chi**: Slow, flowing movements
            
            **Remember:** Exercise is one of the most effective stress relievers because it:
            • Reduces stress hormones
            • Releases endorphins (natural mood boosters)
            • Helps you sleep better
            • Gives you a mental break
            
            Would you like me to create a stress-relief workout specifically designed to help you feel calmer?
            """
        }
        
        if lowercased.contains("anxiety") || lowercased.contains("worried") || lowercased.contains("nervous") {
            return """
            🌸 **Anxiety can feel overwhelming, but movement can be a powerful tool to help manage it.**
            
            **Calming Exercises for Anxiety:**
            • **Gentle Yoga**: Focus on slow, controlled movements
            • **Walking**: Especially in nature or with a friend
            • **Swimming**: The rhythmic movement can be very soothing
            • **Dancing**: To music you love (even just swaying)
            
            **Breathing Techniques:**
            • **4-7-8 Breathing**: Inhale 4, hold 7, exhale 8
            • **Box Breathing**: 4 counts in, 4 hold, 4 out, 4 hold
            • **Belly Breathing**: Focus on expanding your belly, not your chest
            
            **Remember:** When you're anxious, your body is in "fight or flight" mode. Exercise helps your body return to a calmer state.
            
            Would you like a gentle, anxiety-reducing workout that focuses on calming movements and breathing?
            """
        }
        
        // Default stress relief response
        return """
        🌿 **Taking care of your mental health is just as important as physical health.**
        
        **Stress Relief Through Movement:**
        • **Gentle Exercise**: Releases tension and stress hormones
        • **Mindful Movement**: Focus on the present moment
        • **Nature Walks**: Being outside can be very calming
        • **Stretching**: Releases physical tension that builds up from stress
        
        **Remember:** You don't have to do intense workouts to benefit from exercise. Even gentle movement can significantly reduce stress and improve your mood.
        
        Would you like me to create a calming, stress-relief focused workout?
        """
    }
    
    private func provideRecoveryAdvice(_ userMessage: String) -> String {
        let lowercased = userMessage.lowercased()
        
        if lowercased.contains("sleep") || lowercased.contains("rest") {
            return """
            😴 **Sleep and rest are crucial for your fitness progress!**
            
            **Sleep Tips for Better Recovery:**
            • **Consistent Schedule**: Go to bed and wake up at the same time
            • **Cool, Dark Room**: 65-68°F is ideal for sleep
            • **No Screens**: Avoid phones/computers 1 hour before bed
            • **Relaxing Routine**: Reading, gentle stretching, or meditation
            
            **Exercise and Sleep:**
            • Regular exercise improves sleep quality
            • Avoid intense workouts 3 hours before bedtime
            • Gentle evening yoga can help you relax
            • Morning exercise can help regulate your sleep cycle
            
            **Remember:** Your body does most of its repair work while you sleep. Good sleep is essential for muscle growth, recovery, and overall health.
            
            Would you like me to create a gentle, evening routine to help you sleep better?
            """
        }
        
        if lowercased.contains("recovery") || lowercased.contains("sore") {
            return """
            🛁 **Recovery is when your body gets stronger!**
            
            **Active Recovery Options:**
            • **Gentle Walking**: Increases blood flow without stress
            • **Light Stretching**: Helps reduce muscle tightness
            • **Swimming**: Low-impact, full-body movement
            • **Yoga**: Gentle poses that promote recovery
            
            **Recovery Tips:**
            • **Hydration**: Drink plenty of water
            • **Protein**: Helps repair muscle tissue
            • **Sleep**: Your body repairs while you rest
            • **Gentle Movement**: Keeps blood flowing to sore muscles
            
            **Remember:** Being sore is normal, but you shouldn't be in pain. Listen to your body and give it the rest it needs.
            
            Would you like me to create a gentle recovery workout that will help you feel better?
            """
        }
        
        // Default recovery response
        return """
        🌟 **Recovery is an essential part of your fitness journey!**
        
        **Why Recovery Matters:**
        • Prevents injury and burnout
        • Allows your body to adapt and get stronger
        • Improves performance in your next workout
        • Supports overall health and well-being
        
        **Recovery Activities:**
        • Light walking or gentle movement
        • Stretching and flexibility work
        • Adequate sleep and rest
        • Proper nutrition and hydration
        
        **Remember:** Rest days are not lazy days - they're when your body does its most important work!
        
        Would you like me to create a recovery-focused routine?
        """
    }
    
    private func isEmotionalSupport(_ message: String) -> Bool {
        let emotionalKeywords = [
            "sad", "depressed", "anxious", "stressed", "overwhelmed", "tired", "exhausted",
            "frustrated", "angry", "lonely", "hopeless", "worthless", "guilty", "ashamed",
            "afraid", "scared", "worried", "nervous", "panic", "crying", "tears",
            "don't want to", "can't do this", "give up", "quit", "failure", "failed",
            "not good enough", "hate myself", "no energy", "no motivation", "feel like"
        ]
        
        return emotionalKeywords.contains { message.contains($0) }
    }
    
    // Add a helper to generate a workout plan with explicit preferences
    private func generateWorkoutPlanWithPreferences(_ userMessage: String, _ preferences: WorkoutPreferences) -> String {
        let workoutPlan = generateWorkoutPlan(userMessage)
        
        // Store in context for future updates
        sessionContext.lastWorkoutPlan = workoutPlan
        sessionContext.currentWorkoutType = preferences.workoutType
        sessionContext.currentPreferences = preferences
        
        // Add to workout plan manager and set tracking variables
        calendarManager?.addWorkoutPlan(workoutPlan)
        lastCreatedWorkoutPlan = workoutPlan
        awaitingSchedulingResponse = true
        
        return """
        **Updated \(workoutPlan.title)** ✅
        
        I've updated your workout with all your preferences so far! Here's what's included:
        
        **Equipment Needed**: \(workoutPlan.equipment.joined(separator: ", "))
        **Target Areas**: \(workoutPlan.targetMuscleGroups.joined(separator: ", "))
        **Duration**: \(workoutPlan.duration) minutes
        **Difficulty**: \(workoutPlan.difficulty)
        **Focus**: \(workoutPlan.description)
        
        **Workout Breakdown:**
        \(formatExercises(workoutPlan.exercises))
        
        **Would you like me to schedule this workout?** Just say "yes" or tell me when you'd like to do it!
        """
    }
    

    
    private func generateAdditionalExercises(for targetAreas: [String], equipment: [String]) -> [Exercise] {
        var additionalExercises: [Exercise] = []
        
        for area in targetAreas {
            switch area.lowercased() {
            case "legs", "leg":
                additionalExercises.append(Exercise(
                    name: "Walking Lunges",
                    sets: 3,
                    reps: 10,
                    weight: nil,
                    duration: nil,
                    restTime: 45,
                    instructions: "Step forward into a lunge, alternating legs",
                    muscleGroup: "Legs",
                    equipment: "None"
                ))
                additionalExercises.append(Exercise(
                    name: "Calf Raises",
                    sets: 3,
                    reps: 20,
                    weight: nil,
                    duration: nil,
                    restTime: 30,
                    instructions: "Raise up on your toes, then lower",
                    muscleGroup: "Legs",
                    equipment: "None"
                ))
            case "arms", "arm":
                additionalExercises.append(Exercise(
                    name: "Tricep Dips",
                    sets: 3,
                    reps: 12,
                    weight: nil,
                    duration: nil,
                    restTime: 45,
                    instructions: "Use a chair or bench for support",
                    muscleGroup: "Arms",
                    equipment: "None"
                ))
                additionalExercises.append(Exercise(
                    name: "Arm Circles",
                    sets: 3,
                    reps: 1,
                    weight: nil,
                    duration: 60,
                    restTime: 30,
                    instructions: "Make circles with your arms",
                    muscleGroup: "Arms",
                    equipment: "None"
                ))
            case "core", "abs":
                additionalExercises.append(Exercise(
                    name: "Bicycle Crunches",
                    sets: 3,
                    reps: 15,
                    weight: nil,
                    duration: nil,
                    restTime: 30,
                    instructions: "Alternate bringing elbows to opposite knees",
                    muscleGroup: "Core",
                    equipment: "None"
                ))
                additionalExercises.append(Exercise(
                    name: "Russian Twists",
                    sets: 3,
                    reps: 20,
                    weight: nil,
                    duration: nil,
                    restTime: 30,
                    instructions: "Twist from side to side while seated",
                    muscleGroup: "Core",
                    equipment: "None"
                ))
            case "chest":
                additionalExercises.append(Exercise(
                    name: "Diamond Push-ups",
                    sets: 3,
                    reps: 10,
                    weight: nil,
                    duration: nil,
                    restTime: 45,
                    instructions: "Hands together under chest",
                    muscleGroup: "Chest",
                    equipment: "None"
                ))
            case "back":
                additionalExercises.append(Exercise(
                    name: "Superman Hold",
                    sets: 3,
                    reps: 1,
                    weight: nil,
                    duration: 30,
                    restTime: 30,
                    instructions: "Lift arms and legs off ground",
                    muscleGroup: "Back",
                    equipment: "None"
                ))
            default:
                break
            }
        }
        
        return additionalExercises
    }
    
    private func formatUpdatedPlanResponse(_ workout: WorkoutPlan) -> String {
        let exercisesFormatted = formatExercises(workout.exercises)
        
        return """
        **Updated Workout Plan** ✅
        
        I've modified your workout based on your request! Here's your updated plan:
        
        **🎯 \(workout.title)**
        \(workout.description)
        
        **⏱️ Duration**: \(workout.duration) minutes
        **💪 Difficulty**: \(workout.difficulty)
        **🏋️ Equipment**: \(workout.equipment.joined(separator: ", "))
        **🎯 Target Areas**: \(workout.targetMuscleGroups.joined(separator: ", "))
        
        **📋 Exercises:**
        \(exercisesFormatted)
        
        **💡 What changed:**
        • Duration adjusted to \(workout.duration) minutes
        • \(workout.exercises.count) exercises included
        • Focus on \(workout.targetMuscleGroups.joined(separator: ", "))
        
        Would you like me to make any other adjustments to this workout?
        """
    }
    
    private func getDefaultScheduleTime() -> (Date, String) {
        let calendar = Calendar.current
        let now = Date()
        
        // Default to tomorrow at 6 PM
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        return (tomorrow, "6:00 PM")
    }
    
    private func formatWorkoutPlanResponse(_ workout: WorkoutPlan) -> String {
        return """
        **\(workout.title)** 💪
        
        \(workout.description)
        
        **Workout Details:**
        ⏱️ Duration: \(workout.duration) minutes
        🎯 Target Areas: \(workout.targetMuscleGroups.joined(separator: ", "))
        🏋️ Equipment: \(workout.equipment.isEmpty ? "None" : workout.equipment.joined(separator: ", "))
        💪 Difficulty: \(workout.difficulty)
        
        **Exercises:**
        \(formatExercises(workout.exercises))
        
        **What would you like to do next?**
        • **Edit this workout** - Say "make it easier", "focus on legs", "no equipment", etc.
        • **Schedule it** - Say "yes" or "schedule it" and I'll ask when
        • **Create another** - Ask for a different type of workout
        
        Just tell me what you'd like to do!
        """
    }
    
    private func generateEmotionalSupportResponse(_ userMessage: String) -> String {
        let lowercased = userMessage.lowercased()
        
        if lowercased.contains("tired") || lowercased.contains("exhausted") || lowercased.contains("burned out") {
            return """
            **I hear you, and it's completely normal to feel tired!** 💙
            
            **Remember:** Rest is just as important as exercise. Your body needs time to recover and rebuild.
            
            **Today, consider:**
            • **Gentle movement** - A light walk or stretching session
            • **Rest day** - Sometimes the best workout is no workout
            • **Sleep focus** - Prioritize 7-9 hours of quality sleep
            • **Hydration** - Drink plenty of water
            
            **Would you like:**
            • A **gentle recovery workout** to help you feel better?
            • **Rest day guidance** with light activities?
            • **Sleep optimization tips**?
            
            Your wellbeing comes first! 🌟
            """
        }
        
        if lowercased.contains("stress") || lowercased.contains("anxiety") || lowercased.contains("overwhelmed") {
            return """
            **Stress is real, and I'm here to support you!** 🧘‍♀️
            
            **Movement can be a powerful stress reliever:**
            • **Gentle yoga** - Calms the mind and body
            • **Walking** - Clears your thoughts
            • **Deep breathing exercises** - Reduces anxiety
            • **Progressive muscle relaxation** - Releases tension
            
            **Would you like:**
            • A **stress-relief workout** with calming exercises?
            • **Breathing and meditation guidance**?
            • **Gentle movement routine** to help you unwind?
            
            Remember: It's okay to take things one step at a time. 💪
            """
        }
        
        if lowercased.contains("motivation") || lowercased.contains("lazy") || lowercased.contains("don't feel like") {
            return """
            **I get it - motivation can be tricky!** 🔥
            
            **Here's the thing:** You don't need motivation to start, you need to start to get motivation!
            
            **Try this approach:**
            • **Start small** - Just 5 minutes of movement
            • **Make it fun** - Choose activities you actually enjoy
            • **Focus on how you'll feel** - Energized, accomplished, proud
            • **Remember your why** - Why did you start this fitness journey?
            
            **Would you like:**
            • A **quick 10-minute energizer** to get you moving?
            • **Fun workout options** that feel less like work?
            • **Motivation techniques** that actually work?
            
            You've got this! Every small step counts. 🌟
            """
        }
        
        return """
        **I'm here to support your whole wellness journey!** 💙
        
        **Remember:** Fitness isn't just about physical strength - it's about mental resilience, emotional balance, and overall wellbeing.
        
        **How can I help you today?**
        • **Workout plans** that fit your energy and mood
        • **Recovery guidance** when you need rest
        • **Motivation support** when you're feeling stuck
        • **Stress relief** through movement and mindfulness
        
        You're doing great, and I'm here to support you every step of the way! 🌟
        """
    }
    
    private func generateProfileResponse(_ userMessage: String) -> String {
        return """
        **Profile Management** 👤
        
        I can help you update your fitness profile! Here's what I can track:
        
        **Personal Info:**
        • Name, age, weight, height
        • Fitness goals and preferences
        • Equipment availability
        
        **Fitness Goals:**
        • Weight loss/gain
        • Muscle building
        • Endurance improvement
        • General fitness
        
        **Preferences:**
        • Workout types (strength, cardio, yoga, etc.)
        • Target areas (legs, arms, core, etc.)
        • Equipment preferences
        • Intensity levels
        
        **To update your profile:**
        • Go to the **Profile** tab
        • Tap **Edit Profile**
        • Update your information
        
        I'll use this information to create better, more personalized workouts for you! 💪
        """
    }
    
    private func generateCalendarResponse(_ userMessage: String) -> String {
        return """
        **Calendar & Scheduling** 📅
        
        I can help you schedule your workouts! Here's how it works:
        
        **Scheduling Workouts:**
        1. **Create a workout plan** - Tell me what you want to do
        2. **Review the plan** - I'll show you the exercises and details
        3. **Schedule it** - Say "yes" or "schedule it" and I'll ask when
        4. **Choose date/time** - Pick when you want to work out
        5. **Get added to calendar** - I'll add it to your iOS Calendar
        
        **Viewing Scheduled Workouts:**
        • Go to the **Calendar** tab to see all scheduled workouts
        • Check the **Dashboard** for upcoming sessions
        • Get notifications before your workouts
        
        **Let's start by creating a workout plan!** 
        Tell me what type of workout you'd like, and I'll help you schedule it. 💪
        """
    }
    
    private func generateContextualDefaultResponse(_ userMessage: String) -> String {
        let context = persistentContext
        
        if !context.workoutHistory.isEmpty {
            let lastWorkout = context.workoutHistory.last!
            return """
            **I'm your FitBuddy coach!** 💪
            
            I remember your last workout: **\(lastWorkout.title)**
            
            **What would you like to do?**
            • **Continue with this plan** - Say "continue" or "same workout"
            • **Modify it** - Say "make it harder", "focus on legs", etc.
            • **Create something new** - Ask for a different type of workout
            • **Schedule a session** - Say "schedule it" and I'll help you book it
            
            **I can also help with:**
            • **Profile updates** - Update your fitness goals and stats
            • **Nutrition advice** - Get healthy eating tips
            • **Mental wellness** - Support for motivation and stress relief
            • **Fitness questions** - Answer exercise and health questions
            
            Just tell me what you'd like to focus on! 🌟
            """
        } else if !context.userPreferences.targetAreas.isEmpty {
            return """
            **I'm your FitBuddy coach!** 💪
            
            I remember your preferences:
            • You like to focus on: \(context.userPreferences.targetAreas.joined(separator: ", "))
            • Preferred workout type: \(context.lastWorkoutType.displayName)
            • Equipment available: \(context.userPreferences.equipmentList.joined(separator: ", "))
            
            **Let's create a workout that builds on what you enjoy!**
            Say something like "give me a workout" or "create something for me"
            
            **I can also help with:**
            • **Scheduling workouts** - Book sessions in your calendar
            • **Profile updates** - Update your fitness goals
            • **Nutrition advice** - Get healthy eating tips
            • **Mental wellness** - Support for motivation and stress relief
            
            What would you like to work on today? 🌟
            """
        } else {
            return """
            **I'm your FitBuddy coach!** 💪
            
            I'm here to help you with your fitness journey! Here's what I can do:
            
            **Workout Plans:**
            • Create personalized exercise routines
            • Build on your preferences over time
            • Adapt plans based on your feedback
            
            **Scheduling:**
            • Book workout sessions in your calendar
            • Set reminders and notifications
            • Track your fitness schedule
            
            **Profile Management:**
            • Update your fitness goals and stats
            • Remember your preferences
            • Track your progress over time
            
            **Wellness Support:**
            • Nutrition advice and tips
            • Mental wellness and motivation
            • Stress relief through movement
            
            **Let's start by understanding your preferences!**
            Tell me what type of workouts you enjoy, what areas you want to focus on, and what equipment you have. I'll remember this and create better workouts for you over time! 🌟
            """
        }
    }
    
    private func isEmotionalSupportRequest(_ message: String) -> Bool {
        let emotionalKeywords = [
            "tired", "exhausted", "burned out", "stressed", "anxiety", "overwhelmed",
            "depressed", "sad", "down", "motivation", "lazy", "don't feel like",
            "can't", "hard", "difficult", "struggling", "frustrated", "angry",
            "worried", "scared", "nervous", "tense", "pressure", "overwhelming",
            "hopeless", "helpless", "worthless", "lonely", "isolated", "alone"
        ]
        
        return emotionalKeywords.contains { message.lowercased().contains($0) }
    }
    
    // MARK: - Preference Parsing
    private func parseWorkoutPreferences(_ message: String) -> WorkoutPreferences {
        var preferences = WorkoutPreferences()
        let lowercased = message.lowercased()
        
        // Parse workout type
        if lowercased.contains("boxing") {
            preferences.workoutType = .boxing
        } else if lowercased.contains("kickboxing") {
            preferences.workoutType = .kickboxing
        } else if lowercased.contains("mma") {
            preferences.workoutType = .mma
        } else if lowercased.contains("yoga") {
            preferences.workoutType = .yoga
        } else if lowercased.contains("pilates") {
            preferences.workoutType = .pilates
        } else if lowercased.contains("crossfit") {
            preferences.workoutType = .crossfit
        } else if lowercased.contains("calisthenics") {
            preferences.workoutType = .calisthenics
        } else if lowercased.contains("strength") {
            preferences.workoutType = .strength
        } else if lowercased.contains("cardio") {
            preferences.workoutType = .cardio
        } else if lowercased.contains("hiit") {
            preferences.workoutType = .hiit
        }
        
        // Parse equipment
        if lowercased.contains("dumbbell") {
            preferences.hasDumbbells = true
        }
        if lowercased.contains("barbell") {
            preferences.hasBarbell = true
        }
        if lowercased.contains("resistance band") || lowercased.contains("band") {
            preferences.hasResistanceBands = true
        }
        if lowercased.contains("pull up bar") || lowercased.contains("pullup") {
            preferences.hasPullUpBar = true
        }
        if lowercased.contains("kettlebell") {
            preferences.hasKettlebells = true
        }
        if lowercased.contains("no equipment") || lowercased.contains("bodyweight") {
            preferences.bodyweightOnly = true
        }
        
        // Parse intensity
        if lowercased.contains("intense") || lowercased.contains("hard") || lowercased.contains("challenging") {
            preferences.intensity = .high
        } else if lowercased.contains("gentle") || lowercased.contains("easy") || lowercased.contains("light") {
            preferences.intensity = .low
        } else {
            preferences.intensity = .medium
        }
        
        // Parse duration - improved to handle specific time requests
        if lowercased.contains("1 hr") || lowercased.contains("60 min") || lowercased.contains("one hour") {
            preferences.duration = .long
        } else if lowercased.contains("45 min") || lowercased.contains("forty five") {
            preferences.duration = .medium
        } else if lowercased.contains("30 min") || lowercased.contains("half hour") || lowercased.contains("thirty") {
            preferences.duration = .short
        } else if lowercased.contains("quick") || lowercased.contains("short") || lowercased.contains("15") || lowercased.contains("20") {
            preferences.duration = .short
        } else if lowercased.contains("long") || lowercased.contains("extended") || lowercased.contains("90") {
            preferences.duration = .long
        } else {
            preferences.duration = .medium
        }
        
        // Parse specific body parts
        if lowercased.contains("leg") || lowercased.contains("quad") || lowercased.contains("glute") || lowercased.contains("calf") {
            preferences.targetAreas.append("Legs")
        }
        if lowercased.contains("arm") || lowercased.contains("bicep") || lowercased.contains("tricep") || lowercased.contains("shoulder") {
            preferences.targetAreas.append("Arms")
        }
        if lowercased.contains("chest") || lowercased.contains("pec") || lowercased.contains("push") {
            preferences.targetAreas.append("Chest")
        }
        if lowercased.contains("back") || lowercased.contains("pull") || lowercased.contains("lat") {
            preferences.targetAreas.append("Back")
        }
        if lowercased.contains("core") || lowercased.contains("abs") || lowercased.contains("stomach") {
            preferences.targetAreas.append("Core")
        }
        if lowercased.contains("full body") || lowercased.contains("total body") {
            preferences.targetAreas = ["Full Body"]
        }
        
        // Parse cardio intensity
        if lowercased.contains("high cardio") || lowercased.contains("intense cardio") || lowercased.contains("sprint") {
            preferences.cardioIntensity = .high
        } else if lowercased.contains("low cardio") || lowercased.contains("light cardio") || lowercased.contains("walk") {
            preferences.cardioIntensity = .low
        } else if lowercased.contains("cardio") {
            preferences.cardioIntensity = .medium
        }
        
        return preferences
    }
    
    private func formatExercises(_ exercises: [Exercise]) -> String {
        var formatted = ""
        for (index, exercise) in exercises.enumerated() {
            formatted += "\(index + 1). **\(exercise.name)**: \(exercise.formattedSets)\n"
        }
        return formatted
    }
    
    // MARK: - Agentic Modification System
    private func parseUserModifications(_ userMessage: String, currentPlan: WorkoutPlan) -> [WorkoutModification] {
        let lowercased = userMessage.lowercased()
        var modifications: [WorkoutModification] = []
        
        print("🤖 parseUserModifications: Analyzing message: '\(userMessage)'")
        
        // Check for ANY modification keywords first
        let modificationKeywords = [
            "change", "modify", "update", "adjust", "tweak", "edit", "alter", "switch", "replace",
            "instead", "rather", "prefer", "want", "like", "need", "make it", "can you", "could you",
            "should", "would", "please", "maybe", "how about", "what if", "try", "use", "add", "remove",
            "without", "no", "don't", "can't", "won't", "instead of", "rather than", "as opposed to"
        ]
        
        let hasModificationIntent = modificationKeywords.contains { lowercased.contains($0) }
        
        // Duration modifications
        if lowercased.contains("1 hr") || lowercased.contains("60 min") || lowercased.contains("one hour") {
            modifications.append(.setDuration(60))
        } else if lowercased.contains("45 min") || lowercased.contains("forty five") {
            modifications.append(.setDuration(45))
        } else if lowercased.contains("30 min") || lowercased.contains("half hour") || lowercased.contains("thirty") {
            modifications.append(.setDuration(30))
        } else if lowercased.contains("20 min") || lowercased.contains("twenty") {
            modifications.append(.setDuration(20))
        } else if lowercased.contains("15 min") || lowercased.contains("fifteen") {
            modifications.append(.setDuration(15))
        } else if lowercased.contains("90 min") || lowercased.contains("1.5 hr") || lowercased.contains("hour and a half") {
            modifications.append(.setDuration(90))
        }
        
        // Relative duration changes - be more aggressive
        if lowercased.contains("longer") || lowercased.contains("more time") || lowercased.contains("extend") || 
           lowercased.contains("increase") || lowercased.contains("extended") || lowercased.contains("long") {
            modifications.append(.increaseDuration)
        }
        if lowercased.contains("shorter") || lowercased.contains("less time") || lowercased.contains("reduce") || 
           lowercased.contains("decrease") || lowercased.contains("quick") || lowercased.contains("fast") {
            modifications.append(.decreaseDuration)
        }
        
        // Intensity changes - be more aggressive
        if lowercased.contains("easier") || lowercased.contains("gentle") || lowercased.contains("light") || 
           lowercased.contains("beginner") || lowercased.contains("simple") || lowercased.contains("basic") {
            modifications.append(.decreaseIntensity)
        }
        if lowercased.contains("harder") || lowercased.contains("intense") || lowercased.contains("challenging") || 
           lowercased.contains("advanced") || lowercased.contains("difficult") || lowercased.contains("tough") {
            modifications.append(.increaseIntensity)
        }
        
        // Equipment modifications - be more aggressive
        if lowercased.contains("no equipment") || lowercased.contains("bodyweight") || lowercased.contains("without equipment") ||
           lowercased.contains("don't have") || lowercased.contains("can't use") || lowercased.contains("don't want") {
            modifications.append(.removeEquipment)
        }
        if lowercased.contains("add dumbbell") || lowercased.contains("with weights") || lowercased.contains("dumbbells") ||
           lowercased.contains("weights") || lowercased.contains("equipment") {
            modifications.append(.addDumbbells)
        }
        
        // Focus area changes - be more aggressive
        if lowercased.contains("focus on leg") || lowercased.contains("only leg") || lowercased.contains("lower body") ||
           lowercased.contains("legs") || lowercased.contains("leg") || lowercased.contains("thigh") || lowercased.contains("calf") {
            modifications.append(.focusOnLegs)
        }
        if lowercased.contains("focus on arm") || lowercased.contains("only arm") || lowercased.contains("upper body") ||
           lowercased.contains("arms") || lowercased.contains("arm") || lowercased.contains("bicep") || lowercased.contains("tricep") {
            modifications.append(.focusOnArms)
        }
        if lowercased.contains("focus on core") || lowercased.contains("only core") || lowercased.contains("abs") ||
           lowercased.contains("core") || lowercased.contains("stomach") || lowercased.contains("abdominal") {
            modifications.append(.focusOnCore)
        }
        if lowercased.contains("full body") || lowercased.contains("total body") || lowercased.contains("everything") ||
           lowercased.contains("all over") || lowercased.contains("complete") {
            modifications.append(.focusOnFullBody)
        }
        
        // Exercise count changes - be more aggressive
        if lowercased.contains("more exercise") || lowercased.contains("add exercise") || lowercased.contains("longer workout") ||
           lowercased.contains("more") || lowercased.contains("additional") || lowercased.contains("extra") {
            modifications.append(.addExercises)
        }
        if lowercased.contains("fewer exercise") || lowercased.contains("less exercise") || lowercased.contains("shorter workout") ||
           lowercased.contains("fewer") || lowercased.contains("less") || lowercased.contains("reduce") {
            modifications.append(.removeExercises)
        }
        
        // Specific exercise requests
        if lowercased.contains("add cardio") || lowercased.contains("more cardio") || lowercased.contains("cardio") ||
           lowercased.contains("running") || lowercased.contains("jumping") || lowercased.contains("aerobic") {
            modifications.append(.addCardio)
        }
        if lowercased.contains("add strength") || lowercased.contains("more strength") || lowercased.contains("strength") ||
           lowercased.contains("lifting") || lowercased.contains("muscle") || lowercased.contains("power") {
            modifications.append(.addStrength)
        }
        
        // If we have modification intent but no specific modifications detected, 
        // assume they want to modify something about the current workout
        if hasModificationIntent && modifications.isEmpty {
            print("🤖 parseUserModifications: Detected modification intent but no specific changes, applying general improvements")
            // Apply some general improvements based on the current workout
            if currentPlan.duration < 45 {
                modifications.append(.increaseDuration)
            }
            if currentPlan.exercises.count < 6 {
                modifications.append(.addExercises)
            }
        }
        
        print("🤖 parseUserModifications: Detected \(modifications.count) modifications")
        return modifications
    }
    
    private func applyModificationsToPlan(_ plan: WorkoutPlan, modifications: [WorkoutModification]) -> WorkoutPlan {
        var updatedExercises = plan.exercises
        var updatedDuration = plan.duration
        var updatedEquipment = plan.equipment
        var updatedTargetAreas = plan.targetMuscleGroups
        var updatedDifficulty = plan.difficulty
        
        print("🤖 applyModificationsToPlan: Applying \(modifications.count) modifications to '\(plan.title)'")
        
        for modification in modifications {
            switch modification {
            case .setDuration(let minutes):
                print("🤖 Setting duration to \(minutes) minutes")
                updatedDuration = minutes
                
            case .increaseDuration:
                print("🤖 Increasing duration")
                updatedDuration = min(120, updatedDuration + 15)
                
            case .decreaseDuration:
                print("🤖 Decreasing duration")
                updatedDuration = max(15, updatedDuration - 15)
                
            case .increaseIntensity:
                print("🤖 Increasing intensity")
                updatedExercises = updatedExercises.map { exercise in
                    Exercise(
                        name: exercise.name,
                        sets: exercise.sets + 1,
                        reps: exercise.reps,
                        weight: exercise.weight,
                        duration: exercise.duration.map { $0 + 30 },
                        restTime: max(30, exercise.restTime - 15),
                        instructions: exercise.instructions,
                        muscleGroup: exercise.muscleGroup,
                        equipment: exercise.equipment
                    )
                }
                updatedDifficulty = "High"
                
            case .decreaseIntensity:
                print("🤖 Decreasing intensity")
                updatedExercises = updatedExercises.map { exercise in
                    Exercise(
                        name: exercise.name,
                        sets: max(1, exercise.sets - 1),
                        reps: exercise.reps,
                        weight: exercise.weight,
                        duration: exercise.duration.map { max(30, $0 - 30) },
                        restTime: min(120, exercise.restTime + 30),
                        instructions: exercise.instructions,
                        muscleGroup: exercise.muscleGroup,
                        equipment: exercise.equipment
                    )
                }
                updatedDifficulty = "Low"
                
            case .removeEquipment:
                print("🤖 Removing equipment")
                updatedExercises = updatedExercises.compactMap { exercise in
                    if let equipment = exercise.equipment, equipment != "None" {
                        return getBodyweightAlternative(for: exercise)
                    }
                    return exercise
                }
                updatedEquipment = ["None"]
                
            case .addDumbbells:
                print("🤖 Adding dumbbells")
                updatedExercises = updatedExercises.map { exercise in
                    if exercise.equipment == "None" {
                        return Exercise(
                            name: "Dumbbell \(exercise.name)",
                            sets: exercise.sets,
                            reps: exercise.reps,
                            weight: 10.0,
                            duration: exercise.duration,
                            restTime: exercise.restTime,
                            instructions: "Use dumbbells: \(exercise.instructions)",
                            muscleGroup: exercise.muscleGroup,
                            equipment: "Dumbbells"
                        )
                    }
                    return exercise
                }
                if !updatedEquipment.contains("Dumbbells") {
                    updatedEquipment.append("Dumbbells")
                }
                
            case .focusOnLegs:
                print("🤖 Focusing on legs")
                updatedExercises = updatedExercises.filter { 
                    $0.muscleGroup.contains("Leg") || $0.muscleGroup.contains("Full Body") 
                }
                updatedTargetAreas = ["Legs"]
                
            case .focusOnArms:
                print("🤖 Focusing on arms")
                updatedExercises = updatedExercises.filter { 
                    $0.muscleGroup.contains("Arm") || $0.muscleGroup.contains("Chest") || 
                    $0.muscleGroup.contains("Back") || $0.muscleGroup.contains("Full Body") 
                }
                updatedTargetAreas = ["Arms", "Chest", "Back"]
                
            case .focusOnCore:
                print("🤖 Focusing on core")
                updatedExercises = updatedExercises.filter { 
                    $0.muscleGroup.contains("Core") || $0.muscleGroup.contains("Full Body") 
                }
                updatedTargetAreas = ["Core"]
                
            case .focusOnFullBody:
                print("🤖 Focusing on full body")
                updatedTargetAreas = ["Full Body"]
                
            case .addExercises:
                print("🤖 Adding more exercises")
                let additionalExercises = generateAdditionalExercises(for: updatedTargetAreas, equipment: updatedEquipment)
                updatedExercises.append(contentsOf: additionalExercises)
                
            case .removeExercises:
                print("🤖 Removing exercises")
                updatedExercises = Array(updatedExercises.prefix(max(3, updatedExercises.count / 2)))
                
            case .addCardio:
                print("🤖 Adding cardio exercises")
                let cardioExercises = generateCardioExercises(equipment: updatedEquipment)
                updatedExercises.append(contentsOf: cardioExercises)
                
            case .addStrength:
                print("🤖 Adding strength exercises")
                let strengthExercises = generateStrengthExercises(equipment: updatedEquipment)
                updatedExercises.append(contentsOf: strengthExercises)
            }
        }
        
        // Ensure we have at least 3 exercises
        if updatedExercises.count < 3 {
            print("🤖 Not enough exercises after modifications, using original")
            return plan
        }
        
        let updatedPlan = WorkoutPlan(
            title: "Updated \(plan.title)",
            description: "Modified version based on your feedback",
            exercises: updatedExercises,
            duration: updatedDuration,
            difficulty: updatedDifficulty,
            equipment: updatedEquipment,
            targetMuscleGroups: updatedTargetAreas
        )
        
        print("🤖 Successfully updated workout with \(updatedExercises.count) exercises and \(updatedDuration) minutes duration")
        return updatedPlan
    }
    
    private func generateCardioExercises(equipment: [String]) -> [Exercise] {
        var cardioExercises: [Exercise] = []
        
        if equipment.contains("None") || equipment.isEmpty {
            cardioExercises.append(Exercise(
                name: "Jumping Jacks",
                sets: 3,
                reps: 20,
                weight: nil,
                duration: 60,
                restTime: 30,
                instructions: "Jump while raising arms and legs",
                muscleGroup: "Cardio",
                equipment: "None"
            ))
            cardioExercises.append(Exercise(
                name: "High Knees",
                sets: 3,
                reps: 30,
                weight: nil,
                duration: 45,
                restTime: 30,
                instructions: "Run in place, bringing knees to chest",
                muscleGroup: "Cardio",
                equipment: "None"
            ))
            cardioExercises.append(Exercise(
                name: "Mountain Climbers",
                sets: 3,
                reps: 20,
                weight: nil,
                duration: 45,
                restTime: 30,
                instructions: "Alternate bringing knees to chest in plank position",
                muscleGroup: "Cardio",
                equipment: "None"
            ))
        }
        
        return cardioExercises
    }
    
    private func generateStrengthExercises(equipment: [String]) -> [Exercise] {
        var strengthExercises: [Exercise] = []
        
        if equipment.contains("Dumbbells") {
            strengthExercises.append(Exercise(
                name: "Dumbbell Squats",
                sets: 3,
                reps: 12,
                weight: 15.0,
                duration: nil,
                restTime: 60,
                instructions: "Hold dumbbells at shoulders, squat down and up",
                muscleGroup: "Legs",
                equipment: "Dumbbells"
            ))
            strengthExercises.append(Exercise(
                name: "Dumbbell Rows",
                sets: 3,
                reps: 10,
                weight: 12.0,
                duration: nil,
                restTime: 60,
                instructions: "Bend forward, pull dumbbells to chest",
                muscleGroup: "Back",
                equipment: "Dumbbells"
            ))
        } else {
            strengthExercises.append(Exercise(
                name: "Push-ups",
                sets: 3,
                reps: 10,
                weight: nil,
                duration: nil,
                restTime: 60,
                instructions: "Lower body to ground and push back up",
                muscleGroup: "Chest",
                equipment: "None"
            ))
            strengthExercises.append(Exercise(
                name: "Pull-ups",
                sets: 3,
                reps: 5,
                weight: nil,
                duration: nil,
                restTime: 90,
                instructions: "Pull body up to bar",
                muscleGroup: "Back",
                equipment: "Pull-up Bar"
            ))
        }
        
        return strengthExercises
    }
}

// MARK: - Workout Preferences
struct WorkoutPreferences: Codable {
    var workoutType: WorkoutType = .none
    var hasDumbbells = false
    var hasBarbell = false
    var hasResistanceBands = false
    var hasPullUpBar = false
    var hasKettlebells = false
    var bodyweightOnly = false
    var intensity: Intensity = .medium
    var duration: Duration = .medium
    var targetAreas: [String] = []
    var cardioIntensity: CardioIntensity = .medium
    var isSore: Bool = false
    var injuries: [String] = []
    var energyLevel: EnergyLevel = .medium
    
    var equipmentList: [String] {
        var equipment: [String] = []
        if hasDumbbells { equipment.append("Dumbbells") }
        if hasBarbell { equipment.append("Barbell") }
        if hasResistanceBands { equipment.append("Resistance Bands") }
        if hasPullUpBar { equipment.append("Pull-up Bar") }
        if hasKettlebells { equipment.append("Kettlebells") }
        return equipment
    }
    
    mutating func merge(with new: WorkoutPreferences) {
        // Only update if new value is set or true
        if new.workoutType != .none { self.workoutType = new.workoutType }
        if new.hasDumbbells { self.hasDumbbells = true }
        if new.hasBarbell { self.hasBarbell = true }
        if new.hasResistanceBands { self.hasResistanceBands = true }
        if new.hasPullUpBar { self.hasPullUpBar = true }
        if new.hasKettlebells { self.hasKettlebells = true }
        if new.bodyweightOnly { self.bodyweightOnly = true }
        if new.intensity != .medium { self.intensity = new.intensity }
        if new.duration != .medium { self.duration = new.duration }
        if !new.targetAreas.isEmpty { self.targetAreas.append(contentsOf: new.targetAreas.filter { !self.targetAreas.contains($0) }) }
        if new.cardioIntensity != .medium { self.cardioIntensity = new.cardioIntensity }
        if new.isSore { self.isSore = true }
        if !new.injuries.isEmpty { self.injuries.append(contentsOf: new.injuries.filter { !self.injuries.contains($0) }) }
        if new.energyLevel != .medium { self.energyLevel = new.energyLevel }
    }
}

enum WorkoutType: String, CaseIterable, Codable {
    case boxing, kickboxing, mma, yoga, pilates, crossfit, calisthenics, strength, cardio, hiit, none
    
    var displayName: String {
        switch self {
        case .boxing: return "Boxing"
        case .kickboxing: return "Kickboxing"
        case .mma: return "MMA"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .crossfit: return "CrossFit"
        case .calisthenics: return "Calisthenics"
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .hiit: return "HIIT"
        case .none: return "General"
        }
    }
}

enum Intensity: String, Codable {
    case low, medium, high
}

enum Duration: String, Codable {
    case short, medium, long
}

enum CardioIntensity: String, Codable {
    case low, medium, high
}

// MARK: - Workout Modification Types
enum WorkoutModification {
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
}

// MARK: - Workout Plan Model

// MARK: - Intelligent Modification System
enum IntelligentModification {
    case changeWorkoutType
    case adaptToBodyweight
    case addWeights
    case reduceIntensity
    case increaseIntensity
    case addRecoveryExercises
    case avoidInjuredAreas
    case reduceDuration
    case increaseDuration
    case focusOnLegs
    case focusOnArms
    case focusOnCore
}

enum EnergyLevel: String, CaseIterable, Codable {
    case low = "Low Energy"
    case medium = "Medium Energy"
    case high = "High Energy"
}







