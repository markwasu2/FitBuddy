import SwiftUI

struct ModernAICoachView: View {
    @EnvironmentObject var geminiService: GeminiService
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var nutritionViewModel: NutritionViewModel
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: .spacing16) {
                            // Welcome message
                            if messages.isEmpty {
                                welcomeSection
                            }
                            
                            // Chat messages
                            ForEach(messages, id: \.id) { message in
                                ModernChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            // Typing indicator
                            if isTyping {
                                ModernTypingIndicator()
                            }
                        }
                        .padding(.spacing20)
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Input section
                inputSection
            }
            .background(Color.background)
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        messages.removeAll()
                    }
                    .font(.labelMedium)
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
    
    private var welcomeSection: some View {
        VStack(spacing: .spacing24) {
            // AI Coach avatar
            VStack(spacing: .spacing16) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.brandPrimary, .brandSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .overlay(
                        ModernIcon("brain.head.profile", size: 40, color: .textInverse)
                    )
                
                VStack(spacing: .spacing8) {
                    Text("Your AI Fitness Coach")
                        .font(.headlineMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Ask me anything about fitness, nutrition, or your health goals")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Quick suggestions
            VStack(spacing: .spacing12) {
                Text("Quick Questions")
                    .font(.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                VStack(spacing: .spacing8) {
                    ModernSuggestionButton(
                        text: "How can I improve my workout routine?",
                        icon: "dumbbell.fill"
                    ) {
                        sendMessage("How can I improve my workout routine?")
                    }
                    
                    ModernSuggestionButton(
                        text: "What should I eat for muscle building?",
                        icon: "leaf.fill"
                    ) {
                        sendMessage("What should I eat for muscle building?")
                    }
                    
                    ModernSuggestionButton(
                        text: "How many calories should I eat?",
                        icon: "flame.fill"
                    ) {
                        sendMessage("How many calories should I eat?")
                    }
                    
                    ModernSuggestionButton(
                        text: "Create a workout plan for me",
                        icon: "calendar"
                    ) {
                        sendMessage("Create a workout plan for me")
                    }
                }
            }
        }
        .padding(.spacing24)
        .modernCardStyle()
        .padding(.horizontal, .spacing20)
    }
    
    private var inputSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.textTertiary.opacity(0.2))
            
            HStack(spacing: .spacing12) {
                TextField("Ask your AI coach...", text: $messageText, axis: .vertical)
                    .font(.bodyMedium)
                    .padding(.spacing12)
                    .background(Color.surface)
                    .cornerRadius(.radius20)
                    .overlay(
                        RoundedRectangle(cornerRadius: .radius20)
                            .stroke(Color.textTertiary.opacity(0.3), lineWidth: 1)
                    )
                    .lineLimit(1...4)
                
                Button(action: sendMessage) {
                    ModernIcon("arrow.up.circle.fill", size: 32, color: messageText.isEmpty ? .textTertiary : .brandPrimary)
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.spacing16)
        }
        .background(Color.surface)
    }
    
    private func sendMessage(_ text: String? = nil) {
        let messageText = text ?? self.messageText
        guard !messageText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(
            id: UUID(),
            text: messageText,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // Clear input
        self.messageText = ""
        
        // Show typing indicator
        isTyping = true
        
        // Get AI response
        Task {
            let response = await getAIResponse(for: messageText)
            
            await MainActor.run {
                isTyping = false
                
                let aiMessage = ChatMessage(
                    id: UUID(),
                    text: response,
                    isUser: false,
                    timestamp: Date()
                )
                messages.append(aiMessage)
            }
        }
    }
    
    private func getAIResponse(for message: String) async -> String {
        // Create context with user's health data
        let context = createHealthContext()
        let fullPrompt = """
        Context about the user's health and fitness:
        \(context)
        
        User's question: \(message)
        
        Please provide helpful, accurate, and personalized advice about fitness, nutrition, or health goals. 
        Be encouraging and motivational while being practical and safe.
        """
        
        do {
            let response = try await geminiService.generateResponse(prompt: fullPrompt)
            return response
        } catch {
            return "I'm sorry, I'm having trouble connecting right now. Please try again in a moment."
        }
    }
    
    private func createHealthContext() -> String {
        var context = "User's current health data:\n"
        
        // Add nutrition data
        context += "- Daily calories: \(Int(nutritionViewModel.totalCalories)) / \(Int(nutritionViewModel.calorieGoal))\n"
        context += "- Protein: \(Int(nutritionViewModel.entries.reduce(0) { $0 + $1.macros.protein_g }))g\n"
        context += "- Carbs: \(Int(nutritionViewModel.entries.reduce(0) { $0 + $1.macros.carbs_g }))g\n"
        context += "- Fat: \(Int(nutritionViewModel.entries.reduce(0) { $0 + $1.macros.fat_g }))g\n"
        
        // Add fitness data
        context += "- Steps today: \(healthKitManager.stepCount)\n"
        context += "- Active calories: \(Int(healthKitManager.activeCalories))\n"
        context += "- Heart rate: \(healthKitManager.heartRate) bpm\n"
        context += "- Distance: \(String(format: "%.1f", healthKitManager.distance)) km\n"
        
        return context
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - Modern Chat Bubble
struct ModernChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: .spacing4) {
                    Text(message.text)
                        .font(.bodyMedium)
                        .foregroundColor(.textInverse)
                        .padding(.spacing12)
                        .background(Color.brandPrimary)
                        .cornerRadius(.radius16)
                        .cornerRadius(.radius4, corners: [.topLeft, .topRight, .bottomLeft])
                    
                    Text(message.timestamp, style: .time)
                        .font(.captionSmall)
                        .foregroundColor(.textTertiary)
                }
            } else {
                VStack(alignment: .leading, spacing: .spacing4) {
                    HStack(alignment: .top, spacing: .spacing8) {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.brandPrimary, .brandSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 32, height: 32)
                            .overlay(
                                ModernIcon("brain.head.profile", size: 16, color: .textInverse)
                            )
                        
                        Text(message.text)
                            .font(.bodyMedium)
                            .foregroundColor(.textPrimary)
                            .padding(.spacing12)
                            .background(Color.surface)
                            .cornerRadius(.radius16)
                            .cornerRadius(.radius4, corners: [.topLeft, .topRight, .bottomRight])
                    }
                    
                    Text(message.timestamp, style: .time)
                        .font(.captionSmall)
                        .foregroundColor(.textTertiary)
                        .padding(.leading, .spacing40)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Modern Typing Indicator
struct ModernTypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(alignment: .top, spacing: .spacing8) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.brandPrimary, .brandSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)
                    .overlay(
                        ModernIcon("brain.head.profile", size: 16, color: .textInverse)
                    )
                
                HStack(spacing: .spacing4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.textTertiary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animationOffset == CGFloat(index) ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: animationOffset
                            )
                    }
                }
                .padding(.spacing12)
                .background(Color.surface)
                .cornerRadius(.radius16)
                .cornerRadius(.radius4, corners: [.topLeft, .topRight, .bottomRight])
            }
            
            Spacer()
        }
        .onAppear {
            animationOffset = 2
        }
    }
}

// MARK: - Modern Suggestion Button
struct ModernSuggestionButton: View {
    let text: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacing8) {
                ModernIcon(icon, size: 16, color: .brandPrimary)
                
                Text(text)
                    .font(.bodySmall)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.spacing12)
            .background(Color.surface)
            .cornerRadius(.radius12)
            .overlay(
                RoundedRectangle(cornerRadius: .radius12)
                    .stroke(Color.textTertiary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Corner Radius Extension
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