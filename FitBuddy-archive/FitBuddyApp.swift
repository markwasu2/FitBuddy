import SwiftUI
import HealthKit
import CoreData

// MARK: - Modern Design System
extension Color {
    // Primary Brand Colors
    static let brandPrimary = Color(hex: "#007AFF")      // iOS Blue
    static let brandSecondary = Color(hex: "#5856D6")    // Purple
    static let brandSuccess = Color(hex: "#34C759")      // Green
    static let brandWarning = Color(hex: "#FF9500")      // Orange
    static let brandError = Color(hex: "#FF3B30")        // Red
    
    // Neutral Colors
    static let background = Color(hex: "#F8F9FA")        // Light Gray Background
    static let surface = Color.white
    static let cardBackground = Color.white
    
    // Text Colors
    static let textPrimary = Color(hex: "#1A1A1A")      // Deep Black
    static let textSecondary = Color(hex: "#6C757D")     // Medium Gray
    static let textTertiary = Color(hex: "#ADB5BD")      // Light Gray
    static let textInverse = Color.white
    
    // Interactive Colors
    static let buttonPrimary = Color(hex: "#007AFF")
    static let buttonSecondary = Color(hex: "#F8F9FA")
    static let buttonDisabled = Color(hex: "#E9ECEF")
    
    // System Colors (for compatibility)
    static let accent = Color(hex: "#007AFF")            // iOS Blue
    static let error = Color(hex: "#FF3B30")             // Red
    static let secondary = Color(hex: "#5856D6")         // Purple
    static let success = Color(hex: "#34C759")           // Green
    static let info = Color(hex: "#17A2B8")              // Info Blue
    static let warning = Color(hex: "#FF9500")           // Orange
    
    // Shadows
    static let shadowLight = Color.black.opacity(0.05)
    static let shadowMedium = Color.black.opacity(0.1)
    static let shadowHeavy = Color.black.opacity(0.15)
    
    // Gradients
    static let gradientStart = Color(hex: "#007AFF")
    static let gradientEnd = Color(hex: "#5856D6")
    
    // Nutrition Colors
    static let proteinColor = Color(hex: "#007AFF")
    static let carbsColor = Color(hex: "#34C759")
    static let fatColor = Color(hex: "#FF9500")
    static let fiberColor = Color(hex: "#5856D6")
}

extension Font {
    // Typography System
    static let displayLarge = Font.system(size: 48, weight: .bold, design: .default)
    static let displayMedium = Font.system(size: 36, weight: .bold, design: .default)
    static let displaySmall = Font.system(size: 24, weight: .bold, design: .default)
    
    static let headlineLarge = Font.system(size: 32, weight: .bold, design: .default)
    static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .default)
    static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .default)
    
    static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)
    static let titleMedium = Font.system(size: 20, weight: .semibold, design: .default)
    static let titleSmall = Font.system(size: 18, weight: .semibold, design: .default)
    
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 15, weight: .regular, design: .default)
    
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 12, weight: .medium, design: .default)
    
    static let captionLarge = Font.system(size: 12, weight: .regular, design: .default)
    static let captionMedium = Font.system(size: 11, weight: .regular, design: .default)
    static let captionSmall = Font.system(size: 10, weight: .regular, design: .default)
}

extension CGFloat {
    // Spacing System
    static let spacing2: CGFloat = 2
    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacingS: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacingM: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    static let spacing40: CGFloat = 40
    static let spacing48: CGFloat = 48
    static let spacing56: CGFloat = 56
    static let spacing64: CGFloat = 64
    
    // Border Radius
    static let radius4: CGFloat = 4
    static let radius8: CGFloat = 8
    static let radius12: CGFloat = 12
    static let radius16: CGFloat = 16
    static let radius20: CGFloat = 20
    static let radius24: CGFloat = 24
    static let radius32: CGFloat = 32
}

// MARK: - Modern View Modifiers
extension View {
    func modernCardStyle() -> some View {
        self
            .background(Color.surface)
            .cornerRadius(CGFloat.radius16)
            .shadow(color: Color.shadowLight, radius: 8, x: 0, y: 2)
    }
    
