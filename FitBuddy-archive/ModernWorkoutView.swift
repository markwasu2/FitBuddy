import SwiftUI

struct ModernWorkoutView: View {
    @EnvironmentObject var workoutPlanManager: WorkoutPlanManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var showingWorkoutPlan = false
    @State private var showingExerciseLog = false
    @State private var selectedWorkout: WorkoutPlan?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing24) {
                    // Header with workout stats
                    headerSection
                    
                    // Today's workout plan
                    todaysWorkoutSection
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Recent workouts
                    recentWorkoutsSection
                    
                    // Workout progress
                    workoutProgressSection
                }
                .padding(.horizontal, .spacing20)
            }
            .background(Color.background)
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Workout") {
                        showingExerciseLog = true
                    }
                    .font(.labelMedium)
                    .foregroundColor(.brandPrimary)
                }
            }
            .sheet(isPresented: $showingWorkoutPlan) {
                ModernWorkoutPlanView()
            }
            .sheet(isPresented: $showingExerciseLog) {
                ModernExerciseLogView()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: .spacing20) {
            // Workout stats
            HStack(spacing: .spacing16) {
                ModernMetricCard(
                    title: "Active Calories",
                    value: "\(Int(healthKitManager.activeCalories))",
                    subtitle: "Today",
                    icon: "flame.fill",
                    color: .brandWarning
                )
                
                ModernMetricCard(
                    title: "Workouts",
                    value: "\(healthKitManager.workouts.count)",
                    subtitle: "This week",
                    icon: "dumbbell.fill",
                    color: .brandSuccess
                )
            }
            
            // Weekly progress
            ModernProgressRing(
                progress: Double(healthKitManager.workouts.count) / 5.0,
                size: 100,
                lineWidth: 8,
                color: .brandPrimary,
                showPercentage: true
            )
        }
    }
    
    private var todaysWorkoutSection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("Today's Workout", subtitle: "Your scheduled workout")
            
            if let todaysWorkout = workoutPlanManager.todaysWorkout {
                ModernWorkoutCard(workout: todaysWorkout) {
                    selectedWorkout = todaysWorkout
                    showingWorkoutPlan = true
                }
            } else {
                ModernEmptyState(
                    icon: "dumbbell",
                    title: "No Workout Scheduled",
                    subtitle: "Create a workout plan or start a spontaneous workout",
                    action: {
                        showingWorkoutPlan = true
                    },
                    actionTitle: "Create Workout Plan"
                )
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("Quick Actions", subtitle: "Start your workout")
            
            HStack(spacing: .spacing12) {
                ModernQuickActionButton(
                    title: "Start Workout",
                    subtitle: "Begin Exercise",
                    icon: "play.fill",
                    color: .brandSuccess
                ) {
                    showingExerciseLog = true
                }
                
                ModernQuickActionButton(
                    title: "Workout Plan",
                    subtitle: "View Schedule",
                    icon: "calendar",
                    color: .brandPrimary
                ) {
                    showingWorkoutPlan = true
                }
                
                ModernQuickActionButton(
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
    
    private var recentWorkoutsSection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("Recent Workouts", subtitle: "Your latest sessions")
            
            if healthKitManager.workouts.isEmpty {
                ModernEmptyState(
                    icon: "clock",
                    title: "No Recent Workouts",
                    subtitle: "Start logging your workouts to see them here",
                    action: {
                        showingExerciseLog = true
                    },
                    actionTitle: "Log Your First Workout"
                )
            } else {
                VStack(spacing: .spacing12) {
                    ForEach(Array(healthKitManager.workouts.prefix(3)), id: \.self) { workout in
                        ModernWorkoutRow(workout: workout)
                    }
                }
            }
        }
    }
    
    private var workoutProgressSection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("Weekly Progress", subtitle: "Your fitness journey")
            
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
                    title: "Active Time",
                    value: "\(Int(healthKitManager.activeMinutes)) min",
                    subtitle: "Today",
                    icon: "clock.fill",
                    color: .brandPrimary
                )
                
                ModernMetricCard(
                    title: "Calories Burned",
                    value: "\(Int(healthKitManager.activeCalories))",
                    subtitle: "Today",
                    icon: "flame.fill",
                    color: .brandWarning
                )
                
                ModernMetricCard(
                    title: "Heart Rate",
                    value: "\(healthKitManager.heartRate) bpm",
                    subtitle: "Average",
                    icon: "heart.fill",
                    color: .brandError
                )
            }
        }
    }
}

