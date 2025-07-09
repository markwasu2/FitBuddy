import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var currentStep = 0
    @State private var userName = ""
    @State private var selectedGoal = FitnessGoal.loseWeight
    @State private var age = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var selectedActivityLevel = ActivityLevel.moderate
    
    enum ActivityLevel: String, CaseIterable {
        case sedentary = "Sedentary"
        case light = "Light"
        case moderate = "Moderate"
        case active = "Active"
        case veryActive = "Very Active"
        
        var description: String {
            switch self {
            case .sedentary: return "Little or no exercise"
            case .light: return "Light exercise 1-3 days/week"
            case .moderate: return "Moderate exercise 3-5 days/week"
            case .active: return "Hard exercise 6-7 days/week"
            case .veryActive: return "Very hard exercise, physical job"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                
                // Content
                TabView(selection: $currentStep) {
                    welcomeStep
                        .tag(0)
                    
                    profileStep
                        .tag(1)
                    
                    goalsStep
                        .tag(2)
                    
                    activityStep
                        .tag(3)
                    
                    permissionsStep
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation buttons
                navigationButtons
            }
            .background(Color.background)
            .navigationBarHidden(true)
        }
    }
    
    private var progressIndicator: some View {
        VStack(spacing: .spacing16) {
            HStack(spacing: .spacing8) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.brandPrimary : Color.textTertiary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            
            Text("Step \(currentStep + 1) of 5")
                .font(.captionMedium)
                .foregroundColor(.textSecondary)
        }
        .padding(.spacing24)
    }
    
    private var welcomeStep: some View {
        VStack(spacing: .spacing32) {
            Spacer()
            
            // App logo and title
            VStack(spacing: .spacing24) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.brandPrimary, .brandSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                    .overlay(
                        ModernIcon("heart.fill", size: 60, color: .textInverse)
                    )
                
                VStack(spacing: .spacing12) {
                    Text("Welcome to FitBuddy")
                        .font(.displaySmall)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Your AI-powered fitness companion")
                        .font(.titleMedium)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Features
            VStack(spacing: .spacing16) {
                ModernFeatureRow(
                    icon: "camera.fill",
                    title: "Snap & Track Nutrition",
                    subtitle: "AI-powered food recognition"
                )
                
                ModernFeatureRow(
                    icon: "dumbbell.fill",
                    title: "Personalized Workouts",
                    subtitle: "Custom plans for your goals"
                )
                
                ModernFeatureRow(
                    icon: "brain.head.profile",
                    title: "AI Fitness Coach",
                    subtitle: "Get personalized advice"
                )
                
                ModernFeatureRow(
                    icon: "heart.fill",
                    title: "HealthKit Integration",
                    subtitle: "Sync with Apple Health"
                )
            }
            
            Spacer()
        }
        .padding(.spacing24)
    }
    
    private var profileStep: some View {
        VStack(spacing: .spacing32) {
            VStack(spacing: .spacing16) {
                Text("Tell us about yourself")
                    .font(.headlineMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text("This helps us personalize your experience")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: .spacing16) {
                VStack(alignment: .leading, spacing: .spacing8) {
                    Text("Name")
                        .font(.labelMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Your name", text: $userName)
                        .modernInputStyle()
                }
                
                HStack(spacing: .spacing12) {
                    VStack(alignment: .leading, spacing: .spacing8) {
                        Text("Age")
                            .font(.labelMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        TextField("25", text: $age)
                            .modernInputStyle()
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: .spacing8) {
                        Text("Weight (lbs)")
                            .font(.labelMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        TextField("150", text: $weight)
                            .modernInputStyle()
                            .keyboardType(.numberPad)
                    }
                }
                
                VStack(alignment: .leading, spacing: .spacing8) {
                    Text("Height (inches)")
                        .font(.labelMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("70", text: $height)
                        .modernInputStyle()
                        .keyboardType(.numberPad)
                }
            }
            
            Spacer()
        }
        .padding(.spacing24)
    }
    
    private var goalsStep: some View {
        VStack(spacing: .spacing32) {
            VStack(spacing: .spacing16) {
                Text("What's your main goal?")
                    .font(.headlineMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text("We'll create a personalized plan for you")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: .spacing12) {
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    ModernGoalOptionButton(
                        goal: goal,
                        isSelected: selectedGoal == goal
                    ) {
                        selectedGoal = goal
                    }
                }
            }
            
            Spacer()
        }
        .padding(.spacing24)
    }
    
    private var activityStep: some View {
        VStack(spacing: .spacing32) {
            VStack(spacing: .spacing16) {
                Text("How active are you?")
                    .font(.headlineMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text("This helps calculate your calorie needs")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: .spacing12) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    ModernActivityOptionButton(
                        level: level,
                        isSelected: selectedActivityLevel == level
                    ) {
                        selectedActivityLevel = level
                    }
                }
            }
            
            Spacer()
        }
        .padding(.spacing24)
    }
    
    private var permissionsStep: some View {
        VStack(spacing: .spacing32) {
            VStack(spacing: .spacing16) {
                Text("Connect your health data")
                    .font(.headlineMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text("FitBuddy works best when connected to Apple Health")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: .spacing16) {
                ModernPermissionCard(
                    title: "Health Data",
                    subtitle: "Steps, calories, heart rate",
                    icon: "heart.fill",
                    color: .brandError
                )
                
                ModernPermissionCard(
                    title: "Camera Access",
                    subtitle: "Food recognition and photos",
                    icon: "camera.fill",
                    color: .brandPrimary
                )
                
                ModernPermissionCard(
                    title: "Notifications",
                    subtitle: "Reminders and updates",
                    icon: "bell.fill",
                    color: .brandWarning
                )
            }
            
            Spacer()
        }
        .padding(.spacing24)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: .spacing16) {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }
                .modernSecondaryButtonStyle()
            }
            
            Button(currentStep == 4 ? "Get Started" : "Next") {
                if currentStep == 4 {
                    completeOnboarding()
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }
            }
            .modernButtonStyle()
        }
        .padding(.spacing24)
    }
    
    private func completeOnboarding() {
        // Save user data
        profileManager.userName = userName
        profileManager.fitnessGoal = selectedGoal
        profileManager.isOnboardingComplete = true
        
        // Additional setup can be done here
    }
}

// MARK: - Modern Feature Row
struct ModernFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: .spacing12) {
            ModernIcon(icon, size: 24, color: .brandPrimary)
            
            VStack(alignment: .leading, spacing: .spacing2) {
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.captionMedium)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(.spacing12)
        .modernCardStyle()
    }
}

// MARK: - Modern Goal Option Button
struct ModernGoalOptionButton: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacing12) {
                ModernIcon(goalIcon, size: 20, color: isSelected ? .textInverse : .brandPrimary)
                
