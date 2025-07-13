import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var nutritionViewModel: NutritionViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    VStack(spacing: 4) {
                        ModernIcon(selectedTab == 0 ? "house.fill" : "house", size: 20, color: selectedTab == 0 ? .brandPrimary : .textSecondary)
                        Text("Dashboard")
                            .font(.captionSmall)
                            .foregroundColor(selectedTab == 0 ? .brandPrimary : .textSecondary)
                    }
                }
                .tag(0)
            
            // Nutrition Tab
            ModernNutritionView()
                .tabItem {
                    VStack(spacing: 4) {
                        ModernIcon(selectedTab == 1 ? "camera.fill" : "camera", size: 20, color: selectedTab == 1 ? .brandPrimary : .textSecondary)
                        Text("Nutrition")
                            .font(.captionSmall)
                            .foregroundColor(selectedTab == 1 ? .brandPrimary : .textSecondary)
                    }
                }
                .tag(1)
            
            // Workouts Tab
            ModernWorkoutView()
                .tabItem {
                    VStack(spacing: 4) {
                        ModernIcon(selectedTab == 2 ? "dumbbell.fill" : "dumbbell", size: 20, color: selectedTab == 2 ? .brandPrimary : .textSecondary)
                        Text("Workouts")
                            .font(.captionSmall)
                            .foregroundColor(selectedTab == 2 ? .brandPrimary : .textSecondary)
                    }
                }
                .tag(2)
            
            // AI Coach Tab
            ModernAICoachView()
                .tabItem {
                    VStack(spacing: 4) {
                        ModernIcon(selectedTab == 3 ? "brain.head.profile" : "brain", size: 20, color: selectedTab == 3 ? .brandPrimary : .textSecondary)
                        Text("AI Coach")
                            .font(.captionSmall)
                            .foregroundColor(selectedTab == 3 ? .brandPrimary : .textSecondary)
                    }
                }
                .tag(3)
            
            // Profile Tab
            ModernProfileView()
                .tabItem {
                    VStack(spacing: 4) {
                        ModernIcon(selectedTab == 4 ? "person.fill" : "person", size: 20, color: selectedTab == 4 ? .brandPrimary : .textSecondary)
                        Text("Profile")
                            .font(.captionSmall)
                            .foregroundColor(selectedTab == 4 ? .brandPrimary : .textSecondary)
                    }
                }
                .tag(4)
        }
        .accentColor(.brandPrimary)
        .background(Color.background)
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Modern Dashboard View
struct DashboardView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var nutritionViewModel: NutritionViewModel
    @State private var showingGoalSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing24) {
                    // Header with greeting
                    headerSection
                    
                    // Daily progress overview
                    dailyProgressSection
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Recent activities
                    recentActivitiesSection
                    
                    // Nutrition summary
                    nutritionSummarySection
                }
                .padding(.horizontal, .spacing20)
            }
            .background(Color.background)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingGoalSettings = true
                    }
                    .font(.labelMedium)
                    .foregroundColor(.brandPrimary)
                }
            }
            .sheet(isPresented: $showingGoalSettings) {
                GoalSettingsView()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            Text("Good \(timeOfDayGreeting)")
                .font(.headlineLarge)
                .foregroundColor(.textPrimary)
            
            Text("Let's crush your fitness goals today!")
                .font(.bodyLarge)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, .spacing16)
    }
    
    private var dailyProgressSection: some View {
        VStack(spacing: .spacing20) {
            ModernSectionHeader("Today's Progress", subtitle: "Your daily health metrics")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: .spacing16) {
                ModernMetricCard(
                    title: "Steps",
                    value: "\(healthKitManager.stepCount)",
                    subtitle: "Goal: 10,000",
                    icon: "figure.walk",
                    color: .brandSuccess,
                    trend: "+12%"
                )
                
                ModernMetricCard(
                    title: "Calories",
                    value: "\(Int(healthKitManager.activeCalories))",
                    subtitle: "Active calories",
                    icon: "flame.fill",
                    color: .brandWarning,
                    trend: "+8%"
                )
                
                ModernMetricCard(
                    title: "Heart Rate",
                    value: "\(healthKitManager.heartRate) bpm",
                    subtitle: "Current",
                    icon: "heart.fill",
                    color: .brandError
                )
                
                ModernMetricCard(
                    title: "Distance",
                    value: "\(String(format: "%.1f", healthKitManager.distance)) km",
                    subtitle: "Today",
                    icon: "location.fill",
                    color: .brandSecondary
                )
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("Quick Actions", subtitle: "Log your activities")
            
            HStack(spacing: .spacing12) {
                QuickActionButton(
                    title: "Log Food",
                    subtitle: "Camera",
                    icon: "camera.fill",
                    color: .brandPrimary
                ) {
                    // Navigate to nutrition
                }
                
                QuickActionButton(
                    title: "Log Workout",
                    subtitle: "Exercise",
                    icon: "dumbbell.fill",
                    color: .brandSuccess
                ) {
                    // Navigate to workouts
                }
                
                QuickActionButton(
                    title: "AI Coach",
                    subtitle: "Get Advice",
                    icon: "brain.head.profile",
                    color: .brandSecondary
                ) {
                    // Navigate to AI coach
                }
            }
        }
    }
    
    private var recentActivitiesSection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("Recent Activities", subtitle: "Your latest workouts and meals")
            
            if nutritionViewModel.entries.isEmpty && healthKitManager.workouts.isEmpty {
                ModernEmptyState(
                    icon: "clock",
                    title: "No Recent Activities",
                    subtitle: "Start logging your meals and workouts to see them here",
                    action: {
                        // Navigate to nutrition
                    },
                    actionTitle: "Log Your First Meal"
                )
            } else {
                VStack(spacing: .spacing12) {
                    ForEach(Array(nutritionViewModel.entries.prefix(3)), id: \.id) { entry in
                        ActivityRow(
                            title: entry.foodName,
                            subtitle: "\(Int(entry.calories)) calories",
                            icon: "camera.fill",
                            color: .brandPrimary,
                            time: entry.timestamp
                        )
                    }
                }
            }
        }
    }
    
    private var nutritionSummarySection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("Nutrition Summary", subtitle: "Today's intake")
            
            HStack(spacing: .spacing16) {
                MacroProgressView(
                    title: "Protein",
                    value: nutritionViewModel.entries.reduce(0) { $0 + $1.macros.protein_g },
                    goal: 150,
                    color: .proteinColor
                )
                
                MacroProgressView(
                    title: "Carbs",
                    value: nutritionViewModel.entries.reduce(0) { $0 + $1.macros.carbs_g },
                    goal: 250,
                    color: .carbsColor
                )
                
                MacroProgressView(
                    title: "Fat",
                    value: nutritionViewModel.entries.reduce(0) { $0 + $1.macros.fat_g },
                    goal: 65,
                    color: .fatColor
                )
            }
        }
    }
    
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<22: return "evening"
        default: return "night"
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: .spacing8) {
                ModernIcon(icon, size: 24, color: color)
                
                VStack(spacing: .spacing2) {
                    Text(title)
                        .font(.labelMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.captionMedium)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.spacing16)
            .modernCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let time: Date
    
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
            
            Text(time, style: .time)
                .font(.captionMedium)
                .foregroundColor(.textTertiary)
        }
        .padding(.spacing12)
        .modernCardStyle()
    }
}

// MARK: - Macro Progress View
struct MacroProgressView: View {
    let title: String
    let value: Double
    let goal: Double
    let color: Color
    
    private var progress: Double {
        min(value / goal, 1.0)
    }
    
    var body: some View {
        VStack(spacing: .spacing8) {
            ModernProgressRing(
                progress: progress,
                size: 60,
                lineWidth: 4,
                color: color
            )
            
            VStack(spacing: .spacing2) {
                Text(title)
                    .font(.captionMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text("\(Int(value))g")
                    .font(.captionSmall)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

// MARK: - Goal Settings View
struct GoalSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing24) {
                    Text("Goal Settings")
                        .font(.headlineMedium)
                        .foregroundColor(.textPrimary)
                    
                    Text("Customize your fitness and nutrition goals")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    // Add goal settings here
                    
                    Button("Done") {
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