    func modernButtonStyle() -> some View {
        self
            .font(.labelLarge)
            .foregroundColor(.textInverse)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.buttonPrimary)
            .cornerRadius(CGFloat.radius12)
    }
    
    func modernSecondaryButtonStyle() -> some View {
        self
            .font(.labelLarge)
            .foregroundColor(.buttonPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.buttonSecondary)
            .cornerRadius(CGFloat.radius12)
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat.radius12)
                    .stroke(Color.buttonPrimary, lineWidth: 1)
            )
    }
    
    func modernInputStyle() -> some View {
        self
            .font(.bodyMedium)
            .foregroundColor(.textPrimary)
            .padding(.spacing16)
            .background(Color.surface)
            .cornerRadius(CGFloat.radius12)
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat.radius12)
                    .stroke(Color.textTertiary, lineWidth: 1)
            )
    }
    
    func cleanCardStyle() -> some View {
        self
            .background(Color.surface)
            .cornerRadius(CGFloat.radius12)
            .shadow(color: Color.shadowLight, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Modern Icon System
struct ModernIcon: View {
    let name: String
    let size: CGFloat
    let color: Color
    
    init(_ name: String, size: CGFloat = 24, color: Color = .textPrimary) {
        self.name = name
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .medium))
            .foregroundColor(color)
    }
}

// MARK: - Clean Icon System (for compatibility)
struct CleanIcon: View {
    let name: String
    let size: CGFloat
    let color: Color
    
    init(_ name: String, size: CGFloat = 24, color: Color = .textPrimary) {
        self.name = name
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .medium))
            .foregroundColor(color)
    }
}

// MARK: - Clean Section Header (for compatibility)
struct CleanSectionHeader: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
    }
}

// MARK: - Modern Progress Ring
struct ModernProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let color: Color
    let showPercentage: Bool
    
    init(progress: Double, size: CGFloat = 120, lineWidth: CGFloat = 8, color: Color = .brandPrimary, showPercentage: Bool = false) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.color = color
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.textTertiary.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Modern Metric Card
struct ModernMetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: String?
    
    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color = .brandPrimary, trend: String? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trend = trend
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            HStack {
                ModernIcon(icon, size: 20, color: color)
                Spacer()
                if let trend = trend {
                    Text(trend)
                        .font(.captionMedium)
                        .foregroundColor(.brandSuccess)
                }
            }
            
            VStack(alignment: .leading, spacing: .spacing4) {
                Text(value)
                    .font(.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text(title)
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.captionMedium)
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding(.spacing16)
        .modernCardStyle()
    }
}

// MARK: - Modern Section Header
struct ModernSectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(_ title: String, subtitle: String? = nil, action: (() -> Void)? = nil, actionTitle: String? = "See All") {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: .spacing4) {
                Text(title)
                    .font(.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.labelMedium)
                        .foregroundColor(.brandPrimary)
                }
            }
        }
        .padding(.horizontal, .spacing20)
        .padding(.vertical, .spacing12)
    }
}

// MARK: - Modern Empty State
struct ModernEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(icon: String, title: String, subtitle: String, action: (() -> Void)? = nil, actionTitle: String? = "Get Started") {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: .spacing32) {
            ModernIcon(icon, size: 64, color: .textTertiary)
            
            VStack(spacing: .spacing12) {
                Text(title)
                    .font(.headlineMedium)
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle, action: action)
                    .modernButtonStyle()
                    .padding(.horizontal, .spacing32)
            }
        }
        .padding(.spacing48)
    }
}

// MARK: - App Entry Point
@main
struct PeregrineApp: App {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var workoutPlanManager = WorkoutPlanManager()
    @StateObject private var nutritionViewModel = NutritionViewModel()
    @StateObject private var geminiService = GeminiService()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var workoutJournal = WorkoutJournal()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(healthKitManager)
                .environmentObject(profileManager)
                .environmentObject(workoutPlanManager)
                .environmentObject(nutritionViewModel)
                .environmentObject(geminiService)
                .environmentObject(calendarManager)
                .environmentObject(workoutJournal)
                .onAppear {
                    healthKitManager.requestAuthorization()
                }
        }
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
                .preferredColorScheme(.light)
        }
    }
} 