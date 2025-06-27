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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var gptService = GPTService()
    @StateObject private var workoutPlanManager = WorkoutPlanManager()
    @StateObject private var workoutJournal = WorkoutJournal()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(profileManager)
                .environmentObject(gptService)
                .environmentObject(workoutPlanManager)
                .environmentObject(workoutJournal)
                .environmentObject(healthKitManager)
                .environmentObject(notificationManager)
                .preferredColorScheme(.light)
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

struct ChatMessage: Identifiable {
    var id: UUID = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
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
    var body: some View {
        TabView {
            HomeView()
                .tabItem { 
                    Image(systemName: "house.fill")
                }
            ChatbotView()
                .tabItem { 
                    Image(systemName: "message.fill")
                }
            WorkoutCalendarView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                }
        }
        .accentColor(.accentBlue)
    }
}

// MARK: - Home
struct HomeView: View {
    var body: some View {
        FitBuddyDashboard()
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
        }
    }
}

// MARK: - Chatbot + Calendar Integration
struct ChatbotView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var input: String = ""
    @State private var messages: [ChatMessage] = []
    private let gpt = GPTService()
    private let calendar = CalendarManager()
    @StateObject private var speechManager = SpeechRecognitionManager()
    @State private var isLoading = false
    @State private var onboardingStep = 0
    @State private var isOnboarding = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: .spacingM) {
                        ForEach(messages) { message in
                            ModernChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Typing indicator
                        if isLoading {
                            HStack {
                                ModernChatBubble(message: ChatMessage(
                                    id: UUID(),
                                    content: "",
                                    isUser: false,
                                    timestamp: Date()
                                ))
                                .overlay(
                                    HStack(spacing: 4) {
                                        ForEach(0..<3) { index in
                                            Circle()
                                                .fill(Color.textSecondary)
                                                .frame(width: 6, height: 6)
                                                .scaleEffect(1.0)
                                                .animation(
                                                    Animation.easeInOut(duration: 0.6)
                                                        .repeatForever()
                                                        .delay(Double(index) * 0.2),
                                                    value: isLoading
                                                )
                                        }
                                    }
                                )
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, .spacingM)
                    .padding(.top, .spacingM)
                }
                .onChange(of: messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
            }
            
            // Input Bar
            HStack(spacing: .spacingS) {
                HStack(spacing: .spacingS) {
                    TextField("Ask me anything about fitness...", text: $input)
                        .font(.body)
                        .padding(.horizontal, .spacingM)
                        .padding(.vertical, .spacingS)
                        .background(Color(red: 239/255, green: 239/255, blue: 244/255))
                        .cornerRadius(24)
                    
                    Button(action: {
                        if speechManager.isRecording {
                            speechManager.stopRecording()
                            input = speechManager.transcribedText
                        } else {
                            speechManager.startRecording()
                        }
                    }) {
                        Image(systemName: speechManager.isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentBlue)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(!speechManager.isAuthorized)
                }
                
                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(input.isEmpty ? .textSecondary : .accentBlue)
                }
                .disabled(input.isEmpty || isLoading)
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingM)
            .background(Color.bgPrimary)
        }
        .background(Color.bgPrimary)
        .onAppear {
            if !speechManager.isAuthorized {
                speechManager.requestAuthorization()
            }
            startOnboardingIfNeeded()
        }
        .onChange(of: speechManager.transcribedText) { _, newValue in
            if !newValue.isEmpty && !speechManager.isRecording {
                input = newValue
                send()
            }
        }
    }
    
    private func send() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(id: UUID(), content: input, isUser: true, timestamp: Date())
        messages.append(userMessage)
        
        let userInput = input
        input = ""
        isLoading = true
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            let botMessage = ChatMessage(
                id: UUID(),
                content: "Thanks for your message: '\(userInput)'! I'm here to help with your fitness journey.",
                isUser: false,
                timestamp: Date()
            )
            self.messages.append(botMessage)
        }
    }
    
    private func startOnboardingIfNeeded() {
        if !profileManager.isOnboardingComplete || profileManager.name.isEmpty {
            isOnboarding = true
            onboardingStep = 0
            messages = []
            startOnboarding()
        } else {
            isOnboarding = false
        }
    }
    
    private func startOnboarding() {
        // Onboarding logic would go here
    }
}

