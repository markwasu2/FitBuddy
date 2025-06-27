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
import CoreData

// MARK: - Modern Design System
extension Color {
    static let bgPrimary = Color.white
    static let bgSecondary = Color(red: 248/255, green: 248/255, blue: 250/255)
    static let textPrimary = Color.black
    static let textSecondary = Color(red: 142/255, green: 142/255, blue: 147/255)
    static let accentBlue = Color(red: 10/255, green: 132/255, blue: 255/255)
    static let cardShadow = Color.black.opacity(0.05)
    static let cardCorner: CGFloat = 16
}

extension Font {
    static let largeTitle = Font.system(size: 28, weight: .bold)
    static let title = Font.system(size: 20, weight: .semibold)
    static let body = Font.system(size: 17)
    static let caption = Font.system(size: 13, weight: .medium)
}

extension CGFloat {
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
}

extension View {
    func cardStyle() -> some View {
        self.padding(.spacingM)
            .background(Color.bgSecondary)
            .cornerRadius(Color.cardCorner)
            .modifier(CardShadow())
    }
}

struct CardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - App Entry Point
@main
struct FitBuddyApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var workoutPlanManager = WorkoutPlanManager()
    @StateObject private var workoutJournal = WorkoutJournal()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var chatEngine = ChatEngine()
    @StateObject private var geminiService = GeminiService()
    
    var body: some Scene {
        WindowGroup {
            if profileManager.isOnboardingComplete {
                MainTabView()
                    .environmentObject(profileManager)
                    .environmentObject(workoutPlanManager)
                    .environmentObject(workoutJournal)
                    .environmentObject(healthKitManager)
                    .environmentObject(notificationManager)
                    .environmentObject(calendarManager)
                    .environmentObject(chatEngine)
                    .environmentObject(geminiService)
            } else {
                OnboardingView()
                    .environmentObject(profileManager)
                    .environmentObject(workoutPlanManager)
                    .environmentObject(workoutJournal)
                    .environmentObject(healthKitManager)
                    .environmentObject(notificationManager)
                    .environmentObject(calendarManager)
                    .environmentObject(chatEngine)
                    .environmentObject(geminiService)
            }
        }
        .preferredColorScheme(.dark)
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
    static let secondaryText = Color(.secondaryLabel)
}

// MARK: - Basic Models
struct WorkoutPlan: Codable, Identifiable {
    var id: UUID = UUID()
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
    var id: UUID = UUID()
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
    var id: UUID = UUID()
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
    var id: String
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

struct BiometricData {
    var steps: Int = 0
    var activeCalories: Int = 0
    var distance: Double = 0.0
    var heartRate: Int = 0
    var water: Double = 0.0
}

struct WorkoutJournalEntry: Codable, Identifiable {
    var id: UUID = UUID()
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
    var id: UUID = UUID()
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
    var id: UUID = UUID()
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

struct UserProfile: Codable {
    var name: String
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
    @State private var currentStep = 0
    @State private var name = ""
    @State private var age = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var selectedGender = ""
    @State private var selectedFitnessLevel = ""
    @State private var selectedEquipment: Set<String> = []
    @State private var selectedGoals: Set<String> = []
    
    private let totalSteps = 7
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                ProgressView(value: Double(currentStep), total: Double(totalSteps - 1))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding(.horizontal)
                
                stepContent
                
                Spacer()
                
                navigationButtons
            }
            .padding()
            .navigationTitle("Welcome to Moki")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            welcomeStep
        case 1:
            nameAgeStep
        case 2:
            heightWeightStep
        case 3:
            genderStep
        case 4:
            fitnessLevelStep
        case 5:
            equipmentStep
        case 6:
            goalsStep
        default:
            EmptyView()
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to Moki!")
                .font(.largeTitle)
                .bold()
            
            Text("Your AI-powered fitness companion")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Let's create your personalized fitness profile to get started with customized workout plans and expert guidance.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
    }
    
