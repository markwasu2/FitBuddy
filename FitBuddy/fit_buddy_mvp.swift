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
    // Primary accent - Soft Coral
    static let primaryCoral = Color(hex: "#FF6B6B")
    
    // Secondary accent - Warm Peach
    static let secondaryPeach = Color(hex: "#FFA58F")
    
    // Highlight - Apricot
    static let highlightApricot = Color(hex: "#FFB07C")
    
    // Call-to-action / KPI chips - Honey Yellow
    static let ctaYellow = Color(hex: "#FFC65C")
    
    // Sub-accent / error - Muted Terracotta
    static let mutedTerracotta = Color(hex: "#E07A5F")
    
    // Light surface - Off-White
    static let offWhite = Color(hex: "#FDFCFB")
    
    // Warm contrasting background - Soft Cream
    static let warmCream = Color(hex: "#F8F4F0")
    
    // Dark text / backgrounds - Charcoal
    static let charcoal = Color(hex: "#333333")
    
    // Background colors
    static let bgPrimary = Color.warmCream
    static let bgSecondary = Color.white
    static let textPrimary = Color.charcoal
    static let textSecondary = Color(hex: "#666666")
    static let accentBlue = Color.primaryCoral
    static let cardShadow = Color.black.opacity(0.08)
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
    @StateObject private var geminiService = GeminiService()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var workoutPlanManager = WorkoutPlanManager()
    @StateObject private var workoutJournal = WorkoutJournal()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(profileManager)
                .environmentObject(geminiService)
                .environmentObject(calendarManager)
                .environmentObject(workoutPlanManager)
                .environmentObject(workoutJournal)
                .environmentObject(healthKitManager)
                .environmentObject(notificationManager)
                .onAppear {
                    // Configure GeminiService with dependencies
                    geminiService.configure(
                        profileManager: profileManager,
                        calendarManager: calendarManager,
                        workoutPlanManager: workoutPlanManager
                    )
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
    @EnvironmentObject var geminiService: GeminiService
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var workoutPlanManager: WorkoutPlanManager
    
    var body: some View {
        if profileManager.isOnboardingComplete {
            MainTabView()
        } else {
            OnboardingView()
                .preferredColorScheme(.light)
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static let cardBackground = Color.offWhite
    static let errorRed = Color.mutedTerracotta
    static let successGreen = Color(hex: "#4CAF50")
    static let secondaryText = Color.textSecondary
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
            let prefixCount = min(10, recentActivity.count)
            recentActivity = Array(recentActivity.prefix(prefixCount))
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
            let suffixCount = min(100, chatHistory.count)
            chatHistory = Array(chatHistory.suffix(suffixCount))
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

// MARK: - Main Navigation Container
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            ActivitiesView()
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("Activities")
                }
                .tag(1)
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(2)
            
            NutritionView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Nutrition")
                }
                .tag(3)
            
            AICoachView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI Coach")
                }
                .tag(4)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(5)
        }
        .accentColor(Color.primaryCoral)
        .preferredColorScheme(.light)
        .onAppear {
            // Ensure we start with a valid tab
            selectedTab = 0
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Add safety check for tab changes
            if newValue < 0 || newValue > 5 {
                selectedTab = 0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Reset to safe state when app becomes active
            if selectedTab < 0 || selectedTab > 5 {
                selectedTab = 0
            }
        }
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var workoutPlanManager: WorkoutPlanManager
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var workoutJournal: WorkoutJournal
    @State private var showingQuickActions = false
    @State private var showStartWorkout = false
    @State private var showLogActivity = false
    @State private var navigateToPlan = false
    @State private var navigateToAICoach = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    // Quick Actions
                    quickActionsSection
                    // Current Activity
                    currentActivitySection
                    // Biometrics
                    biometricsSection
                    // Activity Journal
                    activityJournalSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Extra padding for tab bar
            }
            .background(Color.offWhite)
            .navigationBarHidden(true)
            .sheet(isPresented: $showStartWorkout) {
                StartWorkoutSheet()
                    .environmentObject(calendarManager)
            }
            .sheet(isPresented: $showLogActivity) {
                LogActivitySheet()
                    .environmentObject(workoutJournal)
            }
            .navigationDestination(isPresented: $navigateToPlan) {
                CalendarView()
                    .environmentObject(workoutPlanManager)
                    .environmentObject(CalendarManager())
            }
            .navigationDestination(isPresented: $navigateToAICoach) {
                AICoachView()
                    .environmentObject(GeminiService())
                    .environmentObject(profileManager)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.title2)
                        .foregroundColor(Color.textSecondary)
                    
                    Text(profileManager.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.textPrimary)
                }
                
                Spacer()
                
                Button(action: { showingQuickActions = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.primaryCoral)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .medium))
                    }
                }
            }
            
            Text("Ready to crush your fitness goals today?")
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "Start Workout",
                    subtitle: "Begin your session",
                    icon: "play.fill",
                    color: Color.primaryCoral
                ) {
                    showStartWorkout = true
                }
                QuickActionCard(
                    title: "Log Activity",
                    subtitle: "Record your progress",
                    icon: "plus.circle.fill",
                    color: Color.secondaryPeach
                ) {
                    showLogActivity = true
                }
                QuickActionCard(
                    title: "View Plan",
                    subtitle: "Check your schedule",
                    icon: "calendar.badge.clock",
                    color: Color.ctaYellow
                ) {
                    navigateToPlan = true
                }
                QuickActionCard(
                    title: "AI Coach",
                    subtitle: "Get personalized advice",
                    icon: "brain.head.profile",
                    color: Color.highlightApricot
                ) {
                    navigateToAICoach = true
                }
            }
        }
    }
    
    private var currentActivitySection: some View {
        return VStack(alignment: .leading, spacing: 24) {
            // Current Activity
            VStack(alignment: .leading, spacing: 16) {
                Text("Current Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's Goal")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                            
                            Text("45 minutes")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        CircularProgressView(progress: 0.7, size: 60)
                    }
                    
                    HStack(spacing: 16) {
                        StatCard(title: "Steps", value: "8,432", subtitle: "Goal: 10,000")
                        StatCard(title: "Calories", value: "1,247", subtitle: "Goal: 2,000")
                    }
                }
                .padding(20)
                .background(Color(hex: "#1C1C2E"))
                .cornerRadius(16)
            }
            
            // Scheduled Workouts Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Scheduled Workouts")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.textPrimary)
                    
                    Spacer()
                    
                    if !calendarManager.getUpcomingWorkouts().isEmpty {
                        Text("\(calendarManager.getUpcomingWorkouts().count) upcoming")
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                }
                
                if calendarManager.getUpcomingWorkouts().isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 32))
                            .foregroundColor(Color.textSecondary)
                        
                        Text("No scheduled workouts")
                            .font(.subheadline)
                            .foregroundColor(Color.textSecondary)
                        
                        Text("Schedule a workout with your AI Coach!")
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                } else {
                    VStack(spacing: 8) {
                        ForEach(calendarManager.getUpcomingWorkouts().prefix(3), id: \.id) { workout in
                            ScheduledWorkoutCard(workout: workout)
                        }
                    }
                }
            }
        }
    }
    
    private var biometricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Biometrics")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                BiometricCard(
                    title: "Heart Rate",
                    value: "72",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: Color(hex: "#EF4444")
                )
                
                BiometricCard(
                    title: "Sleep",
                    value: "7.5",
                    unit: "hrs",
                    icon: "bed.double.fill",
                    color: Color.secondaryPeach
                )
                
                BiometricCard(
                    title: "Weight",
                    value: "165",
                    unit: "lbs",
                    icon: "scalemass.fill",
                    color: Color(hex: "#10B981")
                )
                
                BiometricCard(
                    title: "Body Fat",
                    value: "18",
                    unit: "%",
                    icon: "chart.pie.fill",
                    color: Color(hex: "#F59E0B")
                )
            }
        }
    }
    
    private var activityJournalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activities")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to activities
                }
                .font(.subheadline)
                .foregroundColor(Color.primaryCoral)
            }
            
            VStack(spacing: 12) {
                let activities = sampleActivities
                let displayCount = min(3, activities.count)
                ForEach(Array(activities.prefix(displayCount).enumerated()), id: \.element.id) { index, activity in
                    ActivityJournalCard(activity: activity)
                }
            }
        }
    }
    
    private var sampleActivities: [WorkoutEntry] {
        [
            WorkoutEntry(
                date: Date(),
                exercises: [],
                type: "Strength Training",
                duration: 45,
                mood: "Great",
                difficulty: "Medium",
                calories: 320
            ),
            WorkoutEntry(
                date: Date().addingTimeInterval(-86400),
                exercises: [],
                type: "Cardio",
                duration: 30,
                mood: "Good",
                difficulty: "Easy",
                calories: 280
            ),
            WorkoutEntry(
                date: Date().addingTimeInterval(-172800),
                exercises: [],
                type: "Yoga",
                duration: 60,
                mood: "Excellent",
                difficulty: "Easy",
                calories: 180
            )
        ]
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Activity Journal Card
struct ActivityJournalCard: View {
    let activity: WorkoutEntry
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.primaryCoral)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.type)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.textPrimary)
                
                Text("\(activity.duration) min • \(activity.exercises.count) exercises")
                    .font(.subheadline)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            Text(activity.date, style: .date)
                .font(.caption)
                .foregroundColor(Color.textSecondary)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Scheduled Workout Card