struct ModernChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.accentBlue)
                    .cornerRadius(18)
            } else {
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.bgSecondary)
                    .cornerRadius(18)
                Spacer()
            }
        }
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
        .onChange(of: selection) { oldValue, newValue in 
            classify() 
        }
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
    @Published var name: String = ""
    @Published var age: Int = 25
    @Published var height: Int = 170
    @Published var weight: Int = 70
    @Published var gender: String = ""
    @Published var fitnessLevel: String = ""
    @Published var equipment: [String] = []
    @Published var goals: [String] = []
    @Published var isOnboardingComplete: Bool = false
    
    init() {
        loadProfile()
    }
    
    func completeOnboarding() {
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func resetProfile() {
        name = ""
        age = 25
        height = 170
        weight = 70
        gender = ""
        fitnessLevel = ""
        equipment = []
        goals = []
        isOnboardingComplete = false
        
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "age")
        UserDefaults.standard.removeObject(forKey: "weight")
        UserDefaults.standard.removeObject(forKey: "height")
        UserDefaults.standard.removeObject(forKey: "gender")
        UserDefaults.standard.removeObject(forKey: "fitnessLevel")
        UserDefaults.standard.removeObject(forKey: "equipment")
        UserDefaults.standard.removeObject(forKey: "goals")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
    
    private func loadProfile() {
        name = UserDefaults.standard.string(forKey: "userName") ?? ""
        age = UserDefaults.standard.integer(forKey: "age")
        height = UserDefaults.standard.integer(forKey: "height")
        weight = UserDefaults.standard.integer(forKey: "weight")
        gender = UserDefaults.standard.string(forKey: "gender") ?? ""
        fitnessLevel = UserDefaults.standard.string(forKey: "fitnessLevel") ?? ""
        equipment = UserDefaults.standard.string(forKey: "equipment")?.components(separatedBy: ",") ?? []
        goals = UserDefaults.standard.string(forKey: "goals")?.components(separatedBy: ",") ?? []
        isOnboardingComplete = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func saveProfile() {
        // Save individual properties to UserDefaults
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(age, forKey: "age")
        UserDefaults.standard.set(height, forKey: "height")
        UserDefaults.standard.set(weight, forKey: "weight")
        UserDefaults.standard.set(gender, forKey: "gender")
        UserDefaults.standard.set(fitnessLevel, forKey: "fitnessLevel")
        UserDefaults.standard.set(equipment.joined(separator: ","), forKey: "equipment")
        UserDefaults.standard.set(goals.joined(separator: ","), forKey: "goals")
        
        // Also save as Profile struct for compatibility
        let profile = Profile(
            name: name,
            age: age,
            height: height,
            weight: weight,
            gender: gender,
            fitnessLevel: fitnessLevel,
            equipment: equipment,
            goals: goals
        )
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "profile")
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
        // Extract goals (as array)
        var foundGoals: [String] = []
        if lowerText.contains("build muscle") || lowerText.contains("muscle") {
            foundGoals.append("Build Muscle")
        }
        if lowerText.contains("lose weight") || lowerText.contains("weight loss") {
            foundGoals.append("Lose Weight")
        }
        if lowerText.contains("maintenance") {
            foundGoals.append("Maintenance")
        }
        if !foundGoals.isEmpty {
            goals = foundGoals
        }
        // Extract equipment (as array)
        var equipmentList: [String] = []
        if lowerText.contains("body-weight") || lowerText.contains("bodyweight") {
            equipmentList.append("Body-weight")
        }
        if lowerText.contains("yoga mat") {
            equipmentList.append("Yoga Mat")
        }
        if lowerText.contains("jump rope") {
            equipmentList.append("Jump Rope")
        }
        if !equipmentList.isEmpty {
            equipment = equipmentList
        }
        return "Profile updated! I've extracted: \(goals.isEmpty ? "" : "Goals: \(goals.joined(separator: ", ")), ")\(weight == 0 ? "" : "Weight: \(weight)lbs, ")\(height == 0 ? "" : "Height: \(height)in, ")\(age == 0 ? "" : "Age: \(age), ")\(gender.isEmpty ? "" : "Gender: \(gender), ")\(fitnessLevel.isEmpty ? "" : "Level: \(fitnessLevel), ")\(equipment.isEmpty ? "" : "Equipment: \(equipment.joined(separator: ", "))")"
    }
}

