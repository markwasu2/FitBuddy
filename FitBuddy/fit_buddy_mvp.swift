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
    @AppStorage("userWeight") private var weight: String = ""
    @AppStorage("userHeight") private var height: String = ""
    @AppStorage("userAge") private var age: String = ""
    @AppStorage("userGender") private var gender: String = ""
    @AppStorage("userFitnessLevel") private var fitnessLevel: String = ""
    @AppStorage("userBMI") private var bmi: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("👋 Welcome to FitBuddy")
                    .font(.largeTitle).bold()
                
                Text("Let's create your personalized fitness profile")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 15) {
                    TextField("Primary fitness goal (e.g., build muscle, lose weight, improve cardio)", text: $goal)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Available equipment (e.g., dumbbells, resistance bands, none)", text: $equipment)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        TextField("Weight (lbs)", text: $weight)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        
                        TextField("Height (inches)", text: $height)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        TextField("Age", text: $age)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        
                        Picker("Gender", selection: $gender) {
                            Text("Select").tag("")
                            Text("Male").tag("male")
                            Text("Female").tag("female")
                            Text("Other").tag("other")
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                    }
                    
                    Picker("Fitness Level", selection: $fitnessLevel) {
                        Text("Select Level").tag("")
                        Text("Beginner").tag("beginner")
                        Text("Intermediate").tag("intermediate")
                        Text("Advanced").tag("advanced")
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                }
                
                Button(action: { 
                    calculateBMI()
                    hasOnboarded = true 
                }) {
                    Text("Create My Profile").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(goal.isEmpty || equipment.isEmpty || weight.isEmpty || height.isEmpty || age.isEmpty || gender.isEmpty || fitnessLevel.isEmpty)
            }
            .padding()
        }
    }
    
    private func calculateBMI() {
        guard let weightValue = Double(weight),
              let heightValue = Double(height) else { return }
        
        let heightInMeters = heightValue * 0.0254 // Convert inches to meters
        let weightInKg = weightValue * 0.453592 // Convert lbs to kg
        let bmiValue = weightInKg / (heightInMeters * heightInMeters)
        
        bmi = String(format: "%.1f", bmiValue)
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
    @AppStorage("hasCompletedOnboarding") private var hasOnboarded = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Streak Section
                VStack(spacing: 12) {
                    Text("Daily Streak: \(streak) 🔥")
                        .font(.title2)
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
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
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

// MARK: ‑ Chatbot + Calendar Integration
struct ChatbotView: View {
    @State private var input: String = ""
    @State private var messages: [ChatBubble] = [ChatBubble(text: "Hi! I'm FitBuddy! You can speak to me or type. Try saying 'Update my profile' or ask for a workout plan.", isUser: false)]
    @AppStorage("userGoal") private var goal: String = ""
    @AppStorage("userEquipment") private var equipment: String = ""
    @AppStorage("userWeight") private var weight: String = ""
    @AppStorage("userHeight") private var height: String = ""
    @AppStorage("userAge") private var age: String = ""
    @AppStorage("userGender") private var gender: String = ""
    @AppStorage("userFitnessLevel") private var fitnessLevel: String = ""
    @AppStorage("userBMI") private var bmi: String = ""
    private let gpt = GPTService()
    private let calendar = CalendarManager()
    @StateObject private var speechManager = SpeechRecognitionManager()
    @StateObject private var profileManager = ProfileManager()
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
                                Text("Creating your personalized plan...")
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
                
                TextField("Ask for a workout plan or update profile...", text: $input)
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
        }
    }
    
    func send() {
        guard !input.isEmpty else { return }
        let userMessage = input
        messages.append(ChatBubble(text: userMessage, isUser: true))
        input = ""
        isLoading = true
        
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
        - Goal: \(goal)
        - Equipment: \(equipment)
        - Weight: \(weight) lbs
        - Height: \(height) inches
        - Age: \(age) years
        - Gender: \(gender)
        - Fitness Level: \(fitnessLevel)
        - BMI: \(bmi)
        - Question: \(userMessage)

        INSTRUCTIONS:
        1. Keep responses CONCISE (max 200 words for workout plans)
        2. Be SPECIFIC with sets, reps, weights, and rest periods
        3. Consider the user's equipment limitations
        4. Adapt exercises to their fitness level
        5. Account for age, gender, and BMI in recommendations
        6. If they ask about updating their profile, suggest they say "Update my profile" followed by their details

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
    @AppStorage("userGoal") var goal: String = ""
    @AppStorage("userWeight") var weight: String = ""
    @AppStorage("userHeight") var height: String = ""
    @AppStorage("userAge") var age: String = ""
    @AppStorage("userGender") var gender: String = ""
    @AppStorage("userFitnessLevel") var fitnessLevel: String = ""
    @AppStorage("userBMI") var bmi: String = ""
    @AppStorage("userEquipment") var equipment: String = ""
    
    func updateProfile(from text: String) -> String {
        let lowerText = text.lowercased()
        
        // Extract weight
        if let weightMatch = lowerText.range(of: #"(\d+)\s*(?:pounds?|lbs?)"#, options: .regularExpression) {
            let weightString = String(lowerText[weightMatch])
            if let weightValue = weightString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined().first {
                weight = String(weightValue)
            }
        }
        
        // Extract height
        if let heightMatch = lowerText.range(of: #"(\d+)\s*(?:inches?|in)"#, options: .regularExpression) {
            let heightString = String(lowerText[heightMatch])
            if let heightValue = heightString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined().first {
                height = String(heightValue)
            }
        }
        
        // Extract age
        if let ageMatch = lowerText.range(of: #"(\d+)\s*(?:years?|yrs?)"#, options: .regularExpression) {
            let ageString = String(lowerText[ageMatch])
            if let ageValue = ageString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined().first {
                age = String(ageValue)
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
        if !weight.isEmpty && !height.isEmpty {
            calculateBMI()
        }
        
        return "Profile updated! I've extracted: \(goal.isEmpty ? "" : "Goal: \(goal), ")\(weight.isEmpty ? "" : "Weight: \(weight)lbs, ")\(height.isEmpty ? "" : "Height: \(height)in, ")\(age.isEmpty ? "" : "Age: \(age), ")\(gender.isEmpty ? "" : "Gender: \(gender), ")\(fitnessLevel.isEmpty ? "" : "Level: \(fitnessLevel), ")\(equipment.isEmpty ? "" : "Equipment: \(equipment)")"
    }
    
    private func calculateBMI() {
        guard let weightValue = Double(weight),
              let heightValue = Double(height) else { return }
        
        let heightInMeters = heightValue * 0.0254
        let weightInKg = weightValue * 0.453592
        let bmiValue = weightInKg / (heightInMeters * heightInMeters)
        
        bmi = String(format: "%.1f", bmiValue)
    }
}