struct ScheduledWorkoutCard: View {
    let workout: CalendarEvent
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.ctaYellow)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.textPrimary)
                
                Text(workout.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(workout.time)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primaryCoral)
                
                Text("Scheduled")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(16)
        .background(Color.white)
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
                                .foregroundColor(Color.textPrimary)
                            Spacer()
                            HStack(spacing: 8) {
                                Button(action: {}) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(Color.textPrimary)
                                        .padding(8)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                Button(action: {}) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.textPrimary)
                                        .padding(8)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        
                        // Calendar grid would go here
                        // For now, showing a placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(height: 200)
                            .overlay(
                                Text("Calendar View")
                                    .foregroundColor(Color.textPrimary)
                            )
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Upcoming Workouts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Upcoming")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.textPrimary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            WorkoutCard(
                                title: "Full Body Strength",
                                time: "Today • 60 min",
                                icon: "dumbbell.fill",
                                iconColor: Color.primaryCoral
                            )
                            
                            WorkoutCard(
                                title: "Active Recovery & Stretch",
                                time: "Tomorrow • 30 min",
                                icon: "figure.flexibility",
                                iconColor: Color.secondaryPeach
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.offWhite)
            .navigationTitle("Workout Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
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
                    .foregroundColor(Color.textPrimary)
                Text(time)
                    .font(.subheadline)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.textSecondary)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - AI Coach View
