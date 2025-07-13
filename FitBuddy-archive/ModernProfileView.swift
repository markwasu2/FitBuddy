import SwiftUI

struct ModernProfileView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var nutritionViewModel: NutritionViewModel
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing24) {
                    // Profile header
                    profileHeaderSection
                    
                    // Stats overview
                    statsOverviewSection
                    
                    // Goals and achievements
                    goalsSection
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Settings
                    settingsSection
                }
                .padding(.horizontal, .spacing20)
            }
            .background(Color.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditProfile = true
                    }
                    .font(.labelMedium)
                    .foregroundColor(.brandPrimary)
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                ModernEditProfileView()
            }
            .sheet(isPresented: $showingSettings) {
                ModernSettingsView()
            }
        }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: .spacing20) {
            // Profile picture and name
            VStack(spacing: .spacing16) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.brandPrimary, .brandSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                    .overlay(
                        ModernIcon("person.fill", size: 50, color: .textInverse)
                    )
                
                VStack(spacing: .spacing4) {
                    Text(profileManager.userName.isEmpty ? "Peregrine User" : profileManager.userName)
                        .font(.headlineMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text(profileManager.fitnessGoal.rawValue)
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                }
            }
            
            // Member since
            HStack(spacing: .spacing8) {
                ModernIcon("calendar", size: 16, color: .textTertiary)
                
                Text("Member since \(profileManager.joinDate, style: .date)")
                    .font(.captionMedium)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(.spacing24)
        .modernCardStyle()
    }
    
    private var statsOverviewSection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("Your Stats", subtitle: "This week's progress")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: .spacing16) {
                ModernMetricCard(
                    title: "Workouts",
                    value: "\(healthKitManager.workouts.count)",
                    subtitle: "This week",
                    icon: "dumbbell.fill",
                    color: .brandSuccess
                )
                
                ModernMetricCard(
                    title: "Steps",
                    value: "\(healthKitManager.stepCount)",
                    subtitle: "Today",
                    icon: "figure.walk",
                    color: .brandPrimary
                )
                
                ModernMetricCard(
                    title: "Calories",
                    value: "\(Int(nutritionViewModel.totalCalories))",
                    subtitle: "Consumed today",
                    icon: "flame.fill",
                    color: .brandWarning
                )
                
                ModernMetricCard(
                    title: "Active Time",
                    value: "\(Int(healthKitManager.activeMinutes)) min",
                    subtitle: "Today",
                    icon: "clock.fill",
                    color: .brandSecondary
                )
            }
        }
    }
    
    private var goalsSection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("Goals & Achievements", subtitle: "Track your progress")
            
            VStack(spacing: .spacing12) {
                // Current goals
                ModernGoalCard(
                    title: "Weekly Workouts",
                    current: healthKitManager.workouts.count,
                    target: 5,
                    icon: "dumbbell.fill",
                    color: .brandSuccess
                )
                
                ModernGoalCard(
                    title: "Daily Steps",
                    current: healthKitManager.stepCount,
                    target: 10000,
                    icon: "figure.walk",
                    color: .brandPrimary
                )
                
                ModernGoalCard(
                    title: "Calorie Goal",
                    current: Int(nutritionViewModel.totalCalories),
                    target: Int(nutritionViewModel.calorieGoal),
                    icon: "flame.fill",
                    color: .brandWarning
                )
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("Quick Actions", subtitle: "Manage your profile")
            
            VStack(spacing: .spacing12) {
                ModernProfileActionButton(
                    title: "Edit Profile",
                    subtitle: "Update your information",
                    icon: "person.circle.fill",
                    color: .brandPrimary
                ) {
                    showingEditProfile = true
                }
                
                ModernProfileActionButton(
                    title: "View Achievements",
                    subtitle: "See your milestones",
                    icon: "trophy.fill",
                    color: .brandWarning
                ) {
                    // Navigate to achievements
                }
                
                ModernProfileActionButton(
                    title: "Export Data",
                    subtitle: "Download your health data",
                    icon: "square.and.arrow.up.fill",
                    color: .brandSuccess
                ) {
                    // Export data
                }
            }
        }
    }
    
    private var settingsSection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("Settings", subtitle: "App preferences")
            
            VStack(spacing: .spacing12) {
                ModernProfileActionButton(
                    title: "App Settings",
                    subtitle: "Notifications, privacy, and more",
                    icon: "gear",
                    color: .textSecondary
                ) {
                    showingSettings = true
                }
                
                ModernProfileActionButton(
                    title: "Health Data",
                    subtitle: "Manage HealthKit permissions",
                    icon: "heart.fill",
                    color: .brandError
                ) {
                    // Health data settings
                }
                
                ModernProfileActionButton(
                    title: "Help & Support",
                    subtitle: "Get help and contact support",
                    icon: "questionmark.circle.fill",
                    color: .brandSecondary
                ) {
                    // Help and support
                }
            }
        }
    }
}

