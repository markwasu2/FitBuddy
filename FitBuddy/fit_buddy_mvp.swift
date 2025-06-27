//  FitBuddyMVP.swift
//  Drop this single file into a new Xcode > iOS App (SwiftUI) project.
//  It compiles without external dependencies and demonstrates:
//    • Onboarding input for goal/equipment
//    • TabView navigation (Home, Chatbot, Scanner)
//    • GPT-like chatbot stub that schedules an EventKit workout
//    • Photos‑based calorie scan stub using a hard‑coded lookup table
//  Replace stubs with real API calls + CoreML model when ready.

import SwiftUI
import EventKit
import PhotosUI
import Vision
import CoreML
import GoogleGenerativeAI
import Speech
import AVFoundation
import HealthKit
import Foundation

// MARK: - App Entry Point
@main
struct FitBuddyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var gptService = GPTService()
    @StateObject private var activityTracker = ActivityTracker()
    @StateObject private var chatMemoryManager = ChatMemoryManager()
    @StateObject private var workoutSessionManager = WorkoutSessionManager()
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(profileManager)
                .environmentObject(gptService)
                .environmentObject(activityTracker)
                .environmentObject(chatMemoryManager)
                .environmentObject(workoutSessionManager)
                .environmentObject(healthKitManager)
                .onAppear {
                    // Connect services
                    profileManager.setGPTService(gptService)
                    workoutSessionManager.setActivityTracker(activityTracker)
                    chatMemoryManager.setActivityTracker(activityTracker)
                }
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}

// MARK: - Root Navigation
struct RootView: View {
    @EnvironmentObject var profileManager: ProfileManager
    
    var body: some View {
        if profileManager.isOnboardingComplete {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static let cardBackground = Color(.systemBackground)
    static let errorRed = Color.red
    static let successGreen = Color.green
    static let accentBlue = Color.blue
    static let secondaryText = Color(.secondaryLabel)
}

// MARK: - Basic Models
struct WorkoutPlan: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let exercises: [Exercise]
    let duration: Int // minutes
    let difficulty: String
    let equipment: [String]
    let targetMuscleGroups: [String]
    
    var formattedDuration: String {
        return "\(duration) min"
    }
}

struct Exercise: Codable, Identifiable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: Int
    let weight: Double?
    let duration: Int? // seconds
    let restTime: Int // seconds
    let instructions: String
    let muscleGroup: String
    let equipment: String?
    
    var formattedSets: String {
        if let duration = duration {
            return "\(sets) sets × \(duration)s"
        } else {
            return "\(sets) sets × \(reps) reps"
        }
    }
    
    var formattedRest: String {
        return "\(restTime)s rest"
    }
}

struct ScheduledWorkout: Codable, Identifiable {
    let id = UUID()
    let workoutPlan: WorkoutPlan
    let scheduledDate: Date
    let eventID: String?
    var isCompleted: Bool = false
    var completedExercises: [String] = []
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: scheduledDate)
    }
}

// MARK: - Biometric Data Models
struct HealthKitWorkout: Codable, Identifiable {
    let id: String
    let workoutTitle: String
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let caloriesBurned: Double
    let workoutType: String
    
    var formattedDuration: String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
    
    var formattedCalories: String {
        return String(format: "%.0f cal", caloriesBurned)
    }
}

struct BiometricData: Codable {
    let date: Date
    let steps: Int
    let caloriesBurned: Double
    let activeCalories: Double
    let distance: Double // in meters
    let heartRate: Double?
    let workouts: [HealthKitWorkout]
    
    var formattedSteps: String {
        return "\(steps) steps"
    }
    
    var formattedDistance: String {
        let miles = distance * 0.000621371
        return String(format: "%.1f mi", miles)
    }
    
    var formattedCalories: String {
        return String(format: "%.0f cal", caloriesBurned)
    }
}

struct WorkoutJournalEntry: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let workoutTitle: String
    let duration: TimeInterval
    let exercises: [CompletedExercise]
    let notes: String
    let mood: String
    let energyLevel: Int // 1-10
    
    var formattedDuration: String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}

struct CompletedExercise: Codable, Identifiable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: Int
    let weight: Double?
    let duration: Int?
    let isCompleted: Bool
}

// MARK: - Activity Tracking
class ActivityTracker: ObservableObject {
    @Published var dailyProgress: [String: Double] = [:]
    @Published var weeklyProgress: [String: [Double]] = [:]
    @Published var goals: [String: Double] = [:]
    @Published var recentActivity: [ActivityItem] = []
    
    init() {
        loadData()
    }
    
    func updateProgress(for activity: String, value: Double) {
        dailyProgress[activity] = value
        saveData()
    }
    
    func addActivity(_ activity: ActivityItem) {
        recentActivity.insert(activity, at: 0)
        if recentActivity.count > 10 {
            recentActivity = Array(recentActivity.prefix(10))
        }
        saveData()
    }
    
    func setGoal(for activity: String, target: Double) {
        goals[activity] = target
        saveData()
    }
    
    private func loadData() {
        // Load from UserDefaults
    }
    
    private func saveData() {
        // Save to UserDefaults
    }
}

struct ActivityItem: Codable, Identifiable {
    let id = UUID()
    let type: String
    let value: String
    let timestamp: Date
    let impact: String
}

// MARK: - Chat Memory Manager
class ChatMemoryManager: ObservableObject {
    @Published var chatHistory: [ChatMessage] = []
    @Published var userProfile: UserProfile?
    @Published var goalProgress: [String: Double] = [:]
    
    private var activityTracker: ActivityTracker?
    