struct AICoachView: View {
    @EnvironmentObject var geminiService: GeminiService
    @EnvironmentObject var profileManager: ProfileManager
    @State private var messageText = ""
    @State private var showingProfile = false
    @State private var isRecording = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    @State private var isSpeechAuthorized = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(geminiService.messages, id: \.id) { message in
                                ModernChatBubble(message: message)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100) // Extra padding for input and tab bar
                    }
                    .onChange(of: geminiService.messages.count) { oldValue, newValue in
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(geminiService.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Input area
                VStack(spacing: 0) {
                    Divider()
                        .background(Color(hex: "#E5E7EB")) // Light divider
                    
                    HStack(spacing: 12) {
                        TextField("Ask your AI coach...", text: $messageText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white) // White background
                            .cornerRadius(24)
                            .foregroundColor(Color.charcoal) // Charcoal text
                            .accentColor(Color.primaryCoral) // Soft Coral cursor
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color(hex: "#E5E7EB"), lineWidth: 1) // Light border
                            )
                        
                        // Voice input button
                        Button(action: toggleVoiceRecording) {
                            Image(systemName: isRecording ? "waveform" : "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(isRecording ? Color.red : Color.primaryCoral)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(isRecording ? Color.red.opacity(0.1) : Color.primaryCoral.opacity(0.1))
                                )
                        }
                        .disabled(!isSpeechAuthorized)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(messageText.isEmpty ? Color(hex: "#9CA3AF") : Color.primaryCoral) // Gray when empty, coral when has text
                        }
                        .disabled(messageText.isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.offWhite) // Off-white background
                }
            }
            .background(Color.offWhite) // Off-white background
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingProfile = true }) {
                        Image(systemName: "person.circle")
                            .foregroundColor(Color.primaryCoral) // Soft Coral
                    }
                }
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileEditSheet()
        }
        .onAppear {
            requestSpeechAuthorization()
            if geminiService.messages.isEmpty {
                // Send welcome message
                let welcomeMessage = ChatMessage(
                    content: "Hi! I'm your FitBuddy AI coach. I'm here to help you with personalized workout plans, nutrition advice, and fitness guidance. What would you like to work on today?",
                    isFromUser: false,
                    timestamp: Date()
                )
                geminiService.messages.append(welcomeMessage)
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let messageToSend = messageText
        messageText = ""
        
        Task {
            geminiService.sendMessage(messageToSend)
        }
    }
    
    // MARK: - Voice Input Functions
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.isSpeechAuthorized = status == .authorized
            }
        }
    }
    
    private func toggleVoiceRecording() {
        if isRecording {
            stopVoiceRecording()
        } else {
            startVoiceRecording()
        }
    }
    
    private func startVoiceRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognition not available")
            return
        }
        
        // Request audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Failed to start audio engine: \(error)")
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.messageText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.stopVoiceRecording()
            }
        }
    }
    
    private func stopVoiceRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
        recognitionRequest = nil
        recognitionTask = nil
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var workoutPlanManager: WorkoutPlanManager
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Stats Overview
                    statsOverviewSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Settings
                    settingsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Extra padding for tab bar
            }
            .background(Color.bgPrimary)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingEditProfile = true }) {
                        Image(systemName: "pencil")
                            .foregroundColor(Color.primaryCoral)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            ProfileEditSheet()
        }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(Color.primaryCoral)
                    .frame(width: 100, height: 100)
                
                Text(String((profileManager.name.prefix(1)).uppercased()))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Name and Info
            VStack(spacing: 8) {
                Text(profileManager.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Text("user@example.com")
                    .font(.subheadline)
                    .foregroundColor(Color.textSecondary)
                
                HStack(spacing: 16) {
                    ProfileInfoItem(title: "Age", value: "\(profileManager.age)")
                    ProfileInfoItem(title: "Height", value: "\(profileManager.height) cm")
                    ProfileInfoItem(title: "Weight", value: "\(profileManager.weight) kg")
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var statsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Stats")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ProfileStatCard(
                    title: "Total Workouts",
                    value: "\(workoutPlanManager.plans.count)",
                    icon: "dumbbell.fill",
                    color: Color.primaryCoral
                )
                
                ProfileStatCard(
                    title: "Current Streak",
                    value: "7 days",
                    icon: "flame.fill",
                    color: Color(hex: "#EF4444")
                )
                
                ProfileStatCard(
                    title: "Total Calories",
                    value: "12,450",
                    icon: "flame.fill",
                    color: Color(hex: "#F59E0B")
                )
                
                ProfileStatCard(
                    title: "Workout Hours",
                    value: "24.5",
                    icon: "clock.fill",
                    color: Color(hex: "#10B981")
                )
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ProfileActionRow(
                    title: "Edit Profile",
                    subtitle: "Update your information",
                    icon: "person.circle.fill",
                    color: Color.primaryCoral
                ) {
                    showingEditProfile = true
                }
                
                ProfileActionRow(
                    title: "Workout History",
                    subtitle: "View your past workouts",
                    icon: "chart.bar.fill",
                    color: Color(hex: "#10B981")
                ) {
                    // TODO: Navigate to workout history
                }
                
                ProfileActionRow(
                    title: "Goals & Progress",
                    subtitle: "Track your fitness goals",
                    icon: "target",
                    color: Color(hex: "#F59E0B")
                ) {
                    // TODO: Navigate to goals
                }
            }
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.textPrimary)
            
            VStack(spacing: 12) {
                ProfileActionRow(
                    title: "Notifications",
                    subtitle: "Manage your alerts",
                    icon: "bell.fill",
                    color: Color(hex: "#EF4444")
                ) {
                    // TODO: Navigate to notifications
                }
                
                ProfileActionRow(
                    title: "Privacy",
                    subtitle: "Control your data",
                    icon: "lock.fill",
                    color: Color.secondaryPeach
                ) {
                    // TODO: Navigate to privacy
                }
                
                ProfileActionRow(
                    title: "Help & Support",
                    subtitle: "Get assistance",
                    icon: "questionmark.circle.fill",
                    color: Color(hex: "#6B7280")
                ) {
                    // TODO: Navigate to help
                }
            }
        }
    }
}