// MARK: - HealthKit Manager
class HealthKitManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var biometrics = BiometricData()
    
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
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!
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
        
        fetchSteps(predicate: predicate)
        fetchCalories(predicate: predicate)
        fetchDistance(predicate: predicate)
        fetchHeartRate(predicate: predicate)
        fetchWater(predicate: predicate)
    }
    
    private func fetchSteps(predicate: NSPredicate) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            DispatchQueue.main.async {
                self.biometrics.steps = Int(steps)
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchCalories(predicate: NSPredicate) {
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            DispatchQueue.main.async {
                self.biometrics.activeCalories = Int(calories)
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchDistance(predicate: NSPredicate) {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
            DispatchQueue.main.async {
                self.biometrics.distance = distance / 1000 // Convert to km
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchHeartRate(predicate: NSPredicate) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
            let heartRate = result?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
            DispatchQueue.main.async {
                self.biometrics.heartRate = Int(heartRate)
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchWater(predicate: NSPredicate) {
        let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        let query = HKStatisticsQuery(quantityType: waterType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let water = result?.sumQuantity()?.doubleValue(for: HKUnit.liter()) ?? 0
            DispatchQueue.main.async {
                self.biometrics.water = water
            }
        }
        healthStore.execute(query)
    }
}

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("Notification permission granted: \(granted)")
        }
    }
    
    func scheduleWorkoutReminder(date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Workout Reminder"
        content.body = "Time for your workout! 💪"
        content.sound = .default
        
        let triggerDate = Calendar.current.date(byAdding: .minute, value: -15, to: date) ?? date
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate), repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Workout Plan Manager
class WorkoutPlanManager: ObservableObject {
    @Published var currentPlan: String = ""
    @Published var showingCalendarPrompt = false
    
    func setPlan(_ plan: String) {
        currentPlan = plan
        showingCalendarPrompt = true
    }
}

// MARK: - Workout Journal
class WorkoutJournal: ObservableObject {
    @Published var entries: [WorkoutEntry] = []
    private let key = "WorkoutJournalEntries"
    private var entryDict: [String: WorkoutEntry] = [:] // dateKey: entry
    
    init() {
        load()
    }
    
    func entry(for day: Date) -> WorkoutEntry? {
        let key = Self.dateKey(day)
        return entryDict[key]
    }

    func upsert(_ entry: WorkoutEntry) {
        let key = Self.dateKey(entry.date)
        entryDict[key] = entry
        entries = Array(entryDict.values).sorted { $0.date > $1.date }
        save()
    }

    func delete(_ entry: WorkoutEntry) {
        let key = Self.dateKey(entry.date)
        entryDict.removeValue(forKey: key)
        entries = Array(entryDict.values).sorted { $0.date > $1.date }
        save()
    }
    
    func addEntry(_ entry: WorkoutEntry) {
        upsert(entry)
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(Array(entryDict.values))
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let arr = try? JSONDecoder().decode([WorkoutEntry].self, from: data) {
            entryDict = Dictionary(uniqueKeysWithValues: arr.map { (Self.dateKey($0.date), $0) })
            entries = arr.sorted { $0.date > $1.date }
        }
    }

    static func dateKey(_ date: Date) -> String {
        let c = Calendar.current
        let comps = c.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }
}

struct WorkoutEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var exercises: [ExerciseItem]
    var notes: String = ""
    var calories: Int = 0
    var type: String = ""
    var duration: Int = 0
    var mood: Mood = .good
    var difficulty: Difficulty = .moderate
    
    init(date: Date, exercises: [ExerciseItem] = [], notes: String = "", calories: Int = 0, type: String = "", duration: Int = 0, mood: Mood = .good, difficulty: Difficulty = .moderate) {
        self.date = date
        self.exercises = exercises
        self.notes = notes
        self.calories = calories
        self.type = type
        self.duration = duration
        self.mood = mood
        self.difficulty = difficulty
    }
}

struct ExerciseItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double?
    var duration: Int?
    var isCompleted: Bool = false
}

enum Mood: String, CaseIterable, Codable {
    case great = "Great"
    case good = "Good"
    case okay = "Okay"
    case tired = "Tired"
}

enum Difficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"
}

