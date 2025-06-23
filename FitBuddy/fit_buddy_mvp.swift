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

@main
struct FitBuddyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: ‑ AppDelegate (placeholder for Firebase/etc.)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // TODO: FirebaseApp.configure() when you add Firebase SDK
        return true
    }
}

// MARK: ‑ Root Navigation (Onboarding → Main Tabs)
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasOnboarded = false
    var body: some View {
        if hasOnboarded {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

// MARK: ‑ Onboarding
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasOnboarded = false
    @AppStorage("userGoal") private var goal: String = ""
    @AppStorage("userEquipment") private var equipment: String = ""
    var body: some View {
        VStack(spacing: 20) {
            Text("👋 Welcome to FitBuddy")
                .font(.largeTitle).bold()
            TextField("Your primary fitness goal", text: $goal)
                .textFieldStyle(.roundedBorder)
            TextField("Available equipment (e.g. dumbbells)", text: $equipment)
                .textFieldStyle(.roundedBorder)
            Button(action: { hasOnboarded = true }) {
                Text("Let's Go!").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
    var body: some View {
        VStack(spacing: 12) {
            Text("Daily Streak: \(streak) 🔥")
                .font(.title2)
            Text("Complete a workout today to keep it alive!")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: ‑ Chatbot + Calendar Integration
struct ChatbotView: View {
    @State private var input: String = ""
    @State private var messages: [ChatBubble] = [ChatBubble(text: "Hi! I'm FitBuddy! Ask me for a personalized 3-day workout plan based on your goals and equipment.", isUser: false)]
    @AppStorage("userGoal") private var goal: String = ""
    @AppStorage("userEquipment") private var equipment: String = ""
    private let gpt = GPTService()
    private let calendar = CalendarManager()
    @State private var isLoading = false
    
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
                                Text("Creating your workout plan...")
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
            Divider()
            HStack {
                TextField("Ask for a workout plan...", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isLoading)
                Button("Send") { send() }
                    .disabled(input.isEmpty || isLoading)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
    
    func send() {
        guard !input.isEmpty else { return }
        let userMessage = input
        messages.append(ChatBubble(text: userMessage, isUser: true))
        input = ""
        isLoading = true
        
        // Create a structured prompt template for workout plans
        let contextPrompt = """
        You are FitBuddy, a personal fitness assistant. Generate responses in the following structured format:

        USER CONTEXT:
        - Fitness Goal: \(goal)
        - Available Equipment: \(equipment)
        - User Question: \(userMessage)

        INSTRUCTIONS:
        If the user asks for a workout plan, respond with this EXACT format:

        🏋️ **WORKOUT PLAN**

        **Day 1: [Focus Area]**
        - Exercise 1: [Name] - [Sets] x [Reps] - [Rest]
        - Exercise 2: [Name] - [Sets] x [Reps] - [Rest]
        - Exercise 3: [Name] - [Sets] x [Reps] - [Rest]

        **Day 2: [Focus Area]**
        - Exercise 1: [Name] - [Sets] x [Reps] - [Rest]
        - Exercise 2: [Name] - [Sets] x [Reps] - [Rest]
        - Exercise 3: [Name] - [Sets] x [Reps] - [Rest]

        **Day 3: [Focus Area]**
        - Exercise 1: [Name] - [Sets] x [Reps] - [Rest]
        - Exercise 2: [Name] - [Sets] x [Reps] - [Rest]
        - Exercise 3: [Name] - [Sets] x [Reps] - [Rest]

        💡 **Tips:**
        - [Relevant fitness tip]
        - [Nutrition advice if applicable]

        If the user asks for general fitness advice, respond in a friendly, informative way with clear bullet points.

        Always consider their equipment limitations and fitness goals when creating plans.
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

class GPTService {
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