    func setActivityTracker(_ tracker: ActivityTracker) {
        self.activityTracker = tracker
    }
    
    func addMessage(_ message: ChatMessage) {
        chatHistory.append(message)
        if chatHistory.count > 100 {
            chatHistory = Array(chatHistory.suffix(100))
        }
    }
    
    func updateGoalProgress(_ goal: String, progress: Double) {
        goalProgress[goal] = progress
        activityTracker?.updateProgress(for: goal, value: progress)
    }
}

struct ChatMessage: Codable, Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let type: MessageType
    
    enum MessageType: String, Codable {
        case text, workout, progress, goal
    }
}

struct UserProfile: Codable {
    let name: String
    let age: Int
    let weight: Int
    let height: Int
    let fitnessLevel: String
    let goals: [String]
    let equipment: [String]
}

// MARK: - Onboarding
struct OnboardingView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var fitnessLevel: String = ""
    @State private var equipment: String = ""
    @State private var currentStep = 0
    
    private let totalSteps = 8
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: Double(totalSteps - 1))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding(.horizontal)
                
                // Step content
                stepContent
                
                Spacer()
                
                // Navigation buttons
                navigationButtons
            }
            .padding()
            .navigationTitle("Welcome to FitBuddy")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            welcomeStep
        case 1:
            nameStep
        case 2:
            ageStep
        case 3:
            weightStep
        case 4:
            heightStep
        case 5:
            goalsStep
        case 6:
            fitnessLevelStep
        case 7:
            equipmentStep
        default:
            EmptyView()
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to FitBuddy!")
                .font(.largeTitle)
                .bold()
            
            Text("Your AI-powered fitness companion")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Let's create your personalized fitness profile to get started with customized workout plans and expert guidance.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
    
    private var nameStep: some View {
        VStack(spacing: 20) {
            Text("What's your name?")
                .font(.title)
                .bold()
            
            TextField("Enter your name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.title2)
        }
    }
    
    private var ageStep: some View {
        VStack(spacing: 20) {
            Text("How old are you?")
                .font(.title)
                .bold()
            
            TextField("Age", text: $age)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .font(.title2)
        }
    }
    
    private var weightStep: some View {
        VStack(spacing: 20) {
            Text("What's your weight?")
                .font(.title)
                .bold()
            
            HStack {
                TextField("Weight", text: $weight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .font(.title2)
                
                Text("lbs")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var heightStep: some View {
        VStack(spacing: 20) {
            Text("What's your height?")
                .font(.title)
                .bold()
            
            HStack {
                TextField("Height", text: $height)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .font(.title2)
                
                Text("inches")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var goalsStep: some View {
        VStack(spacing: 20) {
            Text("What are your fitness goals?")
                .font(.title)
                .bold()
            
            VStack(spacing: 15) {
                GoalButton(title: "Lose Weight", isSelected: profileManager.selectedGoals.contains("Lose Weight")) {
                    toggleGoal("Lose Weight")
                }
                
                GoalButton(title: "Build Muscle", isSelected: profileManager.selectedGoals.contains("Build Muscle")) {
                    toggleGoal("Build Muscle")
                }
                
                GoalButton(title: "Improve Cardio", isSelected: profileManager.selectedGoals.contains("Improve Cardio")) {
                    toggleGoal("Improve Cardio")
                }
                
                GoalButton(title: "Increase Strength", isSelected: profileManager.selectedGoals.contains("Increase Strength")) {
                    toggleGoal("Increase Strength")
                }
                
                GoalButton(title: "Maintain Fitness", isSelected: profileManager.selectedGoals.contains("Maintain Fitness")) {
                    toggleGoal("Maintain Fitness")
                }
            }
        }
    }
    
    private var fitnessLevelStep: some View {
        VStack(spacing: 20) {
            Text("What's your fitness level?")
                .font(.title)
                .bold()
            
            VStack(spacing: 15) {
                FitnessLevelButton(title: "Beginner", description: "New to fitness or getting back into it", isSelected: fitnessLevel == "beginner") {
                    fitnessLevel = "beginner"
                }
                
                FitnessLevelButton(title: "Intermediate", description: "Regular exercise routine", isSelected: fitnessLevel == "intermediate") {
                    fitnessLevel = "intermediate"
                }
                
                FitnessLevelButton(title: "Advanced", description: "Experienced with fitness", isSelected: fitnessLevel == "advanced") {
                    fitnessLevel = "advanced"
                }
            }
        }
    }
    
    private var equipmentStep: some View {
        VStack(spacing: 20) {
            Text("What equipment do you have?")
                .font(.title)
                .bold()
            
            VStack(spacing: 15) {
                EquipmentButton(title: "None", description: "Bodyweight exercises only", isSelected: equipment == "none") {
                    equipment = "none"
                }
                
                EquipmentButton(title: "Resistance Bands", description: "Portable and versatile", isSelected: equipment == "resistance bands") {
                    equipment = "resistance bands"
                }
                
                EquipmentButton(title: "Basic Home Gym", description: "Some weights and equipment", isSelected: equipment == "basic home gym") {
                    equipment = "basic home gym"
                }
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    currentStep -= 1
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            Button(currentStep == totalSteps - 1 ? "Complete" : "Next") {
                if currentStep == totalSteps - 1 {
                    completeOnboarding()
                } else {
                    currentStep += 1
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canProceed)
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: return !age.isEmpty
        case 3: return !weight.isEmpty
        case 4: return !height.isEmpty
        case 5: return !profileManager.selectedGoals.isEmpty
        case 6: return !fitnessLevel.isEmpty
        case 7: return !equipment.isEmpty
        default: return false
        }
    }
    
    private func toggleGoal(_ goal: String) {
        if profileManager.selectedGoals.contains(goal) {
            profileManager.selectedGoals.removeAll { $0 == goal }
        } else {
            profileManager.selectedGoals.append(goal)
        }
    }
    
    private func completeOnboarding() {
        // Save all profile data
        profileManager.userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profileManager.age = Int(age) ?? 25
        profileManager.weight = Int(weight) ?? 150
        profileManager.height = Int(height) ?? 70
        profileManager.fitnessLevel = fitnessLevel
        profileManager.equipment = equipment
        
        // Mark onboarding as complete and save to UserDefaults
        profileManager.completeOnboarding()
    }
}

struct GoalButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FitnessLevelButton: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EquipmentButton: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: ‑ Tab Container
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
            ChatbotView()
                .tabItem { Label("Chat", systemImage: "message") }
            ScannerView()
                .tabItem { Label("Scan", systemImage: "camera") }
        }
    }
}

// MARK: ‑ Home
struct HomeView: View {
    @State private var streak: Int = 0
    @AppStorage("userGoal") private var goal: String = ""
    @AppStorage("userWeight") private var weight: String = ""
    @AppStorage("userHeight") private var height: String = ""
    @AppStorage("userAge") private var age: String = ""
    @AppStorage("userGender") private var gender: String = ""
    @AppStorage("userFitnessLevel") private var fitnessLevel: String = ""
    @AppStorage("userBMI") private var bmi: String = ""
    @AppStorage("userEquipment") private var equipment: String = ""
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasOnboarded = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Welcome Section
                VStack(spacing: 12) {
                    Text("Welcome back, \(userName.isEmpty ? "Fitness Buddy" : userName)! 👋")
                        .font(.title2)
                        .bold()
                    Text("Daily Streak: \(streak) 🔥")
                        .font(.headline)
                    Text("Complete a workout today to keep it alive!")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Profile Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("🏃‍♂️ Your Fitness Profile")
                        .font(.headline)
                        .bold()
                    
                    ProfileRow(title: "Name", value: userName.isEmpty ? "Not set" : userName)
                    ProfileRow(title: "Goal", value: goal.isEmpty ? "Not set" : goal)
                    ProfileRow(title: "Weight", value: weight.isEmpty ? "Not set" : "\(weight) lbs")
                    ProfileRow(title: "Height", value: height.isEmpty ? "Not set" : "\(height) inches")
                    ProfileRow(title: "Age", value: age.isEmpty ? "Not set" : "\(age) years")
                    ProfileRow(title: "Gender", value: gender.isEmpty ? "Not set" : gender.capitalized)
                    ProfileRow(title: "Fitness Level", value: fitnessLevel.isEmpty ? "Not set" : fitnessLevel.capitalized)
                    ProfileRow(title: "BMI", value: bmi.isEmpty ? "Not set" : bmi)
                    ProfileRow(title: "Equipment", value: equipment.isEmpty ? "Not set" : equipment)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Quick Actions
                VStack(spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .bold()
                    
                    Button("Ask for Workout Plan") {
                        // This would navigate to chat
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("Update Profile") {
                        hasOnboarded = false
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("Reset Onboarding") {
                        resetProfile()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
    
    private func resetProfile() {
        userName = ""
        goal = ""
        weight = ""
        height = ""
        age = ""
        gender = ""
        fitnessLevel = ""
        bmi = ""
        equipment = ""
        hasOnboarded = false
    }
}

struct ProfileRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .bold()
            Spacer()
        }
    }
}

// MARK: - Chatbot + Calendar Integration
struct ChatbotView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var input: String = ""
    @State private var messages: [ChatBubble] = []
    private let gpt = GPTService()
    private let calendar = CalendarManager()
    @StateObject private var speechManager = SpeechRecognitionManager()
    @State private var isLoading = false
    @State private var onboardingStep = 0
    @State private var isOnboarding = false
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { bubble in
                        HStack(alignment: .top) {
                            if bubble.isUser { Spacer() }
                            Text(bubble.formattedText)
                                .padding(12)
                                .foregroundColor(bubble.isUser ? .white : .primary)
                                .background(bubble.isUser ? Color.blue : Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: bubble.isUser ? .trailing : .leading)
                                .multilineTextAlignment(bubble.isUser ? .trailing : .leading)
                            if !bubble.isUser { Spacer() }
                        }
                        .padding(.horizontal)
                    }
                    if isLoading {
                        HStack {
                            Spacer()
                            VStack {
                                ProgressView()
                                Text(isOnboarding ? "Processing..." : "Creating your personalized plan...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            Spacer()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Voice transcription display
            if !speechManager.transcribedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🎤 You said:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(speechManager.transcribedText)
                        .padding(8)
                        .background(Color.yellow.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // Input area with voice button
            HStack {
                // Voice button
                Button(action: {
                    if speechManager.isRecording {
                        speechManager.stopRecording()
                        input = speechManager.transcribedText
                    } else {
                        speechManager.startRecording()
                    }
                }) {
                    Image(systemName: speechManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title2)
                        .foregroundColor(speechManager.isRecording ? .red : .blue)
                }
                .disabled(!speechManager.isAuthorized)
                
                TextField(isOnboarding ? "Type your answer..." : "Ask for a workout plan or update profile...", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isLoading)
                
                Button("Send") { send() }
                    .disabled(input.isEmpty || isLoading)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onAppear {
            if !speechManager.isAuthorized {
                speechManager.requestAuthorization()
            }
            startOnboardingIfNeeded()
        }
    }
    
    private func startOnboardingIfNeeded() {
        if !profileManager.isOnboardingComplete || profileManager.userName.isEmpty {
            isOnboarding = true
            onboardingStep = 0
            messages = []
            startOnboarding()
        } else {
            isOnboarding = false
            if messages.isEmpty {
                messages = [ChatBubble(text: "Hi \(profileManager.userName)! I'm FitBuddy! You can speak to me or type. Try saying 'Update my profile' or ask for a workout plan.", isUser: false)]
            }
        }
    }
    
    private func startOnboarding() {
        messages.append(ChatBubble(text: "Hi! I'm FitBuddy, your personal fitness assistant! 👋\n\nLet's get to know each other so I can create the perfect workout plan for you.\n\nWhat's your name?", isUser: false))
    }
    
    private func handleOnboardingResponse() {
        let userResponse = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch onboardingStep {
        case 0: // Name
            profileManager.userName = userResponse
            messages.append(ChatBubble(text: "Nice to meet you, \(profileManager.userName)! 😊\n\nHow old are you?", isUser: false))
            onboardingStep = 1
            
        case 1: // Age
            if let ageValue = Int(userResponse) {
                profileManager.age = ageValue
                messages.append(ChatBubble(text: "Great! Now, what's your weight? You can tell me in pounds (lbs) or kilograms (kg).", isUser: false))
                onboardingStep = 2
            } else {
                messages.append(ChatBubble(text: "Please enter a valid age (just the number).", isUser: false))
            }
            
        case 2: // Weight
            let lowerResponse = userResponse.lowercased()
            if lowerResponse.contains("kg") {
                // Convert kg to lbs
                if let kgValue = Double(lowerResponse.replacingOccurrences(of: "kg", with: "").trimmingCharacters(in: .whitespaces)) {
                    let lbsValue = kgValue * 2.20462
                    profileManager.weight = Int(lbsValue)
                }
            } else {
                // Assume lbs
                if let lbsValue = Double(lowerResponse.replacingOccurrences(of: "lbs", with: "").replacingOccurrences(of: "pounds", with: "").trimmingCharacters(in: .whitespaces)) {
                    profileManager.weight = Int(lbsValue)
                }
            }
            
            if profileManager.weight > 0 {
                messages.append(ChatBubble(text: "Perfect! Now, what's your height? You can tell me in inches or centimeters.", isUser: false))
                onboardingStep = 3
            } else {
                messages.append(ChatBubble(text: "Please enter a valid weight (e.g., '150 lbs' or '68 kg').", isUser: false))
            }
            
        case 3: // Height
            let lowerResponse = userResponse.lowercased()
            if lowerResponse.contains("cm") {
                // Convert cm to inches
                if let cmValue = Double(lowerResponse.replacingOccurrences(of: "cm", with: "").trimmingCharacters(in: .whitespaces)) {
                    let inchesValue = cmValue / 2.54
                    profileManager.height = Int(inchesValue)
                }
            } else {
                // Assume inches
                if let inchesValue = Double(lowerResponse.replacingOccurrences(of: "inches", with: "").replacingOccurrences(of: "in", with: "").trimmingCharacters(in: .whitespaces)) {
                    profileManager.height = Int(inchesValue)
                }
            }
            
            if profileManager.height > 0 {
                messages.append(ChatBubble(text: "Great! Now, what's your primary fitness goal?\n\nChoose one:\n• Lose weight\n• Build muscle\n• Improve cardio/endurance\n• General fitness\n• Other (tell me more)", isUser: false))
                onboardingStep = 4
            } else {
                messages.append(ChatBubble(text: "Please enter a valid height (e.g., '5 feet 10 inches' or '178 cm').", isUser: false))
            }
            
        case 4: // Goal
            let lowerResponse = userResponse.lowercased()
            if lowerResponse.contains("lose") || lowerResponse.contains("weight") {
                profileManager.goal = "lose weight"
            } else if lowerResponse.contains("build") || lowerResponse.contains("muscle") {
                profileManager.goal = "build muscle"
            } else if lowerResponse.contains("cardio") || lowerResponse.contains("endurance") {
                profileManager.goal = "improve cardio"
            } else if lowerResponse.contains("general") || lowerResponse.contains("fitness") {
                profileManager.goal = "general fitness"
            } else {
                profileManager.goal = userResponse
            }
            
            messages.append(ChatBubble(text: "Excellent! What equipment do you have available?\n\nChoose one:\n• None (bodyweight only)\n• Resistance bands\n• Basic home gym\n• Full gym access\n• Other (tell me more)", isUser: false))
            onboardingStep = 5
            
        case 5: // Equipment
            let lowerResponse = userResponse.lowercased()
            if lowerResponse.contains("none") || lowerResponse.contains("bodyweight") {
                profileManager.equipment = "none"
            } else if lowerResponse.contains("resistance") || lowerResponse.contains("bands") {
                profileManager.equipment = "resistance bands"
            } else if lowerResponse.contains("home gym") || lowerResponse.contains("basic") {
                profileManager.equipment = "basic home gym"
            } else if lowerResponse.contains("full gym") || lowerResponse.contains("gym access") {
                profileManager.equipment = "full gym"
            } else {
                profileManager.equipment = userResponse
            }
            
            messages.append(ChatBubble(text: "Perfect! Finally, what's your fitness level?\n\nChoose one:\n• Beginner (new to fitness)\n• Intermediate (regular exercise)\n• Advanced (experienced)", isUser: false))
            onboardingStep = 6
            
        case 6: // Fitness Level
            let lowerResponse = userResponse.lowercased()
            if lowerResponse.contains("beginner") {
                profileManager.fitnessLevel = "beginner"
            } else if lowerResponse.contains("intermediate") {
                profileManager.fitnessLevel = "intermediate"
            } else if lowerResponse.contains("advanced") {
                profileManager.fitnessLevel = "advanced"
            } else {
                profileManager.fitnessLevel = "beginner" // Default
            }
            
            // Calculate BMI
            profileManager.calculateBMI()
            
            // Complete onboarding
            profileManager.completeOnboarding()
            isOnboarding = false
            
            let welcomeMessage = """
            🎉 Perfect! Your profile is complete, \(profileManager.userName)!
            
            📊 Your Profile:
            • Age: \(profileManager.age) years
            • Weight: \(profileManager.weight) lbs
            • Height: \(profileManager.height) inches
            • BMI: \(profileManager.bmi)
            • Goal: \(profileManager.goal)
            • Equipment: \(profileManager.equipment)
            • Level: \(profileManager.fitnessLevel.capitalized)
            
            I'm ready to create personalized workout plans just for you! 
            
            Try asking me for a workout plan or any fitness questions. You can also say "Update my profile" anytime to change your details.
            """
            
            messages.append(ChatBubble(text: welcomeMessage, isUser: false))
            
        default:
            break
        }
    }
    
    func send() {
        guard !input.isEmpty else { return }
        let userMessage = input
        messages.append(ChatBubble(text: userMessage, isUser: true))
        input = ""
        isLoading = true
        
        if isOnboarding {
            handleOnboardingResponse()
            isLoading = false
            return
        }
        
        // Check if this is a profile update command
        let lowerMessage = userMessage.lowercased()
        if lowerMessage.contains("update") && lowerMessage.contains("profile") {
            let profileUpdate = profileManager.updateProfile(from: userMessage)
            messages.append(ChatBubble(text: profileUpdate, isUser: false))
            isLoading = false
            return
        }
        
        // Create a comprehensive fitness-focused prompt
        let contextPrompt = """
        You are FitBuddy, an expert fitness coach and personal trainer. Generate CONCISE, SPECIFIC, and ACTIONABLE responses.

        USER PROFILE:
        - Name: \(profileManager.userName)
        - Goal: \(profileManager.goal)
        - Equipment: \(profileManager.equipment)
        - Weight: \(profileManager.weight) lbs
        - Height: \(profileManager.height) inches
        - Age: \(profileManager.age) years
        - Gender: \(profileManager.gender)
        - Fitness Level: \(profileManager.fitnessLevel)
        - BMI: \(profileManager.bmi)
        - Question: \(userMessage)

        INSTRUCTIONS:
        1. Keep responses CONCISE (max 200 words for workout plans)
        2. Be SPECIFIC with sets, reps, weights, and rest periods
        3. Consider the user's equipment limitations
        4. Adapt exercises to their fitness level
        5. Account for age, gender, and BMI in recommendations
        6. If they ask about updating their profile, suggest they say "Update my profile" followed by their details
        7. Use their name \(profileManager.userName) in responses to make it personal

        WORKOUT PLAN FORMAT (if requested):
        🏋️ **PERSONALIZED WORKOUT PLAN**

        **Day 1: [Specific Focus]**
        - [Exercise]: [Sets] x [Reps] @ [Weight/Intensity] - [Rest]
        - [Exercise]: [Sets] x [Reps] @ [Weight/Intensity] - [Rest]
        - [Exercise]: [Sets] x [Reps] @ [Weight/Intensity] - [Rest]

        **Day 2: [Specific Focus]**
        - [Exercise]: [Sets] x [Reps] @ [Weight/Intensity] - [Rest]
        - [Exercise]: [Sets] x [Reps] @ [Weight/Intensity] - [Rest]
        - [Exercise]: [Sets] x [Reps] @ [Weight/Intensity] - [Rest]

        **Day 3: [Specific Focus]**
        - [Exercise]: [Sets] x [Reps] @ [Weight/Intensity] - [Rest]
        - [Exercise]: [Sets] x [Reps] @ [Weight/Intensity] - [Rest]
        - [Exercise]: [Sets] x [Reps] @ [Weight/Intensity] - [Rest]

        💡 **Personalized Tips:**
        - [Specific advice based on their profile]
        - [Nutrition tip if relevant]

        For general questions, provide specific, actionable advice in 2-3 bullet points.
        """
        
        Task {
            let reply = await gpt.generateRoutine(prompt: contextPrompt)
            await MainActor.run {
                messages.append(ChatBubble(text: reply, isUser: false))
                isLoading = false
            }
            
            // If the response suggests a workout, schedule it
            if userMessage.lowercased().contains("workout") || userMessage.lowercased().contains("plan") {
                try? calendar.addWorkout(title: "Workout", offsetMinutes: 1)
            }
        }
    }
}

struct ChatBubble: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    
    // Format the text for better display
    var formattedText: String {
        if isUser {
            return text
        } else {
            // Add line breaks for better readability
            return text.replacingOccurrences(of: "**", with: "\n**")
                      .replacingOccurrences(of: " - ", with: "\n- ")
        }
    }
}

class GPTService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let model: GenerativeModel
    
    init() {
        // Get API key from environment variable
        let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
        print("API Key length: \(apiKey.count)") // Debug: Check if API key is present
        print("API Key starts with: \(String(apiKey.prefix(10)))") // Debug: Check first 10 chars
        print("API Key ends with: \(String(apiKey.suffix(10)))") // Debug: Check last 10 chars
        
        // Clean up the API key - remove any extra whitespace or quotes
        let cleanedApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "")
        
        // TEMPORARY: Use hardcoded API key for testing
        let finalApiKey = "AIzaSyARrgAbADRJL7UU99Q0qAcKdQC18Xxf8Yc"
        
        guard !finalApiKey.isEmpty else {
            fatalError("GEMINI_API_KEY environment variable is not set")
        }
        
        guard finalApiKey.hasPrefix("AIza") else {
            fatalError("GEMINI_API_KEY does not start with 'AIza' - invalid key format")
        }
        
        print("Using API Key length: \(finalApiKey.count)")
        
        // Use gemini-1.5-flash-latest which is available in the API
        model = GenerativeModel(name: "gemini-1.5-flash-latest", apiKey: finalApiKey, generationConfig: GenerationConfig(
            temperature: 0.7,
            topP: 0.8,
            topK: 40
        ))
    }
    
    func sendMessage(_ content: String) async {
        let userMessage = ChatMessage(content: content, isUser: true, timestamp: Date(), type: .text)
        
        await MainActor.run {
            messages.append(userMessage)
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let response = try await generateResponse(for: content)
            let aiMessage = ChatMessage(content: response, isUser: false, timestamp: Date(), type: .text)
            
            await MainActor.run {
                messages.append(aiMessage)
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to get response: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func generateResponse(for message: String) async throws -> String {
        let prompt = createPrompt(for: message)
        let response = try await model.generateContent(prompt)
        return response.text ?? "I'm sorry, I couldn't generate a response."
    }
    
    private func createPrompt(for message: String) -> String {
        return """
        You are Moki, a friendly and professional AI fitness coach for FitBuddy. You help users with:
        - Creating personalized workout plans
        - Providing fitness advice and motivation
        - Tracking progress and goals
        - Scheduling workouts in their calendar
        
        Guidelines:
        - Be conversational and natural, not robotic
        - Ask at most ONE question per response
        - Make questions bold using **question text**
        - Be forgiving of typos and spelling errors
        - Focus on bodyweight exercises and simple equipment
        - Don't mention dumbbells or heavy equipment unless specifically asked
        - If user asks for fitness advice or workout plans, respond conversationally without defaulting to onboarding questions
        
        User message: \(message)
        
        Respond naturally as Moki:
        """
    }
    
    func clearMessages() {
        messages.removeAll()
    }
    
    func generateRoutine(prompt: String) async -> String {
        do {
            print("Sending prompt to Gemini API...") // Debug: Log API call
            let response = try await model.generateContent(prompt)
            print("Received response from Gemini API") // Debug: Log successful response
            if let text = response.text {
                return text
            }
            print("No text in response") // Debug: Log empty response
            return "I apologize, but I couldn't generate a response. Please try again."
        } catch {
            print("Detailed error: \(error)") // Debug: Log detailed error
            let nsError = error as NSError
            print("Error domain: \(nsError.domain)")
            print("Error code: \(nsError.code)")
            print("Error description: \(nsError.localizedDescription)")
            print("Error user info: \(nsError.userInfo)")
            
            // Return a more specific error message based on the error
            if nsError.domain == "GoogleGenerativeAI.GenerateContentError" {
                return "I apologize, but there seems to be an issue with the AI service configuration. Please try again later."
            }
            return "I apologize, but I'm having trouble connecting to the AI service. Please check your internet connection and try again."
        }
    }
}

class CalendarManager {
    private let store = EKEventStore()
    
    init() {
        requestAccess()
    }
    
    private func requestAccess() {
        // Request calendar access with proper error handling
        store.requestAccess(to: .event) { granted, error in
            if let error = error {
                print("Error requesting calendar access: \(error)")
            }
            if !granted {
                print("Calendar access not granted")
            }
        }
    }
    
    func addWorkout(title: String, offsetMinutes: Double) throws {
        // Check calendar authorization status
        let status = EKEventStore.authorizationStatus(for: .event)
        guard status == .authorized else {
            throw NSError(domain: "CalendarError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access not authorized"])
        }
        
        guard let cal = store.defaultCalendarForNewEvents else {
            throw NSError(domain: "CalendarError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No default calendar found"])
        }
        
        let event = EKEvent(eventStore: store)
        event.calendar = cal
        event.title = title
        event.startDate = Date().addingTimeInterval(offsetMinutes*60)
        event.endDate = event.startDate.addingTimeInterval(60*60)
        try store.save(event, span: .thisEvent)
    }
}

// MARK: ‑ Calorie Scanner (PhotosPicker + dummy Vision)
struct ScannerView: View {
    @State private var selection: PhotosPickerItem?
    @State private var calorieText: String = "Snap a meal photo to estimate calories."
    private let classifier = FoodClassifier()
    var body: some View {
        VStack(spacing: 20) {
            Text(calorieText).multilineTextAlignment(.center)
            PhotosPicker(selection: $selection, matching: .images) {
                Label("Take Photo", systemImage: "camera")
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .onChange(of: selection) { _ in classify() }
    }
    func classify() {
        guard let item = selection else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                let label = classifier.predict(image: img)
                calorieText = "Detected \(label.name). ~\(label.calories) kcal."
            }
        }
    }
}

struct FoodLabel { let name: String; let calories: Int }

class FoodClassifier {
    private let lookup: [String: Int] = [
        "apple": 95,
        "banana": 105,
        "broccoli": 55,
        "rice": 206,
        "chicken breast": 165
    ]
    func predict(image: UIImage) -> FoodLabel {
        // TODO: Integrate CoreML Vision model. For demo, always return apple.
        let name = "apple"
        return FoodLabel(name: name, calories: lookup[name] ?? 0)
    }
}

// MARK: - Speech Recognition Manager
class SpeechRecognitionManager: NSObject, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var isAuthorized = false
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.isAuthorized = status == .authorized
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        // Reset transcribed text
        transcribedText = ""
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil {
                self.stopRecording()
            }
        }
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}

// MARK: - Profile Manager
class ProfileManager: ObservableObject {
    @Published var userName: String = ""
    @Published var age: Int = 25
    @Published var weight: Int = 150
    @Published var height: Int = 70
    @Published var fitnessLevel: String = ""
    @Published var selectedGoals: [String] = []
    @Published var equipment: String = ""
    @Published var isOnboardingComplete: Bool = false
    @Published var gender: String = ""
    @Published var goal: String = ""
    @Published var bmi: String = ""
    
    private var gptService: GPTService?
    
    init() {
        loadProfile()
    }
    
    func setGPTService(_ service: GPTService) {
        self.gptService = service
    }
    
    func completeOnboarding() {
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func resetProfile() {
        // Clear all stored data
        userName = ""
        age = 25
        weight = 150
        height = 70
        fitnessLevel = ""
        selectedGoals = []
        equipment = ""
        isOnboardingComplete = false
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "age")
        UserDefaults.standard.removeObject(forKey: "weight")
        UserDefaults.standard.removeObject(forKey: "height")
        UserDefaults.standard.removeObject(forKey: "fitnessLevel")
        UserDefaults.standard.removeObject(forKey: "selectedGoals")
        UserDefaults.standard.removeObject(forKey: "equipment")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        
        // Clear chat history
        gptService?.clearMessages()
    }
    
    private func loadProfile() {
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        age = UserDefaults.standard.integer(forKey: "age")
        if age == 0 { age = 25 }
        weight = UserDefaults.standard.integer(forKey: "weight")
        if weight == 0 { weight = 150 }
        height = UserDefaults.standard.integer(forKey: "height")
        if height == 0 { height = 70 }
        fitnessLevel = UserDefaults.standard.string(forKey: "fitnessLevel") ?? ""
        equipment = UserDefaults.standard.string(forKey: "equipment") ?? ""
        isOnboardingComplete = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if let goalsData = UserDefaults.standard.data(forKey: "selectedGoals"),
           let goals = try? JSONDecoder().decode([String].self, from: goalsData) {
            selectedGoals = goals
        }
    }
    
    func saveProfile() {
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(age, forKey: "age")
        UserDefaults.standard.set(weight, forKey: "weight")
        UserDefaults.standard.set(height, forKey: "height")
        UserDefaults.standard.set(fitnessLevel, forKey: "fitnessLevel")
        UserDefaults.standard.set(equipment, forKey: "equipment")
        
        if let goalsData = try? JSONEncoder().encode(selectedGoals) {
            UserDefaults.standard.set(goalsData, forKey: "selectedGoals")
        }
    }
    
    func updateProfile(from text: String) -> String {
        let lowerText = text.lowercased()
        
        // Extract weight
        if let weightMatch = lowerText.range(of: #"(\d+)\s*(?:pounds?|lbs?)"#, options: .regularExpression) {
            let weightString = String(lowerText[weightMatch])
            if let weightValue = Int(weightString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                weight = weightValue
            }
        }
        
        // Extract height
        if let heightMatch = lowerText.range(of: #"(\d+)\s*(?:inches?|in)"#, options: .regularExpression) {
            let heightString = String(lowerText[heightMatch])
            if let heightValue = Int(heightString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                height = heightValue
            }
        }
        
        // Extract age
        if let ageMatch = lowerText.range(of: #"(\d+)\s*(?:years?|yrs?)"#, options: .regularExpression) {
            let ageString = String(lowerText[ageMatch])
            if let ageValue = Int(ageString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                age = ageValue
            }
        }
        
        // Extract gender
        if lowerText.contains("male") {
            gender = "male"
        } else if lowerText.contains("female") {
            gender = "female"
        }
        
        // Extract fitness level
        if lowerText.contains("beginner") {
            fitnessLevel = "beginner"
        } else if lowerText.contains("intermediate") {
            fitnessLevel = "intermediate"
        } else if lowerText.contains("advanced") {
            fitnessLevel = "advanced"
        }
        
        // Extract goal
        if lowerText.contains("build muscle") || lowerText.contains("muscle") {
            goal = "build muscle"
        } else if lowerText.contains("lose weight") || lowerText.contains("weight loss") {
            goal = "lose weight"
        } else if lowerText.contains("cardio") || lowerText.contains("endurance") {
            goal = "improve cardio"
        }
        
        // Extract equipment
        var equipmentList: [String] = []
        if lowerText.contains("dumbbell") {
            equipmentList.append("dumbbells")
        }
        if lowerText.contains("resistance band") {
            equipmentList.append("resistance bands")
        }
        if lowerText.contains("none") || lowerText.contains("no equipment") {
            equipmentList.append("none")
        }
        if !equipmentList.isEmpty {
            equipment = equipmentList.joined(separator: ", ")
        }
        
        // Calculate BMI if we have weight and height
        calculateBMI()
        
        return "Profile updated! I've extracted: \(goal.isEmpty ? "" : "Goal: \(goal), ")\(weight == 0 ? "" : "Weight: \(weight)lbs, ")\(height == 0 ? "" : "Height: \(height)in, ")\(age == 0 ? "" : "Age: \(age), ")\(gender.isEmpty ? "" : "Gender: \(gender), ")\(fitnessLevel.isEmpty ? "" : "Level: \(fitnessLevel), ")\(equipment.isEmpty ? "" : "Equipment: \(equipment)")"
    }
    
    func calculateBMI() {
        let weightValue = Double(weight)
        let heightValue = Double(height)
        let heightInMeters = heightValue * 0.0254 // Convert inches to meters
        let weightInKg = weightValue * 0.453592 // Convert lbs to kg
        let bmiValue = weightInKg / (heightInMeters * heightInMeters)
        bmi = String(format: "%.1f", bmiValue)
    }
}

// MARK: - HealthKit Manager
class HealthKitManager: ObservableObject {
    @Published var biometricData: BiometricData?
    @Published var workoutJournal: [WorkoutJournalEntry] = []
    @Published var isAuthorized = false
    
    private let healthStore = HKHealthStore()
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchTodayData()
                }
            }
        }
    }
    
    func fetchTodayData() {
        guard isAuthorized else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        fetchSteps(predicate: predicate) { steps in
            self.fetchCalories(predicate: predicate) { calories in
                self.fetchDistance(predicate: predicate) { distance in
                    self.fetchHeartRate(predicate: predicate) { heartRate in
                        self.fetchWorkouts(predicate: predicate) { workouts in
                            DispatchQueue.main.async {
                                self.biometricData = BiometricData(
                                    date: now,
                                    steps: steps,
                                    caloriesBurned: calories,
                                    activeCalories: calories,
                                    distance: distance,
                                    heartRate: heartRate,
                                    workouts: workouts
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fetchSteps(predicate: NSPredicate, completion: @escaping (Int) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            completion(Int(steps))
        }
        healthStore.execute(query)
    }
    
    private func fetchCalories(predicate: NSPredicate, completion: @escaping (Double) -> Void) {
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            completion(calories)
        }
        healthStore.execute(query)
    }
    
    private func fetchDistance(predicate: NSPredicate, completion: @escaping (Double) -> Void) {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
            completion(distance)
        }
        healthStore.execute(query)
    }
    
    private func fetchHeartRate(predicate: NSPredicate, completion: @escaping (Double?) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
            let heartRate = result?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
            completion(heartRate)
        }
        healthStore.execute(query)
    }
    
    private func fetchWorkouts(predicate: NSPredicate, completion: @escaping ([HealthKitWorkout]) -> Void) {
        let workoutQuery = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            let workouts = samples?.compactMap { sample -> HealthKitWorkout? in
                guard let workout = sample as? HKWorkout else { return nil }
                return HealthKitWorkout(
                    id: workout.uuid.uuidString,
                    workoutTitle: self.getWorkoutTypeName(workout.workoutActivityType),
                    startTime: workout.startDate,
                    endTime: workout.endDate,
                    duration: workout.duration,
                    caloriesBurned: workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0,
                    workoutType: self.getWorkoutTypeName(workout.workoutActivityType)
                )
            } ?? []
            completion(workouts)
        }
        healthStore.execute(workoutQuery)
    }
    
    private func getWorkoutTypeName(_ activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .running:
            return "Running"
        case .walking:
            return "Walking"
        case .cycling:
            return "Cycling"
        case .swimming:
            return "Swimming"
        case .yoga:
            return "Yoga"
        case .functionalStrengthTraining:
            return "Strength Training"
        case .traditionalStrengthTraining:
            return "Traditional Strength Training"
        case .highIntensityIntervalTraining:
            return "HIIT"
        case .mixedCardio:
            return "Mixed Cardio"
        case .coreTraining:
            return "Core Training"
        case .flexibility:
            return "Flexibility"
        case .mindAndBody:
            return "Mind & Body"
        default:
            return "Workout"
        }
    }
}

// MARK: - Workout Session Manager
class WorkoutSessionManager: ObservableObject {
    @Published var currentSession: WorkoutSession?
    @Published var isSessionActive = false
    
    private var activityTracker: ActivityTracker?
    
    func setActivityTracker(_ tracker: ActivityTracker) {
        self.activityTracker = tracker
    }
    
    func startSession(with workout: WorkoutPlan) {
        currentSession = WorkoutSession(workout: workout)
        isSessionActive = true
    }
    
    func completeExercise(_ exercise: Exercise) {
        currentSession?.completeExercise(exercise)
        activityTracker?.addActivity(ActivityItem(
            type: "Exercise Completed",
            value: exercise.name,
            timestamp: Date(),
            impact: "Progress"
        ))
    }
    
    func endSession() {
        guard let session = currentSession else { return }
        
        activityTracker?.addActivity(ActivityItem(
            type: "Workout Completed",
            value: session.workout.title,
            timestamp: Date(),
            impact: "Achievement"
        ))
        
        currentSession = nil
        isSessionActive = false
    }
}

struct WorkoutSession {
    let workout: WorkoutPlan
    let startTime: Date
    var completedExercises: [String] = []
    
    init(workout: WorkoutPlan) {
        self.workout = workout
        self.startTime = Date()
    }
    
    mutating func completeExercise(_ exercise: Exercise) {
        completedExercises.append(exercise.name)
    }
    
    var duration: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
    
    var progress: Double {
        return Double(completedExercises.count) / Double(workout.exercises.count)
    }
}

// MARK: - Goal Manager
class GoalManager: ObservableObject {
    @Published var availableGoals: [String] = [
        "Lose Weight",
        "Build Muscle",
        "Improve Cardio",
        "Increase Strength",
        "Maintain Fitness",
        "Improve Flexibility",
        "Better Endurance",
        "Tone Body"
    ]
    
    @Published var selectedGoals: [String] = []
    
    func toggleGoal(_ goal: String) {
        if selectedGoals.contains(goal) {
            selectedGoals.removeAll { $0 == goal }
        } else {
            selectedGoals.append(goal)
        }
    }
    
    func isSelected(_ goal: String) -> Bool {
        return selectedGoals.contains(goal)
    }
}
