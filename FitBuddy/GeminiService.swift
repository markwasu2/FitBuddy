import Foundation
import SwiftUI
import GoogleGenerativeAI

class GeminiService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false
    
    private var model: GenerativeModel?
    private var profileManager: ProfileManager?
    private var calendarManager: CalendarManager?
    private var workoutPlanManager: WorkoutPlanManager?
    
    // Track the last created workout plan for scheduling
    private var lastCreatedWorkoutPlan: WorkoutPlan?
    private var awaitingSchedulingResponse = false
    
    init() {
        // Initialize with welcome message
        let welcomeMessage = ChatMessage(
            content: "Hey! I'm your FitBuddy coach. I can help you with workout plans, answer fitness questions, and keep track of your progress. What would you like to work on today?",
            isFromUser: false,
            timestamp: Date()
        )
        
        self.messages = [welcomeMessage]
        initializeModel()
    }
    
    private func initializeModel() {
        // Initialize the model with the API key
        self.model = GenerativeModel(name: "gemini-1.5-flash", apiKey: Config.geminiAPIKey)
        print("Gemini model initialized successfully")
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
        
        // Generate response using local intelligence
        let response = await generateSmartResponse(message)
        
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
    
    private func generateSmartResponse(_ userMessage: String) async -> String {
        let lowercased = userMessage.lowercased()
        
        // Check if this is a response to a scheduling question
        if isRespondingToSchedulingQuestion(lowercased) {
            return handleSchedulingResponse(userMessage)
        }
        
        // Check for emotional/mental health concerns first
        if isEmotionalSupport(lowercased) {
            return provideEmotionalSupport(userMessage)
        }
        
        // Check if this is off-topic and redirect to fitness
        if isOffTopic(lowercased) {
            return """
            I'm your fitness coach, so I'm here to help with your workouts and health goals! 
            
            I can help you with:
            • **Workout Plans** - Create personalized exercise routines
            • **Scheduling** - Book workout sessions in your calendar  
            • **Profile Updates** - Update your fitness goals and stats
            • **Nutrition Advice** - Get healthy eating tips
            • **Mental Wellness** - Support for motivation and emotional health
            • **Fitness Questions** - Answer exercise and health questions
            
            What would you like to work on today?
            """
        }
        
        // Handle specific intents with local intelligence
        if lowercased.contains("workout") || lowercased.contains("exercise") || lowercased.contains("training") {
            return generateWorkoutPlan(userMessage)
        }
        
        if lowercased.contains("schedule") || lowercased.contains("calendar") || lowercased.contains("book") {
            return handleScheduling(userMessage)
        }
        
        if lowercased.contains("weight") || lowercased.contains("height") || lowercased.contains("age") || 
           lowercased.contains("goal") || lowercased.contains("profile") {
            return handleProfileUpdate(userMessage)
        }
        
        if lowercased.contains("nutrition") || lowercased.contains("diet") || lowercased.contains("food") {
            return generateNutritionAdvice(userMessage)
        }
        
        if lowercased.contains("motivation") || lowercased.contains("tired") || lowercased.contains("lazy") ||
           lowercased.contains("don't feel like") || lowercased.contains("can't") || lowercased.contains("hard") {
            return provideMotivation(userMessage)
        }
        
        if lowercased.contains("stress") || lowercased.contains("anxiety") || lowercased.contains("overwhelmed") ||
           lowercased.contains("depressed") || lowercased.contains("sad") || lowercased.contains("down") {
            return provideStressRelief(userMessage)
        }
        
        if lowercased.contains("sleep") || lowercased.contains("rest") || lowercased.contains("recovery") {
            return provideRecoveryAdvice(userMessage)
        }
        
        if lowercased.contains("hello") || lowercased.contains("hi") || lowercased.contains("hey") {
            return "Hello! I'm your FitBuddy coach. I can help you with:\n\n• **Workout Plans** - Create personalized exercise routines\n• **Scheduling** - Book workout sessions in your calendar\n• **Profile Updates** - Update your fitness goals and stats\n• **Nutrition Advice** - Get healthy eating tips\n• **Mental Wellness** - Support for motivation and emotional health\n\nWhat would you like to work on today?"
        }
        
        // Default helpful response for fitness-related questions
        return "I'm here to help with your fitness journey! I can assist with:\n\n• Creating personalized workout plans\n• Scheduling training sessions\n• Updating your fitness profile\n• Providing nutrition advice\n• Supporting your mental wellness and motivation\n• Answering fitness questions\n\nJust let me know what you'd like to focus on!"
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
        awaitingSchedulingResponse = false
        
        guard let workoutPlan = lastCreatedWorkoutPlan else {
            return "I don't have a workout plan to schedule. Let me create one for you first!"
        }
        
        // Use the improved parseDateAndTime function
        if let (scheduledDate, scheduledTime) = parseDateAndTime(userMessage) {
            // Actually schedule the workout
            calendarManager?.addEvent(title: workoutPlan.title, date: scheduledDate, time: scheduledTime)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: scheduledDate)
            
            return """
            ✅ **Workout Scheduled Successfully!**
            
            **\(workoutPlan.title)** has been added to your calendar for **\(dateString) at \(scheduledTime)**.
            
            You'll receive a reminder before your workout. The session will take approximately **\(workoutPlan.duration) minutes**.
            
            You can view your scheduled workouts in the Calendar tab or on your dashboard. Would you like me to create another workout plan or help you with anything else?
            """
        }
        
        // Fallback for simple responses like "yes"
        let lowercased = userMessage.lowercased()
        var scheduledDate = Date()
        var scheduledTime = "9:00 AM"
        
        // Determine the date
        if lowercased.contains("tomorrow") {
            scheduledDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        } else if lowercased.contains("today") {
            scheduledDate = Date()
        } else if lowercased.contains("next week") {
            scheduledDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        }
        
        // Determine the time
        if lowercased.contains("morning") || lowercased.contains("am") {
            scheduledTime = "9:00 AM"
        } else if lowercased.contains("afternoon") || lowercased.contains("pm") {
            scheduledTime = "2:00 PM"
        } else if lowercased.contains("evening") || lowercased.contains("night") {
            scheduledTime = "6:00 PM"
        }
        
        // Actually schedule the workout
        calendarManager?.addEvent(title: workoutPlan.title, date: scheduledDate, time: scheduledTime)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: scheduledDate)
        
        return """
        ✅ **Workout Scheduled Successfully!**
        
        **\(workoutPlan.title)** has been added to your calendar for **\(dateString) at \(scheduledTime)**.
        
        You'll receive a reminder before your workout. The session will take approximately **\(workoutPlan.duration) minutes**.
        
        You can view your scheduled workouts in the Calendar tab or on your dashboard. Would you like me to create another workout plan or help you with anything else?
        """
    }
    
    private func generateWorkoutPlan(_ userMessage: String) -> String {
        let lowercased = userMessage.lowercased()
        
        // Parse user preferences from the message
        let hasDumbbells = lowercased.contains("dumbbell") || lowercased.contains("weights") || lowercased.contains("gym")
        let hasResistanceBands = lowercased.contains("band") || lowercased.contains("resistance")
        let hasPullUpBar = lowercased.contains("pull") || lowercased.contains("bar") || lowercased.contains("chin")
        let isBodyweightOnly = lowercased.contains("bodyweight") || lowercased.contains("no equipment") || lowercased.contains("home")
        
        // Determine target body parts
        let targetLegs = lowercased.contains("leg") || lowercased.contains("quad") || lowercased.contains("glute") || lowercased.contains("calf")
        let targetArms = lowercased.contains("arm") || lowercased.contains("bicep") || lowercased.contains("tricep") || lowercased.contains("shoulder")
        let targetChest = lowercased.contains("chest") || lowercased.contains("pec") || lowercased.contains("push")
        let targetBack = lowercased.contains("back") || lowercased.contains("pull") || lowercased.contains("lat")
        let targetCore = lowercased.contains("core") || lowercased.contains("abs") || lowercased.contains("stomach")
        let targetCardio = lowercased.contains("cardio") || lowercased.contains("running") || lowercased.contains("cycling")
        
        // Determine workout type
        let isStrength = lowercased.contains("strength") || lowercased.contains("muscle") || lowercased.contains("build")
        let isCardio = lowercased.contains("cardio") || lowercased.contains("endurance") || lowercased.contains("burn")
        let isFlexibility = lowercased.contains("yoga") || lowercased.contains("flexibility") || lowercased.contains("stretch")
        let isHIIT = lowercased.contains("hiit") || lowercased.contains("interval") || lowercased.contains("intense")
        
        // Create personalized workout plan
        var workoutPlan: WorkoutPlan
        
        if isFlexibility {
            workoutPlan = createYogaPlan()
        } else if isCardio {
            workoutPlan = createCardioPlan(hasEquipment: hasDumbbells || hasResistanceBands)
        } else if isHIIT {
            workoutPlan = createHIITPlan(hasEquipment: hasDumbbells)
        } else if targetLegs {
            workoutPlan = createLegsPlan(hasDumbbells: hasDumbbells, isBodyweightOnly: isBodyweightOnly)
        } else if targetArms {
            workoutPlan = createArmsPlan(hasDumbbells: hasDumbbells, hasPullUpBar: hasPullUpBar, isBodyweightOnly: isBodyweightOnly)
        } else if targetChest {
            workoutPlan = createChestPlan(hasDumbbells: hasDumbbells, isBodyweightOnly: isBodyweightOnly)
        } else if targetBack {
            workoutPlan = createBackPlan(hasDumbbells: hasDumbbells, hasPullUpBar: hasPullUpBar, isBodyweightOnly: isBodyweightOnly)
        } else if targetCore {
            workoutPlan = createCorePlan(hasDumbbells: hasDumbbells, isBodyweightOnly: isBodyweightOnly)
        } else {
            // Default to full body workout
            workoutPlan = createFullBodyPlan(hasDumbbells: hasDumbbells, isBodyweightOnly: isBodyweightOnly)
        }
        
        // Add to workout plan manager and set tracking variables
        calendarManager?.addWorkoutPlan(workoutPlan)
        lastCreatedWorkoutPlan = workoutPlan
        awaitingSchedulingResponse = true
        
        return """
        **\(workoutPlan.title)** ✅
        
        I've created a personalized workout plan based on your preferences! Here's what's included:
        
        **Equipment Needed**: \(workoutPlan.equipment.joined(separator: ", "))
        **Target Areas**: \(workoutPlan.targetMuscleGroups.joined(separator: ", "))
        **Duration**: \(workoutPlan.duration) minutes
        **Difficulty**: \(workoutPlan.difficulty)
        
        **Workout Breakdown:**
        \(formatExercises(workoutPlan.exercises))
        
        **Would you like me to schedule this workout?** Just say "yes" or tell me when you'd like to do it (today, tomorrow, Monday at 6 PM, etc.)!
        """
    }
    
    private func formatExercises(_ exercises: [Exercise]) -> String {
        var formatted = ""
        for (index, exercise) in exercises.enumerated() {
            formatted += "\(index + 1). **\(exercise.name)**: \(exercise.formattedSets)\n"
        }
        return formatted
    }
    
    // MARK: - Workout Plan Creators
    
    private func createYogaPlan() -> WorkoutPlan {
        return WorkoutPlan(
            title: "Yoga & Flexibility",
            description: "Improve flexibility, reduce stress, and enhance mindfulness",
            exercises: [
                Exercise(name: "Child's Pose", sets: 1, reps: 1, weight: nil, duration: 60, restTime: 0, instructions: "Kneel and stretch arms forward", muscleGroup: "Back", equipment: "Yoga Mat"),
                Exercise(name: "Cat-Cow Stretches", sets: 1, reps: 10, weight: nil, duration: nil, restTime: 0, instructions: "Alternate between cat and cow poses", muscleGroup: "Back", equipment: "Yoga Mat"),
                Exercise(name: "Sun Salutations", sets: 3, reps: 1, weight: nil, duration: 120, restTime: 30, instructions: "Complete sun salutation sequence", muscleGroup: "Full Body", equipment: "Yoga Mat"),
                Exercise(name: "Downward Dog", sets: 1, reps: 1, weight: nil, duration: 60, restTime: 0, instructions: "Form inverted V shape with body", muscleGroup: "Shoulders", equipment: "Yoga Mat"),
                Exercise(name: "Warrior Poses", sets: 1, reps: 3, weight: nil, duration: 30, restTime: 15, instructions: "Hold each warrior pose", muscleGroup: "Legs", equipment: "Yoga Mat"),
                Exercise(name: "Tree Pose", sets: 1, reps: 1, weight: nil, duration: 60, restTime: 0, instructions: "Balance on one leg", muscleGroup: "Legs", equipment: "Yoga Mat"),
                Exercise(name: "Bridge Pose", sets: 1, reps: 1, weight: nil, duration: 45, restTime: 0, instructions: "Lift hips off ground", muscleGroup: "Back", equipment: "Yoga Mat"),
                Exercise(name: "Corpse Pose", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Relax completely on back", muscleGroup: "Full Body", equipment: "Yoga Mat")
            ],
            duration: 40,
            difficulty: "Beginner",
            equipment: ["Yoga Mat"],
            targetMuscleGroups: ["Full Body", "Flexibility"]
        )
    }
    
    private func createCardioPlan(hasEquipment: Bool) -> WorkoutPlan {
        let exercises: [Exercise]
        let equipment: [String]
        
        if hasEquipment {
            exercises = [
                Exercise(name: "Warm-up Walk", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light walking to warm up", muscleGroup: "Cardio", equipment: "None"),
                Exercise(name: "Jump Rope", sets: 3, reps: 1, weight: nil, duration: 300, restTime: 60, instructions: "Jump rope for 5 minutes", muscleGroup: "Cardio", equipment: "Jump Rope"),
                Exercise(name: "Burpees", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 90, instructions: "Full burpee with push-up", muscleGroup: "Cardio", equipment: "Bodyweight"),
                Exercise(name: "Mountain Climbers", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 60, instructions: "Alternate knees to chest", muscleGroup: "Cardio", equipment: "Bodyweight"),
                Exercise(name: "Cool-down Walk", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "5 minutes easy pace", muscleGroup: "Cardio", equipment: "None")
            ]
            equipment = ["Jump Rope", "Bodyweight"]
        } else {
            exercises = [
                Exercise(name: "Warm-up Walk", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light walking to warm up", muscleGroup: "Cardio", equipment: "None"),
                Exercise(name: "Interval Training", sets: 10, reps: 1, weight: nil, duration: 30, restTime: 90, instructions: "30 seconds sprint, 90 seconds walk", muscleGroup: "Cardio", equipment: "None"),
                Exercise(name: "Steady State", sets: 1, reps: 1, weight: nil, duration: 1200, restTime: 0, instructions: "20 minutes moderate pace", muscleGroup: "Cardio", equipment: "None"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "5 minutes easy pace", muscleGroup: "Cardio", equipment: "None")
            ]
            equipment = ["None"]
        }
        
        return WorkoutPlan(
            title: "Cardio Training",
            description: "Improve cardiovascular fitness and burn calories",
            exercises: exercises,
            duration: 30,
            difficulty: "Beginner",
            equipment: equipment,
            targetMuscleGroups: ["Cardio"]
        )
    }
    
    private func createHIITPlan(hasEquipment: Bool) -> WorkoutPlan {
        let exercises: [Exercise]
        let equipment: [String]
        
        if hasEquipment {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and dynamic stretches", muscleGroup: "Full Body", equipment: "None"),
                Exercise(name: "Burpees", sets: 4, reps: 8, weight: nil, duration: nil, restTime: 30, instructions: "Full burpee with push-up", muscleGroup: "Full Body", equipment: "Bodyweight"),
                Exercise(name: "Dumbbell Thrusters", sets: 4, reps: 10, weight: nil, duration: nil, restTime: 30, instructions: "Squat with overhead press", muscleGroup: "Full Body", equipment: "Dumbbells"),
                Exercise(name: "Mountain Climbers", sets: 4, reps: 1, weight: nil, duration: 45, restTime: 30, instructions: "Alternate knees to chest", muscleGroup: "Core", equipment: "Bodyweight"),
                Exercise(name: "Jump Squats", sets: 4, reps: 12, weight: nil, duration: nil, restTime: 30, instructions: "Squat with jump at top", muscleGroup: "Legs", equipment: "Bodyweight"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Full Body", equipment: "None")
            ]
            equipment = ["Dumbbells", "Bodyweight"]
        } else {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and dynamic stretches", muscleGroup: "Full Body", equipment: "None"),
                Exercise(name: "Burpees", sets: 4, reps: 10, weight: nil, duration: nil, restTime: 30, instructions: "Full burpee with push-up", muscleGroup: "Full Body", equipment: "Bodyweight"),
                Exercise(name: "Jump Squats", sets: 4, reps: 15, weight: nil, duration: nil, restTime: 30, instructions: "Squat with jump at top", muscleGroup: "Legs", equipment: "Bodyweight"),
                Exercise(name: "Push-ups", sets: 4, reps: 12, weight: nil, duration: nil, restTime: 30, instructions: "Standard push-ups", muscleGroup: "Chest", equipment: "Bodyweight"),
                Exercise(name: "Mountain Climbers", sets: 4, reps: 1, weight: nil, duration: 45, restTime: 30, instructions: "Alternate knees to chest", muscleGroup: "Core", equipment: "Bodyweight"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Full Body", equipment: "None")
            ]
            equipment = ["Bodyweight"]
        }
        
        return WorkoutPlan(
            title: "HIIT Training",
            description: "High-intensity interval training for maximum calorie burn",
            exercises: exercises,
            duration: 25,
            difficulty: "Advanced",
            equipment: equipment,
            targetMuscleGroups: ["Full Body", "Cardio"]
        )
    }
    
    private func createLegsPlan(hasDumbbells: Bool, isBodyweightOnly: Bool) -> WorkoutPlan {
        let exercises: [Exercise]
        let equipment: [String]
        
        if hasDumbbells && !isBodyweightOnly {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and dynamic stretches", muscleGroup: "Legs", equipment: "None"),
                Exercise(name: "Dumbbell Squats", sets: 4, reps: 12, weight: nil, duration: nil, restTime: 90, instructions: "Hold dumbbells at sides, squat down", muscleGroup: "Legs", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Lunges", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 90, instructions: "Step forward with dumbbells", muscleGroup: "Legs", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Deadlifts", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 90, instructions: "Hinge at hips, keep back straight", muscleGroup: "Legs", equipment: "Dumbbells"),
                Exercise(name: "Calf Raises", sets: 3, reps: 20, weight: nil, duration: nil, restTime: 60, instructions: "Stand on toes, lower heels", muscleGroup: "Legs", equipment: "Dumbbells"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Legs", equipment: "None")
            ]
            equipment = ["Dumbbells"]
        } else {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and dynamic stretches", muscleGroup: "Legs", equipment: "None"),
                Exercise(name: "Bodyweight Squats", sets: 4, reps: 15, weight: nil, duration: nil, restTime: 90, instructions: "Standard bodyweight squats", muscleGroup: "Legs", equipment: "Bodyweight"),
                Exercise(name: "Walking Lunges", sets: 3, reps: 20, weight: nil, duration: nil, restTime: 90, instructions: "Step forward, alternate legs", muscleGroup: "Legs", equipment: "Bodyweight"),
                Exercise(name: "Glute Bridges", sets: 3, reps: 15, weight: nil, duration: nil, restTime: 60, instructions: "Lie on back, lift hips", muscleGroup: "Legs", equipment: "Bodyweight"),
                Exercise(name: "Calf Raises", sets: 3, reps: 25, weight: nil, duration: nil, restTime: 60, instructions: "Stand on toes, lower heels", muscleGroup: "Legs", equipment: "Bodyweight"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Legs", equipment: "None")
            ]
            equipment = ["Bodyweight"]
        }
        
        return WorkoutPlan(
            title: "Legs & Glutes",
            description: "Build strong legs and glutes",
            exercises: exercises,
            duration: 45,
            difficulty: "Intermediate",
            equipment: equipment,
            targetMuscleGroups: ["Legs", "Glutes"]
        )
    }
    
    private func createArmsPlan(hasDumbbells: Bool, hasPullUpBar: Bool, isBodyweightOnly: Bool) -> WorkoutPlan {
        let exercises: [Exercise]
        let equipment: [String]
        
        if hasDumbbells && !isBodyweightOnly {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and arm circles", muscleGroup: "Arms", equipment: "None"),
                Exercise(name: "Dumbbell Bicep Curls", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 60, instructions: "Curl dumbbells to shoulders", muscleGroup: "Arms", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Tricep Extensions", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 60, instructions: "Extend arms overhead", muscleGroup: "Arms", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Shoulder Press", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 90, instructions: "Press dumbbells overhead", muscleGroup: "Arms", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Lateral Raises", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 60, instructions: "Raise arms to sides", muscleGroup: "Arms", equipment: "Dumbbells"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Arms", equipment: "None")
            ]
            equipment = ["Dumbbells"]
        } else if hasPullUpBar {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and arm circles", muscleGroup: "Arms", equipment: "None"),
                Exercise(name: "Pull-ups", sets: 3, reps: 8, weight: nil, duration: nil, restTime: 90, instructions: "Pull body up to bar", muscleGroup: "Arms", equipment: "Pull-up Bar"),
                Exercise(name: "Push-ups", sets: 3, reps: 15, weight: nil, duration: nil, restTime: 60, instructions: "Standard push-ups", muscleGroup: "Arms", equipment: "Bodyweight"),
                Exercise(name: "Dips", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 90, instructions: "Dip on parallel bars", muscleGroup: "Arms", equipment: "Pull-up Bar"),
                Exercise(name: "Pike Push-ups", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 60, instructions: "Push-ups with elevated hips", muscleGroup: "Arms", equipment: "Bodyweight"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Arms", equipment: "None")
            ]
            equipment = ["Pull-up Bar", "Bodyweight"]
        } else {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and arm circles", muscleGroup: "Arms", equipment: "None"),
                Exercise(name: "Push-ups", sets: 4, reps: 15, weight: nil, duration: nil, restTime: 60, instructions: "Standard push-ups", muscleGroup: "Arms", equipment: "Bodyweight"),
                Exercise(name: "Diamond Push-ups", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 60, instructions: "Push-ups with diamond hand position", muscleGroup: "Arms", equipment: "Bodyweight"),
                Exercise(name: "Pike Push-ups", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 60, instructions: "Push-ups with elevated hips", muscleGroup: "Arms", equipment: "Bodyweight"),
                Exercise(name: "Tricep Dips", sets: 3, reps: 15, weight: nil, duration: nil, restTime: 60, instructions: "Dips on chair or surface", muscleGroup: "Arms", equipment: "Bodyweight"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Arms", equipment: "None")
            ]
            equipment = ["Bodyweight"]
        }
        
        return WorkoutPlan(
            title: "Arms & Shoulders",
            description: "Build strong arms and shoulders",
            exercises: exercises,
            duration: 40,
            difficulty: "Intermediate",
            equipment: equipment,
            targetMuscleGroups: ["Arms", "Shoulders"]
        )
    }
    
    private func createChestPlan(hasDumbbells: Bool, isBodyweightOnly: Bool) -> WorkoutPlan {
        let exercises: [Exercise]
        let equipment: [String]
        
        if hasDumbbells && !isBodyweightOnly {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and arm circles", muscleGroup: "Chest", equipment: "None"),
                Exercise(name: "Dumbbell Bench Press", sets: 4, reps: 12, weight: nil, duration: nil, restTime: 90, instructions: "Press dumbbells from chest", muscleGroup: "Chest", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Flyes", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 90, instructions: "Open arms like flying", muscleGroup: "Chest", equipment: "Dumbbells"),
                Exercise(name: "Push-ups", sets: 3, reps: 15, weight: nil, duration: nil, restTime: 60, instructions: "Standard push-ups", muscleGroup: "Chest", equipment: "Bodyweight"),
                Exercise(name: "Dumbbell Pullovers", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 90, instructions: "Pull dumbbell over head", muscleGroup: "Chest", equipment: "Dumbbells"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Chest", equipment: "None")
            ]
            equipment = ["Dumbbells", "Bodyweight"]
        } else {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and arm circles", muscleGroup: "Chest", equipment: "None"),
                Exercise(name: "Push-ups", sets: 4, reps: 15, weight: nil, duration: nil, restTime: 60, instructions: "Standard push-ups", muscleGroup: "Chest", equipment: "Bodyweight"),
                Exercise(name: "Wide Push-ups", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 60, instructions: "Push-ups with wide hand position", muscleGroup: "Chest", equipment: "Bodyweight"),
                Exercise(name: "Diamond Push-ups", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 60, instructions: "Push-ups with diamond hand position", muscleGroup: "Chest", equipment: "Bodyweight"),
                Exercise(name: "Decline Push-ups", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 60, instructions: "Push-ups with feet elevated", muscleGroup: "Chest", equipment: "Bodyweight"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Chest", equipment: "None")
            ]
            equipment = ["Bodyweight"]
        }
        
        return WorkoutPlan(
            title: "Chest & Triceps",
            description: "Build a strong chest and triceps",
            exercises: exercises,
            duration: 45,
            difficulty: "Intermediate",
            equipment: equipment,
            targetMuscleGroups: ["Chest", "Triceps"]
        )
    }
    
    private func createBackPlan(hasDumbbells: Bool, hasPullUpBar: Bool, isBodyweightOnly: Bool) -> WorkoutPlan {
        let exercises: [Exercise]
        let equipment: [String]
        
        if hasDumbbells && !isBodyweightOnly {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and arm circles", muscleGroup: "Back", equipment: "None"),
                Exercise(name: "Dumbbell Rows", sets: 4, reps: 12, weight: nil, duration: nil, restTime: 90, instructions: "Bend forward, pull dumbbell to hip", muscleGroup: "Back", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Deadlifts", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 90, instructions: "Hinge at hips, keep back straight", muscleGroup: "Back", equipment: "Dumbbells"),
                Exercise(name: "Dumbbell Pullovers", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 90, instructions: "Pull dumbbell over head", muscleGroup: "Back", equipment: "Dumbbells"),
                Exercise(name: "Superman Holds", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 60, instructions: "Lie face down, lift chest and legs", muscleGroup: "Back", equipment: "Bodyweight"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Back", equipment: "None")
            ]
            equipment = ["Dumbbells", "Bodyweight"]
        } else if hasPullUpBar {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and arm circles", muscleGroup: "Back", equipment: "None"),
                Exercise(name: "Pull-ups", sets: 4, reps: 8, weight: nil, duration: nil, restTime: 90, instructions: "Pull body up to bar", muscleGroup: "Back", equipment: "Pull-up Bar"),
                Exercise(name: "Chin-ups", sets: 3, reps: 8, weight: nil, duration: nil, restTime: 90, instructions: "Pull-ups with underhand grip", muscleGroup: "Back", equipment: "Pull-up Bar"),
                Exercise(name: "Superman Holds", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 60, instructions: "Lie face down, lift chest and legs", muscleGroup: "Back", equipment: "Bodyweight"),
                Exercise(name: "Bird Dogs", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 60, instructions: "Alternate arm and leg raises", muscleGroup: "Back", equipment: "Bodyweight"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Back", equipment: "None")
            ]
            equipment = ["Pull-up Bar", "Bodyweight"]
        } else {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and arm circles", muscleGroup: "Back", equipment: "None"),
                Exercise(name: "Superman Holds", sets: 4, reps: 1, weight: nil, duration: 30, restTime: 60, instructions: "Lie face down, lift chest and legs", muscleGroup: "Back", equipment: "Bodyweight"),
                Exercise(name: "Bird Dogs", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 60, instructions: "Alternate arm and leg raises", muscleGroup: "Back", equipment: "Bodyweight"),
                Exercise(name: "Cat-Cow Stretches", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 30, instructions: "Alternate between cat and cow poses", muscleGroup: "Back", equipment: "Bodyweight"),
                Exercise(name: "Child's Pose", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 30, instructions: "Kneel and stretch arms forward", muscleGroup: "Back", equipment: "Bodyweight"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Back", equipment: "None")
            ]
            equipment = ["Bodyweight"]
        }
        
        return WorkoutPlan(
            title: "Back & Biceps",
            description: "Build a strong back and biceps",
            exercises: exercises,
            duration: 45,
            difficulty: "Intermediate",
            equipment: equipment,
            targetMuscleGroups: ["Back", "Biceps"]
        )
    }
    
    private func createCorePlan(hasDumbbells: Bool, isBodyweightOnly: Bool) -> WorkoutPlan {
        let exercises: [Exercise]
        let equipment: [String]
        
        if hasDumbbells && !isBodyweightOnly {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and dynamic stretches", muscleGroup: "Core", equipment: "None"),
                Exercise(name: "Dumbbell Russian Twists", sets: 3, reps: 20, weight: nil, duration: nil, restTime: 60, instructions: "Sit with knees bent, twist with dumbbell", muscleGroup: "Core", equipment: "Dumbbells"),
                Exercise(name: "Plank", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 60, instructions: "Hold plank position", muscleGroup: "Core", equipment: "Bodyweight"),
                Exercise(name: "Dumbbell Side Bends", sets: 3, reps: 15, weight: nil, duration: nil, restTime: 60, instructions: "Stand with dumbbell, bend to side", muscleGroup: "Core", equipment: "Dumbbells"),
                Exercise(name: "Bicycle Crunches", sets: 3, reps: 20, weight: nil, duration: nil, restTime: 60, instructions: "Alternate elbow to knee", muscleGroup: "Core", equipment: "Bodyweight"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Core", equipment: "None")
            ]
            equipment = ["Dumbbells", "Bodyweight"]
        } else {
            exercises = [
                Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and dynamic stretches", muscleGroup: "Core", equipment: "None"),
                Exercise(name: "Plank", sets: 3, reps: 1, weight: nil, duration: 60, restTime: 60, instructions: "Hold plank position", muscleGroup: "Core", equipment: "Bodyweight"),
                Exercise(name: "Bicycle Crunches", sets: 3, reps: 20, weight: nil, duration: nil, restTime: 60, instructions: "Alternate elbow to knee", muscleGroup: "Core", equipment: "Bodyweight"),
                Exercise(name: "Russian Twists", sets: 3, reps: 20, weight: nil, duration: nil, restTime: 60, instructions: "Sit with knees bent, twist side to side", muscleGroup: "Core", equipment: "Bodyweight"),
                Exercise(name: "Leg Raises", sets: 3, reps: 15, weight: nil, duration: nil, restTime: 60, instructions: "Lie on back, raise legs straight up", muscleGroup: "Core", equipment: "Bodyweight"),
                Exercise(name: "Mountain Climbers", sets: 3, reps: 1, weight: nil, duration: 45, restTime: 60, instructions: "Alternate knees to chest", muscleGroup: "Core", equipment: "Bodyweight"),
                Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches", muscleGroup: "Core", equipment: "None")
            ]
            equipment = ["Bodyweight"]
        }
        
        return WorkoutPlan(
            title: "Core & Abs",
            description: "Build a strong core and abs",
            exercises: exercises,
            duration: 35,
            difficulty: "Beginner",
            equipment: equipment,
            targetMuscleGroups: ["Core", "Abs"]
        )
    }
    
    private func createFullBodyPlan(hasDumbbells: Bool, isBodyweightOnly: Bool) -> WorkoutPlan {
        let exercises: [Exercise]
        let equipment: [String]
        
        if hasDumbbells && !isBodyweightOnly {
            exercises = [
                Exercise(name: "Warm-up Cardio", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio for 5 minutes", muscleGroup: "Cardio", equipment: "None"),
                Exercise(name: "Dynamic Stretches", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Dynamic stretching for 5 minutes", muscleGroup: "Full Body", equipment: "None"),
                Exercise(name: "Dumbbell Squats", sets: 3, reps: 15, weight: nil, duration: nil, restTime: 90, instructions: "Hold dumbbells at sides, squat down", muscleGroup: "Legs", equipment: "Dumbbells"),
                Exercise(name: "Push-ups", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 60, instructions: "Standard push-ups", muscleGroup: "Chest", equipment: "Bodyweight"),
                Exercise(name: "Dumbbell Rows", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 90, instructions: "Bend forward, pull dumbbell to hip", muscleGroup: "Back", equipment: "Dumbbells"),
                Exercise(name: "Lunges", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 60, instructions: "Step forward, alternate legs", muscleGroup: "Legs", equipment: "Bodyweight"),
                Exercise(name: "Plank", sets: 3, reps: 1, weight: nil, duration: 45, restTime: 60, instructions: "Hold plank position", muscleGroup: "Core", equipment: "Bodyweight"),
                Exercise(name: "Cardio Session", sets: 1, reps: 1, weight: nil, duration: 900, restTime: 0, instructions: "15 minutes of cardio", muscleGroup: "Cardio", equipment: "None"),
                Exercise(name: "Cool-down Stretches", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches and deep breathing", muscleGroup: "Full Body", equipment: "None")
            ]
            equipment = ["Dumbbells", "Bodyweight"]
        } else {
            exercises = [
                Exercise(name: "Warm-up Cardio", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio for 5 minutes", muscleGroup: "Cardio", equipment: "None"),
                Exercise(name: "Dynamic Stretches", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Dynamic stretching for 5 minutes", muscleGroup: "Full Body", equipment: "None"),
                Exercise(name: "Squats", sets: 3, reps: 15, weight: nil, duration: nil, restTime: 90, instructions: "Standard bodyweight squats", muscleGroup: "Legs", equipment: "Bodyweight"),
                Exercise(name: "Push-ups", sets: 3, reps: 12, weight: nil, duration: nil, restTime: 60, instructions: "Standard push-ups", muscleGroup: "Chest", equipment: "Bodyweight"),
                Exercise(name: "Superman Holds", sets: 3, reps: 1, weight: nil, duration: 30, restTime: 60, instructions: "Lie face down, lift chest and legs", muscleGroup: "Back", equipment: "Bodyweight"),
                Exercise(name: "Lunges", sets: 3, reps: 10, weight: nil, duration: nil, restTime: 60, instructions: "Step forward, alternate legs", muscleGroup: "Legs", equipment: "Bodyweight"),
                Exercise(name: "Plank", sets: 3, reps: 1, weight: nil, duration: 45, restTime: 60, instructions: "Hold plank position", muscleGroup: "Core", equipment: "Bodyweight"),
                Exercise(name: "Cardio Session", sets: 1, reps: 1, weight: nil, duration: 900, restTime: 0, instructions: "15 minutes of cardio", muscleGroup: "Cardio", equipment: "None"),
                Exercise(name: "Cool-down Stretches", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Static stretches and deep breathing", muscleGroup: "Full Body", equipment: "None")
            ]
            equipment = ["Bodyweight"]
        }
        
        return WorkoutPlan(
            title: "Full Body Workout",
            description: "Balanced full-body routine for overall fitness",
            exercises: exercises,
            duration: 60,
            difficulty: "Intermediate",
            equipment: equipment,
            targetMuscleGroups: ["Full Body", "Cardio"]
        )
    }
    
    private func parseDateAndTime(_ text: String) -> (Date, String)? {
        let lowercased = text.lowercased()
        
        // Parse common date patterns
        var targetDate = Date()
        var timeString = "9:00 AM"
        
        // Check for specific date patterns first
        if let specificDate = parseSpecificDate(lowercased) {
            targetDate = specificDate
        } else if lowercased.contains("tomorrow") {
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        } else if lowercased.contains("today") {
            targetDate = Date()
        } else if lowercased.contains("next week") {
            targetDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
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
        
        // Parse time with more flexibility
        if let parsedTime = parseTimeString(lowercased) {
            timeString = parsedTime
        }
        
        return (targetDate, timeString)
    }
    
    private func parseSpecificDate(_ text: String) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        
        // Check for "in X days"
        if let daysMatch = text.range(of: "in (\\d+) days?", options: .regularExpression) {
            let daysString = String(text[daysMatch]).replacingOccurrences(of: "in ", with: "").replacingOccurrences(of: " days", with: "").replacingOccurrences(of: " day", with: "")
            if let days = Int(daysString) {
                return calendar.date(byAdding: .day, value: days, to: today)
            }
        }
        
        // Check for "next [day]"
        if text.contains("next ") {
            if text.contains("monday") || text.contains("mon") {
                return getNextWeekday(2)
            } else if text.contains("tuesday") || text.contains("tue") {
                return getNextWeekday(3)
            } else if text.contains("wednesday") || text.contains("wed") {
                return getNextWeekday(4)
            } else if text.contains("thursday") || text.contains("thu") {
                return getNextWeekday(5)
            } else if text.contains("friday") || text.contains("fri") {
                return getNextWeekday(6)
            } else if text.contains("saturday") || text.contains("sat") {
                return getNextWeekday(7)
            } else if text.contains("sunday") || text.contains("sun") {
                return getNextWeekday(1)
            }
        }
        
        // Check for specific month and day patterns
        let monthPatterns = [
            "january": 1, "jan": 1,
            "february": 2, "feb": 2,
            "march": 3, "mar": 3,
            "april": 4, "apr": 4,
            "may": 5,
            "june": 6, "jun": 6,
            "july": 7, "jul": 7,
            "august": 8, "aug": 8,
            "september": 9, "sep": 9, "sept": 9,
            "october": 10, "oct": 10,
            "november": 11, "nov": 11,
            "december": 12, "dec": 12
        ]
        
        for (monthName, monthNumber) in monthPatterns {
            if text.contains(monthName) {
                // Extract day number
                if let dayMatch = text.range(of: "(\\d{1,2})(st|nd|rd|th)?", options: .regularExpression) {
                    let dayString = String(text[dayMatch]).replacingOccurrences(of: "st", with: "").replacingOccurrences(of: "nd", with: "").replacingOccurrences(of: "rd", with: "").replacingOccurrences(of: "th", with: "")
                    if let day = Int(dayString) {
                        var components = calendar.dateComponents([.year], from: today)
                        components.month = monthNumber
                        components.day = day
                        
                        if let date = calendar.date(from: components) {
                            // If the date is in the past, assume next year
                            if date < today {
                                components.year = (components.year ?? 2024) + 1
                                return calendar.date(from: components)
                            }
                            return date
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func parseTimeString(_ text: String) -> String? {
        // Parse specific times like "6:30 PM", "14:30", etc.
        let timePatterns = [
            "6am": "6:00 AM", "6 am": "6:00 AM", "6:00am": "6:00 AM", "6:00 am": "6:00 AM",
            "7am": "7:00 AM", "7 am": "7:00 AM", "7:00am": "7:00 AM", "7:00 am": "7:00 AM",
            "8am": "8:00 AM", "8 am": "8:00 AM", "8:00am": "8:00 AM", "8:00 am": "8:00 AM",
            "9am": "9:00 AM", "9 am": "9:00 AM", "9:00am": "9:00 AM", "9:00 am": "9:00 AM",
            "10am": "10:00 AM", "10 am": "10:00 AM", "10:00am": "10:00 AM", "10:00 am": "10:00 AM",
            "11am": "11:00 AM", "11 am": "11:00 AM", "11:00am": "11:00 AM", "11:00 am": "11:00 AM",
            "12pm": "12:00 PM", "12 pm": "12:00 PM", "12:00pm": "12:00 PM", "12:00 pm": "12:00 PM", "noon": "12:00 PM",
            "1pm": "1:00 PM", "1 pm": "1:00 PM", "1:00pm": "1:00 PM", "1:00 pm": "1:00 PM",
            "2pm": "2:00 PM", "2 pm": "2:00 PM", "2:00pm": "2:00 PM", "2:00 pm": "2:00 PM",
            "3pm": "3:00 PM", "3 pm": "3:00 PM", "3:00pm": "3:00 PM", "3:00 pm": "3:00 PM",
            "4pm": "4:00 PM", "4 pm": "4:00 PM", "4:00pm": "4:00 PM", "4:00 pm": "4:00 PM",
            "5pm": "5:00 PM", "5 pm": "5:00 PM", "5:00pm": "5:00 PM", "5:00 pm": "5:00 PM",
            "6pm": "6:00 PM", "6 pm": "6:00 PM", "6:00pm": "6:00 PM", "6:00 pm": "6:00 PM",
            "7pm": "7:00 PM", "7 pm": "7:00 PM", "7:00pm": "7:00 PM", "7:00 pm": "7:00 PM",
            "8pm": "8:00 PM", "8 pm": "8:00 PM", "8:00pm": "8:00 PM", "8:00 pm": "8:00 PM",
            "9pm": "9:00 PM", "9 pm": "9:00 PM", "9:00pm": "9:00 PM", "9:00 pm": "9:00 PM",
            "10pm": "10:00 PM", "10 pm": "10:00 PM", "10:00pm": "10:00 PM", "10:00 pm": "10:00 PM"
        ]
        
        for (pattern, time) in timePatterns {
            if text.contains(pattern) {
                return time
            }
        }
        
        // Parse time periods
        if text.contains("morning") || text.contains("am") {
            return "9:00 AM"
        } else if text.contains("afternoon") || text.contains("pm") {
            return "2:00 PM"
        } else if text.contains("evening") || text.contains("night") {
            return "6:00 PM"
        }
        
        return nil
    }
    
    private func getNextWeekday(_ weekday: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        
        let daysToAdd = (weekday - todayWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
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
    
    private func handleScheduling(_ userMessage: String) -> String {
        let lowercased = userMessage.lowercased()
        
        // If user is asking to schedule a specific workout, use the last created plan
        if let workoutPlan = lastCreatedWorkoutPlan {
            if let (date, time) = parseDateAndTime(userMessage) {
                // Actually schedule the workout
                calendarManager?.addEvent(title: workoutPlan.title, date: date, time: time)
                
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                let dateString = formatter.string(from: date)
                
                return """
                ✅ **Workout Scheduled Successfully!**
                
                **\(workoutPlan.title)** has been added to your calendar for **\(dateString) at \(time)**.
                
                You'll receive a reminder before your workout. The session will take approximately **\(workoutPlan.duration) minutes**.
                
                You can view your scheduled workouts in the Calendar tab or on your dashboard. Would you like me to create another workout plan or help you with anything else?
                """
            }
        }
        
        // If user is asking to schedule a general workout
        if let (date, time) = parseDateAndTime(userMessage) {
            // Create a default workout and schedule it
            let defaultWorkout = WorkoutPlan(
                title: "Fitness Session",
                description: "General fitness workout",
                exercises: [
                    Exercise(name: "Warm-up", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Light cardio and stretching", muscleGroup: "Full Body", equipment: "None"),
                    Exercise(name: "Full Body Circuit", sets: 3, reps: 1, weight: nil, duration: 1200, restTime: 60, instructions: "Complete body workout", muscleGroup: "Full Body", equipment: "Bodyweight"),
                    Exercise(name: "Cool-down", sets: 1, reps: 1, weight: nil, duration: 300, restTime: 0, instructions: "Stretching and relaxation", muscleGroup: "Full Body", equipment: "None")
                ],
                duration: 30,
                difficulty: "Beginner",
                equipment: ["Bodyweight"],
                targetMuscleGroups: ["Full Body"]
            )
            
            calendarManager?.addWorkoutPlan(defaultWorkout)
            calendarManager?.addEvent(title: defaultWorkout.title, date: date, time: time)
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let dateString = formatter.string(from: date)
            
            return """
            ✅ **Workout Scheduled Successfully!**
            
            I've scheduled a **\(defaultWorkout.title)** for **\(dateString) at \(time)**.
            
            This will be a 30-minute full body workout that you can do anywhere. You'll receive a reminder before your session.
            
            Would you like me to create a more specific workout plan for this session?
            """
        }
        
        // If no specific date/time provided, ask for more details
        return """
        **Schedule a Workout**
        
        I can help you schedule a workout! When would you like to train?
        
        **Quick Options:**
        • "Schedule for tomorrow at 9 AM"
        • "Book a session on Monday at 6 PM"
        • "Schedule today at 5 PM"
        • "Tomorrow morning"
        • "Next week Tuesday at 7 PM"
        
        Just let me know the day and time, and I'll add it to your calendar!
        """
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
        
        if lowercased.contains("tired") || lowercased.contains("exhausted") || lowercased.contains("no energy") {
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
} 