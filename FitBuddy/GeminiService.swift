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
        initializeModel()
    }
    
    private func initializeModel() {
        // Try to initialize the model with the API key
        do {
            self.model = GenerativeModel(name: "gemini-1.5-flash", apiKey: Config.geminiAPIKey)
            print("Gemini model initialized successfully")
        } catch {
            print("Failed to initialize Gemini model: \(error)")
            self.model = nil
        }
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
        
        if lowercased.contains("hello") || lowercased.contains("hi") || lowercased.contains("hey") {
            return "Hello! I'm your FitBuddy coach. I can help you with:\n\n• **Workout Plans** - Create personalized exercise routines\n• **Scheduling** - Book workout sessions in your calendar\n• **Profile Updates** - Update your fitness goals and stats\n• **Nutrition Advice** - Get healthy eating tips\n\nWhat would you like to work on today?"
        }
        
        // Default helpful response
        return "I'm here to help you with your fitness journey! I can assist with:\n\n• Creating personalized workout plans\n• Scheduling training sessions\n• Updating your fitness profile\n• Providing nutrition advice\n• Answering fitness questions\n\nJust let me know what you'd like to focus on!"
    }
    
    private func generateWorkoutPlan(_ userMessage: String) -> String {
        let lowercased = userMessage.lowercased()
        
        if lowercased.contains("strength") || lowercased.contains("muscle") {
            return """
            **Strength Training Workout Plan**
            
            Here's a great strength training routine for you:
            
            **Warm-up (5-10 minutes):**
            • Light cardio (jogging, cycling)
            • Dynamic stretches
            
            **Main Workout:**
            • **Squats**: 3 sets × 12 reps
            • **Push-ups**: 3 sets × 10-15 reps
            • **Dumbbell Rows**: 3 sets × 12 reps each arm
            • **Lunges**: 3 sets × 10 reps each leg
            • **Plank**: 3 sets × 30-60 seconds
            
            **Cool-down (5 minutes):**
            • Static stretches
            • Foam rolling
            
            **Total Time**: 45-60 minutes
            **Difficulty**: Beginner to Intermediate
            
            Would you like me to schedule this workout for you or modify it based on your equipment?
            """
        }
        
        if lowercased.contains("cardio") || lowercased.contains("running") || lowercased.contains("cycling") {
            return """
            **Cardio Workout Plan**
            
            Here's an effective cardio routine:
            
            **Warm-up (5 minutes):**
            • Light walking or cycling
            
            **Main Workout (30-45 minutes):**
            • **Interval Training**: 30 seconds sprint, 90 seconds walk (repeat 10-15 times)
            • **Steady State**: 20 minutes moderate pace
            • **Cool-down**: 5 minutes easy pace
            
            **Alternative Options:**
            • **HIIT**: 20 minutes high-intensity intervals
            • **Long Distance**: 45-60 minutes steady pace
            • **Hill Training**: 30 minutes with incline
            
            **Target Heart Rate**: 70-85% of max heart rate
            
            Would you like me to schedule this cardio session?
            """
        }
        
        if lowercased.contains("yoga") || lowercased.contains("flexibility") || lowercased.contains("stretch") {
            return """
            **Yoga & Flexibility Workout**
            
            Here's a relaxing yoga sequence:
            
            **Opening (5 minutes):**
            • Child's Pose
            • Cat-Cow Stretches
            • Sun Salutations (3 rounds)
            
            **Main Sequence (30 minutes):**
            • Downward Dog
            • Warrior I, II, III
            • Tree Pose
            • Bridge Pose
            • Cobra Pose
            • Seated Forward Bend
            
            **Closing (5 minutes):**
            • Corpse Pose (Savasana)
            • Meditation (optional)
            
            **Benefits**: Improved flexibility, stress relief, better posture
            
            Would you like me to schedule this yoga session?
            """
        }
        
        // Default workout plan
        return """
        **Full Body Workout Plan**
        
        Here's a balanced full-body routine:
        
        **Warm-up (10 minutes):**
        • Light cardio (5 minutes)
        • Dynamic stretches (5 minutes)
        
        **Strength Training (30 minutes):**
        • **Squats**: 3 sets × 15 reps
        • **Push-ups**: 3 sets × 10-15 reps
        • **Bent-over Rows**: 3 sets × 12 reps
        • **Lunges**: 3 sets × 10 reps each leg
        • **Plank**: 3 sets × 45 seconds
        
        **Cardio (15 minutes):**
        • Choose: Running, cycling, or swimming
        
        **Cool-down (5 minutes):**
        • Static stretches
        • Deep breathing
        
        **Total Time**: 60 minutes
        **Calories Burned**: ~400-600
        
        Would you like me to schedule this workout or create a more specific plan based on your goals?
        """
    }
    
    private func handleScheduling(_ userMessage: String) -> String {
        if let (date, time) = parseDateAndTime(userMessage) {
            // Schedule the workout
            scheduleWorkout?(date, time, "Workout Session")
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            
            return """
            ✅ **Workout Scheduled!**
            
            I've scheduled your workout for:
            **Date**: \(formatter.string(from: date))
            **Time**: \(time)
            
            You'll receive a reminder before your session. Would you like me to create a specific workout plan for this session?
            """
        }
        
        return """
        **Schedule a Workout**
        
        I can help you schedule a workout! When would you like to train?
        
        **Quick Options:**
        • "Schedule for tomorrow at 9 AM"
        • "Book a session on Monday at 6 PM"
        • "Schedule today at 5 PM"
        
        Just let me know the day and time, and I'll add it to your calendar!
        """
    }
    
    private func handleProfileUpdate(_ userMessage: String) -> String {
        // Update profile based on message
        updateProfile?(userMessage)
        
        return """
        ✅ **Profile Updated!**
        
        I've updated your fitness profile based on your message. Your changes have been saved.
        
        Would you like me to:
        • Review your updated profile
        • Create a workout plan based on your new goals
        • Schedule your next training session
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