struct ProfileInfoItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
            
            Text(value)
                .font(.body)
                .foregroundColor(Color.textPrimary)
        }
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "#9CA3AF"))
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(16)
        .background(Color(hex: "#1C1C2E"))
        .cornerRadius(12)
    }
}

struct ProfileActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(16)
            .background(Color(hex: "#1C1C2E"))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var workoutPlanManager: WorkoutPlanManager
    @State private var selectedDate = Date()
    @State private var showingAddWorkout = false
    @State private var showingPersonalizedSetup = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Personalized Workout Setup
                    if !workoutPlanManager.isPersonalizationComplete {
                        personalizedSetupSection
                    }
                    
                    // Calendar Grid
                    calendarGridSection
                    
                    // Selected Date Workouts
                    selectedDateWorkoutsSection
                    
                    // Weekly Summary
                    weeklySummarySection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Extra padding for tab bar
            }
            .background(Color.bgPrimary)
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if workoutPlanManager.isPersonalizationComplete {
                            Button(action: { showingPersonalizedSetup = true }) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .foregroundColor(Color.primaryCoral)
                            }
                        }
                        
                        Button(action: { showingAddWorkout = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(Color.primaryCoral)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPersonalizedSetup) {
                PersonalizedWorkoutSetupView()
                    .environmentObject(workoutPlanManager)
            }
        }
    }
    
    private var personalizedSetupSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personalize Your Workouts")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("Get customized workout plans that fit your schedule and preferences")
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.primaryCoral)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .onTapGesture {
                showingPersonalizedSetup = true
            }
        }
    }
    
    private var calendarGridSection: some View {
        VStack(spacing: 16) {
            // Month header
            HStack {
                Button(action: { moveMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.primaryCoral)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Button(action: { moveMonth(1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.primaryCoral)
                }
            }
            
            // Day headers
            HStack(spacing: 0) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(calendarDays, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        hasWorkout: hasWorkoutOnDate(date)
                    ) {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var selectedDateWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedDateString)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.textPrimary)
            
            if personalizedWorkoutsForSelectedDate.isEmpty && workoutsForSelectedDate.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(Color.textSecondary)
                    
                    Text("No workouts scheduled")
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                    
                    if !workoutPlanManager.isPersonalizationComplete {
                        Button("Personalize Workouts") {
                            showingPersonalizedSetup = true
                        }
                        .font(.subheadline)
                        .foregroundColor(Color.primaryCoral)
                    } else {
                        Button("Add Workout") {
                            showingAddWorkout = true
                        }
                        .font(.subheadline)
                        .foregroundColor(Color.primaryCoral)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color.white)
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    // Show personalized workouts first
                    ForEach(personalizedWorkoutsForSelectedDate, id: \.id) { plan in
                        PersonalizedWorkoutCard(plan: plan)
                    }
                    
                    // Show regular workouts
                    ForEach(workoutsForSelectedDate, id: \.id) { workout in
                        ActivityJournalCard(activity: workout)
                    }
                }
            }
        }
    }
    
    private var weeklySummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.textPrimary)
            
            HStack(spacing: 16) {
                WeeklyStatCard(title: "Workouts", value: "5", icon: "dumbbell.fill")
                WeeklyStatCard(title: "Hours", value: "4.5", icon: "clock.fill")
                WeeklyStatCard(title: "Calories", value: "2,100", icon: "flame.fill")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }
    
    private var calendarDays: [Date] {
        // Generate calendar days for current month
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
        
        var days: [Date] = []
        
        // Add previous month days
        let previousMonthDays = firstWeekday - 1
        if previousMonthDays > 0 {
            for i in (1...previousMonthDays).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: startOfMonth) {
                    days.append(date)
                }
            }
        }
        
        // Add current month days
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        // Add next month days to fill the grid
        let remainingDays = max(0, 42 - days.count) // 6 rows * 7 days, ensure non-negative
        if remainingDays > 0 {
            for day in 1...remainingDays {
                if let date = calendar.date(byAdding: .day, value: day, to: days.last ?? startOfMonth) {
                    days.append(date)
                }
            }
        }
        
        return days
    }
    
    private func hasWorkoutOnDate(_ date: Date) -> Bool {
        // Check if there's a workout scheduled for this date
        let hasRegularWorkout = workoutsForSelectedDate.contains { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: date)
        }
        
        let hasPersonalizedWorkout = !workoutPlanManager.getWorkoutsForDate(date).isEmpty
        
        return hasRegularWorkout || hasPersonalizedWorkout
    }
    
    private var personalizedWorkoutsForSelectedDate: [PersonalizedWorkoutPlan] {
        return workoutPlanManager.getWorkoutsForDate(selectedDate)
    }
    
    private var workoutsForSelectedDate: [WorkoutEntry] {
        return sampleWorkouts.filter { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: selectedDate)
        }
    }
    
    private func moveMonth(_ direction: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: direction, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private var sampleWorkouts: [WorkoutEntry] {
        [
            WorkoutEntry(
                date: Date(),
                exercises: [],
                type: "Strength Training",
                duration: 45,
                mood: "Great",
                difficulty: "Medium",
                calories: 320
            ),
            WorkoutEntry(
                date: Date().addingTimeInterval(-86400),
                exercises: [],
                type: "Cardio",
                duration: 30,
                mood: "Good",
                difficulty: "Easy",
                calories: 280
            ),
            WorkoutEntry(
                date: Date().addingTimeInterval(-172800),
                exercises: [],
                type: "Yoga",
                duration: 60,
                mood: "Excellent",
                difficulty: "Easy",
                calories: 180
            )
        ]
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasWorkout: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : (hasWorkout ? Color.textPrimary : Color.textSecondary))
                
                if hasWorkout {
                    Circle()
                        .fill(Color.primaryCoral)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(isSelected ? Color.primaryCoral : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Personalized Workout Card
struct PersonalizedWorkoutCard: View {
    let plan: PersonalizedWorkoutPlan
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.textPrimary)
                    
                    Text(plan.formattedSchedule)
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(plan.formattedDuration)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.primaryCoral)
                    
                    Text(plan.difficulty.rawValue)
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }
            
            // Equipment and muscle groups
            HStack(spacing: 16) {
                if !plan.equipment.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Equipment")
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                        
                        Text(plan.equipment.map { $0.rawValue }.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(Color.textPrimary)
                    }
                }
                
                if !plan.targetMuscleGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target Areas")
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                        
                        Text(plan.targetMuscleGroups.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(Color.textPrimary)
                    }
                }
            }
            
            // Exercises (expandable)
            if !plan.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text("Exercises (\(plan.exercises.count))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.primaryCoral)
                            
                            Spacer()
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(Color.primaryCoral)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if isExpanded {
                        VStack(spacing: 12) {
                            ForEach(plan.exercises, id: \.id) { exercise in
                                ExerciseRow(exercise: exercise)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    // Start workout action
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start Workout")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.primaryCoral)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    // Edit workout action
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primaryCoral)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.primaryCoral.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - Exercise Row
struct ExerciseRow: View {
    let exercise: PersonalizedExercise
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.textPrimary)
                
                Text(exercise.muscleGroup)
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(exercise.formattedSets)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.textPrimary)
                
                Text(exercise.formattedRest)
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(12)
        .background(Color.offWhite)
        .cornerRadius(8)
    }
}

