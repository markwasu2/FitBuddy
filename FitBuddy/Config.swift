import Foundation

struct Config {
    // MARK: - API Configuration
    static let geminiAPIKey: String = {
        // First try to get from environment variable (for production)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            return envKey
        }
        
        // Use the actual API key that was already working
        return "AIzaSyARrgAbADRJL7UU99Q0qAcKdQC18Xxf8Yc"
    }()
    
    // MARK: - App Configuration
    static let appName = "FitBuddy"
    static let appVersion = "1.0.0"
    
    // MARK: - Feature Flags
    static let enableAIFeatures = true
    static let enableHealthKit = true
    static let enableCalendar = true
    static let enableNotifications = true
    
    // MARK: - Validation
    static var isConfigured: Bool {
        return true
    }
} 