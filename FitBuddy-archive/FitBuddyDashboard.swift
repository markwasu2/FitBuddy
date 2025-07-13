import SwiftUI
import HealthKit

struct PeregrineDashboard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var profileManager: ProfileManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingL) {
                    // Header
                    headerSection
                    
                    // Quick Stats
                    quickStatsSection
                    
                    // Today's Progress
                    progressSection
                    
                    // Remove the entire recentActivitySection and all calls to it, as recentWorkouts is not available.
                }
                .padding(.spacingM)
            }
            .background(Color.background)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text("Good \(timeOfDay)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text(profileManager.name.isEmpty ? "Welcome back!" : "Welcome back, \(profileManager.name)!")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Button(action: { /* Profile action */ }) {
                    CleanIcon("person.circle.fill", size: 32, color: .accent)
                }
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: .spacingM) {
            CleanMetricCard(
                title: "Steps",
                value: "\(healthKitManager.todaySteps)",
                subtitle: "Goal: 10,000",
                icon: "figure.walk",
                color: .success
            )
            
            CleanMetricCard(
                title: "Calories",
                value: "\(Int(healthKitManager.todayActiveCalories))",
                subtitle: "Active today",
                icon: "flame.fill",
                color: .warning
            )
            
            CleanMetricCard(
                title: "Heart Rate",
                value: "\(Int(healthKitManager.todayHeartRate))",
                subtitle: "BPM",
                icon: "heart.fill",
                color: .error
            )
            
            CleanMetricCard(
                title: "Distance",
                value: String(format: "%.1f", healthKitManager.todayDistance),
                subtitle: "Miles",
                icon: "location.fill",
                color: .info
            )
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            CleanSectionHeader("Today's Progress")
            
            VStack(spacing: .spacingM) {
                // Steps Progress
                progressRow(
                    title: "Steps",
                    current: healthKitManager.todaySteps,
                    goal: 10000,
                    icon: "figure.walk",
                    color: .success
                )
                
                // Calories Progress
                progressRow(
                    title: "Calories",
                    current: Int(healthKitManager.todayActiveCalories),
                    goal: 500,
                    icon: "flame.fill",
                    color: .warning
                )
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - Helper Views
    private func progressRow(title: String, current: Int, goal: Int, icon: String, color: Color) -> some View {
        HStack(spacing: .spacingM) {
            CleanIcon(icon, size: 24, color: color)
            
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                
                Text("\(current) / \(goal)")
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            CleanProgressRing(
                progress: Double(current) / Double(goal),
                size: 40,
                lineWidth: 4,
                color: color
            )
        }
        .padding(.spacingS)
    }
    
    // MARK: - Helper Properties
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<22: return "evening"
        default: return "night"
        }
    }
} 

 