    private var nameAgeStep: some View {
        VStack(spacing: 20) {
            Text("Tell us about yourself")
                .font(.title)
                .bold()
            
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.title2)
            
            TextField("Age", text: $age)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .font(.title2)
        }
    }
    
    private var heightWeightStep: some View {
        VStack(spacing: 20) {
            Text("Your measurements")
                .font(.title)
                .bold()
            
            HStack {
                TextField("Height (cm)", text: $height)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .font(.title2)
                
                TextField("Weight (kg)", text: $weight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .font(.title2)
            }
        }
    }
    
    private var genderStep: some View {
        VStack(spacing: 20) {
            Text("Gender")
                .font(.title)
                .bold()
            
            VStack(spacing: 15) {
                Button("Male") { selectedGender = "Male" }
                    .buttonStyle(SelectionButtonStyle(isSelected: selectedGender == "Male"))
                
                Button("Female") { selectedGender = "Female" }
                    .buttonStyle(SelectionButtonStyle(isSelected: selectedGender == "Female"))
                
                Button("Other") { selectedGender = "Other" }
                    .buttonStyle(SelectionButtonStyle(isSelected: selectedGender == "Other"))
            }
        }
    }
    
    private var fitnessLevelStep: some View {
        VStack(spacing: 20) {
            Text("Fitness Level")
                .font(.title)
                .bold()
            
            VStack(spacing: 15) {
                Button("Beginner") { selectedFitnessLevel = "Beginner" }
                    .buttonStyle(SelectionButtonStyle(isSelected: selectedFitnessLevel == "Beginner"))
                
                Button("Intermediate") { selectedFitnessLevel = "Intermediate" }
                    .buttonStyle(SelectionButtonStyle(isSelected: selectedFitnessLevel == "Intermediate"))
                
                Button("Advanced") { selectedFitnessLevel = "Advanced" }
                    .buttonStyle(SelectionButtonStyle(isSelected: selectedFitnessLevel == "Advanced"))
            }
        }
    }
    
    private var equipmentStep: some View {
        VStack(spacing: 20) {
            Text("Available Equipment")
                .font(.title)
                .bold()
            
            VStack(spacing: 15) {
                EquipmentButton(title: "Body-weight", isSelected: selectedEquipment.contains("Body-weight")) {
                    toggleEquipment("Body-weight")
                }
                
                EquipmentButton(title: "Yoga Mat", isSelected: selectedEquipment.contains("Yoga Mat")) {
                    toggleEquipment("Yoga Mat")
                }
                
                EquipmentButton(title: "Jump Rope", isSelected: selectedEquipment.contains("Jump Rope")) {
                    toggleEquipment("Jump Rope")
                }
            }
        }
    }
    
    private var goalsStep: some View {
        VStack(spacing: 20) {
            Text("Your Goals")
                .font(.title)
                .bold()
            
            VStack(spacing: 15) {
                GoalButton(title: "Lose Weight", isSelected: selectedGoals.contains("Lose Weight")) {
                    toggleGoal("Lose Weight")
                }
                
                GoalButton(title: "Build Muscle", isSelected: selectedGoals.contains("Build Muscle")) {
                    toggleGoal("Build Muscle")
                }
                
                GoalButton(title: "Maintenance", isSelected: selectedGoals.contains("Maintenance")) {
                    toggleGoal("Maintenance")
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
        case 1: return !name.isEmpty && !age.isEmpty
        case 2: return !height.isEmpty && !weight.isEmpty
        case 3: return !selectedGender.isEmpty
        case 4: return !selectedFitnessLevel.isEmpty
        case 5: return !selectedEquipment.isEmpty
        case 6: return !selectedGoals.isEmpty
        default: return false
        }
    }
    
    private func toggleEquipment(_ equipment: String) {
        if selectedEquipment.contains(equipment) {
            selectedEquipment.remove(equipment)
        } else {
            selectedEquipment.insert(equipment)
        }
    }
    
    private func toggleGoal(_ goal: String) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }
    
    private func completeOnboarding() {
        profileManager.name = name
        profileManager.age = Int(age) ?? 25
        profileManager.height = Int(height) ?? 170
        profileManager.weight = Int(weight) ?? 70
        profileManager.gender = selectedGender
        profileManager.fitnessLevel = selectedFitnessLevel
        profileManager.equipment = Array(selectedEquipment)
        profileManager.goals = Array(selectedGoals)
        
        profileManager.completeOnboarding()
    }
}

struct SelectionButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .black)
            .cornerRadius(12)
    }
}

struct EquipmentButton: View {
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
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
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
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tab Container
struct MainTabView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var workoutJournal: WorkoutJournal
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var chatEngine: ChatEngine
    
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem { 
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            PlanScreen()
                .tabItem { 
                    Image(systemName: "calendar")
                    Text("Plan")
                }
            CoachScreen()
                .tabItem {
                    Image(systemName: "message.and.waveform.fill")
                    Text("Coach")
                }
            ProfileScreen()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(Color(hex: "#7C3AED"))
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(hex: "#1C1C2E"))
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "#7C3AED"))
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color(hex: "#7C3AED"))]
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color(hex: "#9CA3AF"))
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color(hex: "#9CA3AF"))]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Home Screen
struct HomeScreen: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome Back,")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                            Text(profileManager.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button(action: { showingEditProfile = true }) {
                            Circle()
                                .fill(Color(hex: "#7C3AED"))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(profileManager.name.prefix(1)).uppercased())
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Today's Plan Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today's Plan")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#C4B5FD"))
                                Text("Full Body Strength")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("60 min • High Intensity")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#C4B5FD"))
                            }
                            Spacer()
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.white)
                                )
                        }
                        
                        Button(action: {}) {
                            Text("Start Workout")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#7C3AED"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#7C3AED"), Color(hex: "#4F46E5")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Biometrics Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Biometrics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            BiometricCard(
                                icon: "heart.fill",
                                iconColor: Color(hex: "#F87171"),
                                title: "Heart Rate",
                                value: "72",
                                unit: "bpm"
                            )
                            
                            BiometricCard(
                                icon: "figure.walk",
                                iconColor: Color(hex: "#60A5FA"),
                                title: "Steps",
                                value: "4,521",
                                unit: nil
                            )
                            
                            BiometricCard(
                                icon: "bed.double.fill",
                                iconColor: Color(hex: "#34D399"),
                                title: "Sleep",
                                value: "7h 45m",
                                unit: nil
                            )
                            
                            BiometricCard(
                                icon: "flame.fill",
                                iconColor: Color(hex: "#FB923C"),
                                title: "Calories",
                                value: "1,204",
                                unit: "kcal"
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(hex: "#0D0D1A"))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
    }
}