// MARK: - Weekly Stat Card
struct WeeklyStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.primaryCoral)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.textSecondary)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.textPrimary)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Placeholder Views
struct ActivityLogView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Activity Log")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Text("Coming soon...")
                    .foregroundColor(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.offWhite)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct WorkoutLogView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Workout Log")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Text("Coming soon...")
                    .foregroundColor(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.offWhite)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Notifications")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Text("No new notifications")
                    .foregroundColor(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.offWhite)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct AddWorkoutView: View {
    let selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Workout")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Text("Coming soon...")
                    .foregroundColor(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.offWhite)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct WorkoutDetailView: View {
    let workout: ScheduledWorkout
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Workout Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Text(workout.workoutPlan.title)
                    .foregroundColor(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.offWhite)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - Helper Components

struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "#374151"), lineWidth: 4)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.primaryCoral, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.textSecondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.textPrimary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color.primaryCoral)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.textSecondary)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Biometric Card (Stub)
struct BiometricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(Color.textPrimary)
            Text("\(value) \(unit)")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
        }
        .padding()
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Activities View (Stub)
struct ActivitiesView: View {
    @EnvironmentObject var workoutPlanManager: WorkoutPlanManager
    @State private var selectedFilter = "All"
    @State private var showingAddActivity = false
    