// MARK: - Modern Goal Card
struct ModernGoalCard: View {
    let title: String
    let current: Int
    let target: Int
    let icon: String
    let color: Color
    
    private var progress: Double {
        min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        HStack(spacing: .spacing12) {
            ModernIcon(icon, size: 20, color: color)
            
            VStack(alignment: .leading, spacing: .spacing4) {
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text("\(current) / \(target)")
                    .font(.captionMedium)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            ModernProgressRing(
                progress: progress,
                size: 40,
                lineWidth: 4,
                color: color
            )
        }
        .padding(.spacing12)
        .modernCardStyle()
    }
}

// MARK: - Modern Profile Action Button
struct ModernProfileActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacing12) {
                ModernIcon(icon, size: 20, color: color)
                
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
                
                ModernIcon("chevron.right", size: 16, color: .textTertiary)
            }
            .padding(.spacing12)
            .modernCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Edit Profile View
struct ModernEditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileManager: ProfileManager
    @State private var userName = ""
    @State private var selectedGoal = FitnessGoal.loseWeight
    @State private var age = ""
    @State private var weight = ""
    @State private var height = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing24) {
                    Text("Edit Profile")
                        .font(.headlineMedium)
                        .foregroundColor(.textPrimary)
                    
                    VStack(spacing: .spacing16) {
                        // Basic info
                        VStack(alignment: .leading, spacing: .spacing8) {
                            Text("Name")
                                .font(.labelMedium)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            
                            TextField("Your name", text: $userName)
                                .modernInputStyle()
                        }
                        
                        // Fitness goal
                        VStack(alignment: .leading, spacing: .spacing8) {
                            Text("Fitness Goal")
                                .font(.labelMedium)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            
                            Picker("Fitness Goal", selection: $selectedGoal) {
                                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                                    Text(goal.rawValue).tag(goal)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .modernInputStyle()
                        }
                        
                        // Physical stats
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
                    
                    Button("Save Changes") {
                        // Save profile changes
                        profileManager.userName = userName
                        profileManager.fitnessGoal = selectedGoal
                        dismiss()
                    }
                    .modernButtonStyle()
                }
                .padding(.spacing24)
            }
            .background(Color.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.labelMedium)
                    .foregroundColor(.brandPrimary)
                }
            }
            .onAppear {
                userName = profileManager.userName
                selectedGoal = profileManager.fitnessGoal
            }
        }
    }
}

// MARK: - Modern Settings View
struct ModernSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var healthKitSync = true
    @State private var darkMode = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing24) {
                    Text("Settings")
                        .font(.headlineMedium)
                        .foregroundColor(.textPrimary)
                    
                    VStack(spacing: .spacing16) {
                        // Notifications
                        ModernSettingsRow(
                            title: "Notifications",
                            subtitle: "Get reminders and updates",
                            icon: "bell.fill",
                            color: .brandPrimary
                        ) {
                            notificationsEnabled.toggle()
                        }
                        .overlay(
                            Toggle("", isOn: $notificationsEnabled)
                                .labelsHidden()
                        )
                        
                        // HealthKit Sync
                        ModernSettingsRow(
                            title: "HealthKit Sync",
                            subtitle: "Sync with Apple Health",
                            icon: "heart.fill",
                            color: .brandError
                        ) {
                            healthKitSync.toggle()
                        }
                        .overlay(
                            Toggle("", isOn: $healthKitSync)
                                .labelsHidden()
                        )
                        
                        // Dark Mode
                        ModernSettingsRow(
                            title: "Dark Mode",
                            subtitle: "Use dark appearance",
                            icon: "moon.fill",
                            color: .brandSecondary
                        ) {
                            darkMode.toggle()
                        }
                        .overlay(
                            Toggle("", isOn: $darkMode)
                                .labelsHidden()
                        )
                    }
                    
                    Button("Save Settings") {
                        // Save settings
                        dismiss()
                    }
                    .modernButtonStyle()
                }
                .padding(.spacing24)
            }
            .background(Color.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.labelMedium)
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
}

// MARK: - Modern Settings Row
struct ModernSettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacing12) {
                ModernIcon(icon, size: 20, color: color)
                
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
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Fitness Goal Enum
enum FitnessGoal: String, CaseIterable {
    case loseWeight = "Lose Weight"
    case buildMuscle = "Build Muscle"
    case stayFit = "Stay Fit"
    case improveEndurance = "Improve Endurance"
    case generalHealth = "General Health"
} 