// MARK: - Modern Workout Card
struct ModernWorkoutCard: View {
    let workout: WorkoutPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: .spacing12) {
                HStack {
                    ModernIcon("dumbbell.fill", size: 20, color: .brandSuccess)
                    
                    VStack(alignment: .leading, spacing: .spacing4) {
                        Text(workout.name)
                            .font(.titleSmall)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Text(workout.type.rawValue)
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("\(workout.exercises.count) exercises")
                        .font(.captionMedium)
                        .foregroundColor(.textTertiary)
                }
                
                // Exercise preview
                if !workout.exercises.isEmpty {
                    HStack(spacing: .spacing8) {
                        ForEach(Array(workout.exercises.prefix(3)), id: \.name) { exercise in
                            Text(exercise.name)
                                .font(.captionMedium)
                                .padding(.horizontal, .spacing8)
                                .padding(.vertical, .spacing4)
                                .background(Color.brandPrimary.opacity(0.1))
                                .foregroundColor(.brandPrimary)
                                .cornerRadius(.radius8)
                        }
                        
                        if workout.exercises.count > 3 {
                            Text("+\(workout.exercises.count - 3) more")
                                .font(.captionMedium)
                                .foregroundColor(.textTertiary)
                        }
                    }
                }
            }
            .padding(.spacing16)
            .modernCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Workout Row
struct ModernWorkoutRow: View {
    let workout: String // Simplified for now
    
    var body: some View {
        HStack(spacing: .spacing12) {
            ModernIcon("dumbbell.fill", size: 20, color: .brandSuccess)
            
            VStack(alignment: .leading, spacing: .spacing4) {
                Text(workout)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text("Workout completed")
                    .font(.captionMedium)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Text("Today")
                .font(.captionMedium)
                .foregroundColor(.textTertiary)
        }
        .padding(.spacing12)
        .modernCardStyle()
    }
}

// MARK: - Modern Workout Plan View
struct ModernWorkoutPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutPlanManager: WorkoutPlanManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing24) {
                    Text("Workout Plans")
                        .font(.headlineMedium)
                        .foregroundColor(.textPrimary)
                    
                    if workoutPlanManager.workoutPlans.isEmpty {
                        ModernEmptyState(
                            icon: "calendar",
                            title: "No Workout Plans",
                            subtitle: "Create your first workout plan to get started",
                            action: {
                                // Create workout plan
                            },
                            actionTitle: "Create Plan"
                        )
                    } else {
                        VStack(spacing: .spacing16) {
                            ForEach(workoutPlanManager.workoutPlans, id: \.id) { plan in
                                ModernWorkoutCard(workout: plan) {
                                    // View workout details
                                }
                            }
                        }
                    }
                }
                .padding(.spacing24)
            }
            .background(Color.background)
            .navigationTitle("Workout Plans")
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

// MARK: - Modern Exercise Log View
struct ModernExerciseLogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise = ""
    @State private var sets = ""
    @State private var reps = ""
    @State private var weight = ""
    @State private var duration = ""
    
    let exercises = [
        "Push-ups", "Pull-ups", "Squats", "Deadlifts", "Bench Press",
        "Overhead Press", "Rows", "Lunges", "Planks", "Burpees"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing24) {
                    Text("Log Exercise")
                        .font(.headlineMedium)
                        .foregroundColor(.textPrimary)
                    
                    VStack(spacing: .spacing16) {
                        // Exercise selection
                        VStack(alignment: .leading, spacing: .spacing8) {
                            Text("Exercise")
                                .font(.labelMedium)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            
                            Picker("Exercise", selection: $selectedExercise) {
                                Text("Select Exercise").tag("")
                                ForEach(exercises, id: \.self) { exercise in
                                    Text(exercise).tag(exercise)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .modernInputStyle()
                        }
                        
                        // Exercise details
                        HStack(spacing: .spacing12) {
                            VStack(alignment: .leading, spacing: .spacing8) {
                                Text("Sets")
                                    .font(.labelMedium)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                
                                TextField("3", text: $sets)
                                    .modernInputStyle()
                                    .keyboardType(.numberPad)
                            }
                            
                            VStack(alignment: .leading, spacing: .spacing8) {
                                Text("Reps")
                                    .font(.labelMedium)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                
                                TextField("10", text: $reps)
                                    .modernInputStyle()
                                    .keyboardType(.numberPad)
                            }
                        }
                        
                        HStack(spacing: .spacing12) {
                            VStack(alignment: .leading, spacing: .spacing8) {
                                Text("Weight (lbs)")
                                    .font(.labelMedium)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                
                                TextField("0", text: $weight)
                                    .modernInputStyle()
                                    .keyboardType(.numberPad)
                            }
                            
                            VStack(alignment: .leading, spacing: .spacing8) {
                                Text("Duration (min)")
                                    .font(.labelMedium)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                
                                TextField("0", text: $duration)
                                    .modernInputStyle()
                                    .keyboardType(.numberPad)
                            }
                        }
                    }
                    
                    Button("Log Exercise") {
                        // Log exercise logic
                        dismiss()
                    }
                    .modernButtonStyle()
                    .disabled(selectedExercise.isEmpty)
                }
                .padding(.spacing24)
            }
            .background(Color.background)
            .navigationTitle("Log Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.labelMedium)
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
} 