    private let filters: [String] = ["All", "Strength", "Cardio", "Flexibility", "Sports"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Activity Summary
                    activitySummarySection
                    
                    // Filter Tabs
                    filterTabsSection
                    
                    // Activity List
                    activityListSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Extra padding for tab bar
            }
            .background(Color.bgPrimary)
            .navigationTitle("Activities")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddActivity = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.primaryCoral)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddActivity) {
            AddActivityView()
        }
    }
    
    private var activitySummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                SummaryCard(
                    title: "Workouts",
                    value: "5",
                    icon: "dumbbell.fill"
                )
                
                SummaryCard(
                    title: "Calories",
                    value: "2,450",
                    icon: "flame.fill"
                )
                
                SummaryCard(
                    title: "Time",
                    value: "4.5h",
                    icon: "clock.fill"
                )
                
                SummaryCard(
                    title: "Streak",
                    value: "7 days",
                    icon: "flame.fill"
                )
            }
        }
    }
    
    private var filterTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.self) { filter in
                    SelectableChip(
                        title: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var activityListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activities")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(sampleActivities, id: \.id) { activity in
                    DetailedActivityCard(activity: activity)
                }
            }
        }
    }
    
    private var sampleActivities: [WorkoutEntry] {
        [
            WorkoutEntry(
                date: Date(),
                exercises: [],
                type: "Strength Training",
                duration: 45,
                mood: "Great",
                difficulty: "Medium",
                calories: 320
            ),
            WorkoutEntry(
                date: Date().addingTimeInterval(-86400),
                exercises: [],
                type: "Cardio",
                duration: 30,
                mood: "Good",
                difficulty: "Easy",
                calories: 280
            ),
            WorkoutEntry(
                date: Date().addingTimeInterval(-172800),
                exercises: [],
                type: "Yoga",
                duration: 60,
                mood: "Excellent",
                difficulty: "Easy",
                calories: 180
            )
        ]
    }
}

