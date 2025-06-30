import SwiftUI

// MARK: - Modern Chat Bubble

struct ModernChatBubble: View {
    let message: ChatMessage
    @State private var showActions = false
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                userBubble
            } else {
                botBubble
                Spacer()
            }
        }
        .animation(.spring(), value: showActions)
    }
    
    private var userBubble: some View {
        Text(message.content)
            .font(.body)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 59/255, green: 130/255, blue: 246/255)) // Bright blue
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var botBubble: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main message content
            if message.content.contains("**") {
                // Rich text with formatting
                richTextContent
            } else {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(Color(red: 31/255, green: 41/255, blue: 55/255)) // Dark gray for better contrast
                    .multilineTextAlignment(.leading)
            }
            
            // Action buttons for planning stage
            if message.content.contains("Schedule this") || message.content.contains("Edit something") {
                actionButtons
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 249/255, green: 250/255, blue: 251/255)) // Light gray background
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var richTextContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            let lines = message.content.components(separatedBy: "\n")
            
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                if line.contains("**") {
                    // Bold text (headers)
                    Text(line.replacingOccurrences(of: "**", with: ""))
                        .font(.headline)
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255)) // Very dark for headers
                        .fontWeight(.semibold)
                } else if line.contains("•") {
                    // Bullet points
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255)) // Blue bullet
                            .font(.body)
                        Text(line.replacingOccurrences(of: "• ", with: ""))
                            .font(.body)
                            .foregroundColor(Color(red: 31/255, green: 41/255, blue: 55/255)) // Dark gray text
                    }
                } else if line.contains("✅") || line.contains("📝") || line.contains("❌") {
                    // Action items
                    HStack(alignment: .top, spacing: 8) {
                        Text(line.prefix(2))
                            .font(.body)
                        Text(line.dropFirst(2))
                            .font(.body)
                            .foregroundColor(Color(red: 31/255, green: 41/255, blue: 55/255)) // Dark gray text
                    }
                } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    // Regular text
                    Text(line)
                        .font(.body)
                        .foregroundColor(Color(red: 31/255, green: 41/255, blue: 55/255)) // Dark gray text
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button("✅ Schedule") {
                // Handle schedule action
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 34/255, green: 197/255, blue: 94/255)) // Green
            .cornerRadius(12)
            
            Button("📝 Edit") {
                // Handle edit action
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 59/255, green: 130/255, blue: 246/255)) // Blue
            .cornerRadius(12)
            
            Button("❌ Discard") {
                // Handle discard action
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 239/255, green: 68/255, blue: 68/255)) // Red
            .cornerRadius(12)
        }
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(content: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    let onVoiceInput: () -> Void
    let isRecording: Bool
    let isAuthorized: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Ask me anything about fitness...", text: $text)
                    .font(.body)
                    .foregroundColor(Color(red: 31/255, green: 41/255, blue: 55/255)) // Dark text
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(red: 255/255, green: 255/255, blue: 255/255)) // White background
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(red: 209/255, green: 213/255, blue: 219/255), lineWidth: 1) // Light border
                    )
                
                Button(action: onVoiceInput) {
                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255)) // Blue
                        .frame(width: 40, height: 40)
                }
                .disabled(!isAuthorized)
            }
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(text.isEmpty ? Color(red: 156/255, green: 163/255, blue: 175/255) : Color(red: 59/255, green: 130/255, blue: 246/255)) // Gray when empty, blue when has text
            }
            .disabled(text.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 248/255, green: 250/255, blue: 252/255)) // Very light gray background
    }
} 