                VStack(alignment: .leading, spacing: .spacing4) {
                    Text(goal.rawValue)
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .textInverse : .textPrimary)
                    
                    Text(goalDescription)
                        .font(.captionMedium)
                        .foregroundColor(isSelected ? .textInverse.opacity(0.8) : .textSecondary)
                }
                
                Spacer()
            }
            .padding(.spacing16)
            .background(
                RoundedRectangle(cornerRadius: .radius12)
                    .fill(isSelected ? Color.brandPrimary : Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: .radius12)
                            .stroke(isSelected ? Color.brandPrimary : Color.textTertiary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var goalIcon: String {
        switch goal {
        case .loseWeight: return "arrow.down.circle.fill"
        case .buildMuscle: return "dumbbell.fill"
        case .stayFit: return "heart.fill"
        case .improveEndurance: return "figure.run"
        case .generalHealth: return "cross.fill"
        }
    }
    
    private var goalDescription: String {
        switch goal {
        case .loseWeight: return "Reduce body weight and fat"
        case .buildMuscle: return "Increase muscle mass and strength"
        case .stayFit: return "Maintain current fitness level"
        case .improveEndurance: return "Build cardiovascular fitness"
        case .generalHealth: return "Improve overall health"
        }
    }
}

// MARK: - Modern Activity Option Button
struct ModernActivityOptionButton: View {
    let level: OnboardingView.ActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: .spacing8) {
                HStack {
                    Text(level.rawValue)
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .textInverse : .textPrimary)
                    
                    Spacer()
                    
                    if isSelected {
                        ModernIcon("checkmark.circle.fill", size: 20, color: .textInverse)
                    }
                }
                
                Text(level.description)
                    .font(.captionMedium)
                    .foregroundColor(isSelected ? .textInverse.opacity(0.8) : .textSecondary)
            }
            .padding(.spacing16)
            .background(
                RoundedRectangle(cornerRadius: .radius12)
                    .fill(isSelected ? Color.brandPrimary : Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: .radius12)
                            .stroke(isSelected ? Color.brandPrimary : Color.textTertiary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Permission Card
struct ModernPermissionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: .spacing12) {
            ModernIcon(icon, size: 20, color: color)
            
            VStack(alignment: .leading, spacing: .spacing4) {
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.captionMedium)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            ModernIcon("checkmark.circle.fill", size: 20, color: .brandSuccess)
        }
        .padding(.spacing16)
        .modernCardStyle()
    }
} 