// MARK: - Add Activity View
struct AddActivityView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Activity")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Text("Coming soon...")
                    .foregroundColor(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.bgPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - Detailed Activity Card
struct DetailedActivityCard: View {
    let activity: WorkoutEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.primaryCoral)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.type)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("\(activity.duration) min • \(activity.exercises.count) exercises")
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(activity.calories) cal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.textPrimary)
                    
                    Text(activity.date, style: .date)
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }
            
            HStack(spacing: 16) {
                Label(activity.mood, systemImage: "face.smiling")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
                
                Label(activity.difficulty, systemImage: "speedometer")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Start Workout Sheet
struct StartWorkoutSheet: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            VStack {
                if calendarManager.workoutPlans.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 48))
                            .foregroundColor(Color.textSecondary)
                        
                        Text("No Workout Plans Yet")
                            .font(.headline)
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Create a workout plan with your AI Coach first!")
                            .font(.subheadline)
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.bgPrimary)
                } else {
                    List {
                        ForEach(calendarManager.workoutPlans, id: \.id) { plan in
                            Button(action: {
                                // TODO: Start/log this workout
                                dismiss()
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(plan.title)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.textPrimary)
                                    
                                    Text(plan.description)
                                        .font(.subheadline)
                                        .foregroundColor(Color.textSecondary)
                                    
                                    HStack {
                                        Label("\(plan.duration) min", systemImage: "clock")
                                        Spacer()
                                        Label(plan.difficulty, systemImage: "speedometer")
                                    }
                                    .font(.caption)
                                    .foregroundColor(Color.textSecondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Start Workout")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - Log Activity Sheet
struct LogActivitySheet: View {
    @EnvironmentObject var workoutJournal: WorkoutJournal
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(workoutJournal.entries, id: \.id) { entry in
                        VStack(alignment: .leading) {
                            Text(entry.type)
                            Text(entry.date, style: .date).font(.caption)
                        }
                    }
                }
                Button("Add Activity") {
                    // TODO: Add new activity
                }
                .padding()
                .background(Color.primaryCoral)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.top)
            }
            .navigationTitle("Log Activity")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

