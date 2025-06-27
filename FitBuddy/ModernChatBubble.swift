import SwiftUI

// MARK: - Modern Chat Bubble

struct ModernChatBubble: View {
    let message: ChatMessage
    @State private var showActions = false
    
    var body: some View {
        HStack {
            if message.isUser {
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
            .background(Color.accentBlue)
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
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
            }
            
            // Action buttons for planning stage
            if message.content.contains("Schedule this") || message.content.contains("Edit something") {
                actionButtons
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.glyphGray.opacity(0.06))
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
                        .foregroundColor(.textPrimary)
                        .fontWeight(.semibold)
                } else if line.contains("•") {
                    // Bullet points
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.accentBlue)
                            .font(.body)
                        Text(line.replacingOccurrences(of: "• ", with: ""))
                            .font(.body)
                            .foregroundColor(.textPrimary)
                    }
                } else if line.contains("✅") || line.contains("📝") || line.contains("❌") {
                    // Action items
                    HStack(alignment: .top, spacing: 8) {
                        Text(line.prefix(2))
                            .font(.body)
                        Text(line.dropFirst(2))
                            .font(.body)
                            .foregroundColor(.textPrimary)
                    }
                } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    // Regular text
                    Text(line)
                        .font(.body)
                        .foregroundColor(.textPrimary)
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
            .foregroundColor(.accentBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentBlue.opacity(0.1))
            .cornerRadius(12)
            
            Button("📝 Edit") {
                // Handle edit action
            }
            .font(.caption)
            .foregroundColor(.accentMint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentMint.opacity(0.1))
            .cornerRadius(12)
            
            Button("❌ Discard") {
                // Handle discard action
            }
            .font(.caption)
            .foregroundColor(.errorRed)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.errorRed.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var actions: [ChatAction] = []
    
    struct ChatAction {
        let title: String
        let action: () -> Void
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(red: 239/255, green: 239/255, blue: 244/255))
                    .cornerRadius(24)
                
                Button(action: onVoiceInput) {
                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accentBlue)
                        .frame(width: 40, height: 40)
                }
                .disabled(!isAuthorized)
            }
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(text.isEmpty ? .textSecondary : .accentBlue)
            }
            .disabled(text.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.bgPrimary)
    }
} 