struct Profile: Codable {
    var name: String
    let age: Int
    let height: Int
    let weight: Int
    let gender: String
    let fitnessLevel: String
    let equipment: [String]
    let goals: [String]
}

class GPTService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let model: GenerativeModel
    
    init() {
        let apiKey = "AIzaSyARrgAbADRJL7UU99Q0qAcKdQC18Xxf8Yc"
        model = GenerativeModel(name: "gemini-1.5-flash-latest", apiKey: apiKey)
    }
    
    func sendMessage(_ content: String) async {
        let userMessage = ChatMessage(id: UUID(), content: content, isUser: true, timestamp: Date())
        
        await MainActor.run {
            messages.append(userMessage)
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let response = try await model.generateContent(content)
            let assistantMessage = ChatMessage(id: UUID(), content: response.text ?? "Sorry, I didn't quite catch that – could you rephrase?", isUser: false, timestamp: Date())
            
            await MainActor.run {
                messages.append(assistantMessage)
                isLoading = false
            }
        } catch {
            let errorMessage = ChatMessage(id: UUID(), content: "Sorry, I didn't quite catch that – could you rephrase?", isUser: false, timestamp: Date())
            
            await MainActor.run {
                messages.append(errorMessage)
                isLoading = false
            }
        }
    }
    
    func generateWorkoutPlan(profile: Profile) async -> String {
        let prompt = """
        Create a personalized workout plan for \(profile.name) with the following details:
        - Age: \(profile.age)
        - Height: \(profile.height) cm
        - Weight: \(profile.weight) kg
        - Gender: \(profile.gender)
        - Fitness Level: \(profile.fitnessLevel)
        - Equipment: \(profile.equipment.joined(separator: ", "))
        - Goals: \(profile.goals.joined(separator: ", "))
        
        Rules:
        1. Use ONLY body-weight exercises unless specific equipment is listed
        2. No dumbbells or heavy weights unless explicitly mentioned
        3. Create a 3-day plan with clear day sections
        4. Include sets, reps, and rest periods
        5. Format as readable text, not JSON
        6. Keep it beginner-friendly and safe
        """
        
        do {
            let response = try await model.generateContent(prompt)
            return response.text ?? "Sorry, I couldn't generate a workout plan right now."
        } catch {
            return "Sorry, I couldn't generate a workout plan right now."
        }
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

class CalendarManager: ObservableObject {
    private let store = EKEventStore()
    
    init() {
        requestAccess()
    }
    
    private func requestAccess() {
        // Request calendar access with proper error handling using new iOS 17+ API
        if #available(iOS 17.0, *) {
            store.requestFullAccessToEvents { granted, error in
                if let error = error {
                    print("Error requesting calendar access: \(error)")
                }
                if !granted {
                    print("Calendar access not granted")
                }
            }
        } else {
            // Fallback for older iOS versions
            store.requestAccess(to: .event) { granted, error in
                if let error = error {
                    print("Error requesting calendar access: \(error)")
                }
                if !granted {
                    print("Calendar access not granted")
                }
            }
        }
    }
    
    func addWorkout(title: String, offsetMinutes: Double) throws {
        // Check calendar authorization status using new iOS 17+ API
        let status: EKAuthorizationStatus
        if #available(iOS 17.0, *) {
            status = EKEventStore.authorizationStatus(for: .event)
        } else {
            status = EKEventStore.authorizationStatus(for: .event)
        }
        
        guard status == .authorized || status == .fullAccess else {
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
