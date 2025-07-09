import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var workoutPlanManager: WorkoutPlanManager
    @State private var showingSetup = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingL) {
                    // Header
                    headerSection
                    
                    // Current Plan
                    currentPlanSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent Workouts
                    recentWorkoutsSection
                }
                .padding(.spacingM)
            }
            .background(Color.background)
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSetup) {
                PersonalizedWorkoutSetupView()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text("Your Workout Plan")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Stay consistent with personalized workouts")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Button(action: { showingSetup = true }) {
                    CleanIcon("plus.circle.fill", size: 32, color: .accent)
                }
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - Current Plan Section
    private var currentPlanSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            CleanSectionHeader("Current Plan")
            
            if workoutPlanManager.personalizedPlans.isEmpty {
                CleanEmptyState(
                    icon: "dumbbell",
                    title: "No Workout Plan",
                    subtitle: "Create a personalized workout plan to get started",
                    action: { showingSetup = true }
                )
            } else {
                LazyVStack(spacing: .spacingM) {
                    ForEach(workoutPlanManager.personalizedPlans.prefix(3)) { workout in
                        workoutCard(workout)
                    }
                }
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            CleanSectionHeader("Quick Actions")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: .spacingM) {
                quickActionCard(
                    title: "Start Workout",
                    subtitle: "Begin today's session",
                    icon: "play.circle.fill",
                    color: .success,
                    action: { /* Start workout */ }
                )
                
                quickActionCard(
                    title: "View History",
                    subtitle: "See past workouts",
                    icon: "clock.fill",
                    color: .info,
                    action: { /* View history */ }
                )
                
                quickActionCard(
                    title: "Edit Plan",
                    subtitle: "Modify your routine",
                    icon: "pencil.circle.fill",
                    color: .warning,
                    action: { showingSetup = true }
                )
                
                quickActionCard(
                    title: "Sync Calendar",
                    subtitle: "Update schedule",
                    icon: "calendar.badge.plus",
                    color: .accent,
                    action: { /* Sync calendar */ }
                )
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - Recent Workouts Section
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            CleanSectionHeader("Recent Workouts")
            
            if workoutPlanManager.plans.isEmpty {
                CleanEmptyState(
                    icon: "figure.run",
                    title: "No Recent Workouts",
                    subtitle: "Complete your first workout to see it here"
                )
            } else {
                LazyVStack(spacing: .spacingS) {
                    ForEach(workoutPlanManager.plans.prefix(3)) { workout in
                        recentWorkoutRow(workout)
                    }
                }
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - Helper Views
    private func workoutCard(_ workout: PersonalizedWorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                CleanIcon(workout.workoutType.icon, size: 24, color: .accent)
                
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(workout.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text(workout.formattedDuration)
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Text(workout.difficulty.rawValue)
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, .spacingS)
                    .padding(.vertical, 2)
                    .background(Color.textTertiary.opacity(0.1))
                    .cornerRadius(CGFloat.radiusS)
            }
            
            if !workout.exercises.isEmpty {
                Text("\(workout.exercises.count) exercises")
                    .font(.caption1)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(.spacingM)
        .background(Color.surface)
        .cornerRadius(CGFloat.radiusM)
    }
    
    private func quickActionCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: .spacingS) {
                CleanIcon(icon, size: 24, color: color)
                
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.spacingM)
            .background(Color.surface)
            .cornerRadius(CGFloat.radiusM)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func recentWorkoutRow(_ workout: WorkoutPlan) -> some View {
        HStack(spacing: .spacingM) {
            CleanIcon("figure.run", size: 20, color: .success)
            
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(workout.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text(workout.formattedDuration)
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Optionally show more info here
        }
        .padding(.spacingS)
        .background(Color.surface)
        .cornerRadius(CGFloat.radiusM)
    }
} 