struct BiometricCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "#D1D5DB"))
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let unit = unit {
                    Text(unit)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#1C1C2E"))
        .cornerRadius(12)
    }
}

// MARK: - Plan Screen
struct PlanScreen: View {
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Calendar
                    VStack(spacing: 16) {
                        HStack {
                            Text("June 2025")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                            HStack(spacing: 8) {
                                Button(action: {}) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color(hex: "#374151"))
                                        .clipShape(Circle())
                                }
                                Button(action: {}) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color(hex: "#374151"))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        
                        // Calendar grid would go here
                        // For now, showing a placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#1C1C2E"))
                            .frame(height: 200)
                            .overlay(
                                Text("Calendar View")
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(16)
                    .background(Color(hex: "#1C1C2E"))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Upcoming Workouts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Upcoming")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            WorkoutCard(
                                title: "Full Body Strength",
                                time: "Today • 60 min",
                                icon: "dumbbell.fill",
                                iconColor: Color(hex: "#7C3AED")
                            )
                            
                            WorkoutCard(
                                title: "Active Recovery & Stretch",
                                time: "Tomorrow • 30 min",
                                icon: "figure.flexibility",
                                iconColor: Color(hex: "#60A5FA")
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(hex: "#0D0D1A"))
            .navigationTitle("Workout Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct WorkoutCard: View {
    let title: String
    let time: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(iconColor.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.title3)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(time)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .padding(16)
        .background(Color(hex: "#1C1C2E"))
        .cornerRadius(12)
    }
}

// MARK: - Coach Screen
struct CoachScreen: View {
    @EnvironmentObject var chatEngine: ChatEngine
    @State private var messageText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(chatEngine.messages) { message in
                            ChatBubble(message: message)
                        }
                    }
                    .padding()
                }
                .background(Color(hex: "#0D0D1A"))
                
                // Suggestion chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(["New workout plan", "How's my progress?", "Adjust my goals"], id: \.self) { suggestion in
                            Button(action: {
                                messageText = suggestion
                            }) {
                                Text(suggestion)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(hex: "#1C1C2E"))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(hex: "#0D0D1A"))
                
                // Input area
                HStack(spacing: 12) {
                    TextField("Ask me anything...", text: $messageText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(Color(hex: "#1C1C2E"))
                        .cornerRadius(25)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        if !messageText.isEmpty {
                            chatEngine.sendMessage(messageText)
                            messageText = ""
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: "#7C3AED"))
                    }
                }
                .padding()
                .background(Color(hex: "#0D0D1A"))
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding()
                        .background(Color(hex: "#7C3AED"))
                        .foregroundColor(.white)
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#7C3AED"), Color(hex: "#4F46E5")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text("AI")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        Text(message.content)
                            .padding()
                            .background(Color(hex: "#1C1C2E"))
                            .foregroundColor(.white)
                            .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Profile Screen
struct ProfileScreen: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // User info
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color(hex: "#7C3AED"))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(profileManager.name.prefix(1)).uppercased())
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profileManager.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Joined May 2024")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Settings list
                    VStack(spacing: 8) {
                        SettingsRow(
                            icon: "target",
                            iconColor: Color(hex: "#7C3AED"),
                            title: "My Goals"
                        )
                        
                        SettingsRow(
                            icon: "link",
                            iconColor: Color(hex: "#60A5FA"),
                            title: "Connected Devices"
                        )
                        
                        SettingsRow(
                            icon: "bell",
                            iconColor: Color(hex: "#34D399"),
                            title: "Notifications"
                        )
                        
                        SettingsRow(
                            icon: "person.crop.circle.badge.plus",
                            iconColor: Color(hex: "#F87171"),
                            title: "Account & Security"
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(hex: "#0D0D1A"))
            .navigationTitle("Profile & Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title3)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color(hex: "#6B7280"))
                .font(.caption)
        }
        .padding()
        .background(Color(hex: "#1C1C2E"))
        .cornerRadius(12)
    }
}

// MARK: - Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
