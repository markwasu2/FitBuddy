import SwiftUI

struct PersonalizedWorkoutSetupView: View {
    @EnvironmentObject var workoutPlanManager: WorkoutPlanManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var preferences: WorkoutPreferences = WorkoutPreferences()
    @State private var currentStep = 0
    @State private var showingCompletion = false
    
    private let totalSteps = 6
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Header
                progressHeader
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case 0:
                            fitnessLevelStep
                        case 1:
                            workoutTypesStep
                        case 2:
                            equipmentStep
                        case 3:
                            durationStep
                        case 4:
                            scheduleStep
                        case 5:
                            goalsStep
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.background)
            .navigationTitle("Personalize Your Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(Color.accent)
                    }
                }
            }
            .sheet(isPresented: $showingCompletion) {
                WorkoutSetupCompletionView()
                    .environmentObject(workoutPlanManager)
            }
        }
    }
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Progress bar
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Rectangle()
                        .fill(step <= currentStep ? Color.accent : Color.textSecondary.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
            .padding(.horizontal, 20)
            
            // Step indicator
            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(Color.textSecondary)
        }
        .padding(.vertical, 16)
        .background(Color.accent)
    }
    
    // MARK: - Step Views
    
    private var fitnessLevelStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(
                title: "What's your fitness level?",
                subtitle: "This helps us create workouts that match your experience"
            )
            
            VStack(spacing: 16) {
                ForEach(FitnessLevel.allCases, id: \.self) { level in
                    FitnessLevelCard(
                        level: level,
                        isSelected: preferences.fitnessLevel == level
                    ) {
                        preferences.fitnessLevel = level
                    }
                }
            }
            
            Spacer()
            
            nextButton {
                withAnimation {
                    currentStep += 1
                }
            }
        }
    }
    
    private var workoutTypesStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(
                title: "What types of workouts do you enjoy?",
                subtitle: "Select all that interest you"
            )
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(WorkoutType.allCases, id: \.self) { workoutType in
                    WorkoutTypeCard(
                        workoutType: workoutType,
                        isSelected: preferences.preferredWorkoutTypes.contains(workoutType)
                    ) {
                        if preferences.preferredWorkoutTypes.contains(workoutType) {
                            preferences.preferredWorkoutTypes.removeAll { $0 == workoutType }
                        } else {
                            preferences.preferredWorkoutTypes.append(workoutType)
                        }
                    }
                }
            }
            
            Spacer()
            
            nextButton {
                withAnimation {
                    currentStep += 1
                }
            }
        }
    }
    
    private var equipmentStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(
                title: "What equipment do you have access to?",
                subtitle: "We'll customize exercises based on your available equipment"
            )
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(Equipment.allCases, id: \.self) { equipment in
                    EquipmentCard(
                        equipment: equipment,
                        isSelected: preferences.availableEquipment.contains(equipment)
                    ) {
                        if preferences.availableEquipment.contains(equipment) {
                            preferences.availableEquipment.removeAll { $0 == equipment }
                        } else {
                            preferences.availableEquipment.append(equipment)
                        }
                    }
                }
            }
            
            Spacer()
            
            nextButton {
                withAnimation {
                    currentStep += 1
                }
            }
        }
    }
    
    private var durationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(
                title: "How long do you want your workouts to be?",
                subtitle: "Choose a duration that fits your schedule"
            )
            
            VStack(spacing: 16) {
                ForEach(WorkoutDuration.allCases, id: \.self) { duration in
                    DurationCard(
                        duration: duration,
                        isSelected: preferences.workoutDuration == duration
                    ) {
                        preferences.workoutDuration = duration
                    }
                }
            }
            
            Spacer()
            
            nextButton {
                withAnimation {
                    currentStep += 1
                }
            }
        }
    }
    
    private var scheduleStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(
                title: "How often do you want to work out?",
                subtitle: "We'll schedule your workouts automatically"
            )
            
            VStack(spacing: 20) {
                // Days per week
                VStack(alignment: .leading, spacing: 12) {
                    Text("Workouts per week")
                        .font(.headline)
                        .foregroundColor(Color.textPrimary)
                    
                    HStack(spacing: 12) {
                        ForEach([3, 4, 5, 6], id: \.self) { days in
                            Button(action: {
                                preferences.daysPerWeek = days
                            }) {
                                Text("\(days)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(preferences.daysPerWeek == days ? .white : Color.textPrimary)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(preferences.daysPerWeek == days ? Color.accent : Color.background)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.accent, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
                
                // Preferred time
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferred workout time")
                        .font(.headline)
                        .foregroundColor(Color.textPrimary)
                    
                    VStack(spacing: 12) {
                        ForEach(WorkoutTime.allCases, id: \.self) { time in
                            TimeCard(
                                time: time,
                                isSelected: preferences.preferredTime == time
                            ) {
                                preferences.preferredTime = time
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            nextButton {
                withAnimation {
                    currentStep += 1
                }
            }
        }
    }
    
    private var goalsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(
                title: "What are your fitness goals?",
                subtitle: "Select your primary goals"
            )
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: preferences.goals.contains(goal)
                    ) {
                        if preferences.goals.contains(goal) {
                            preferences.goals.removeAll { $0 == goal }
                        } else {
                            preferences.goals.append(goal)
                        }
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                workoutPlanManager.updatePreferences(preferences)
                showingCompletion = true
            }) {
                Text("Create My Workout Plan")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.accent)
                    .cornerRadius(16)
            }
            .disabled(!preferences.isComplete)
            .opacity(preferences.isComplete ? 1.0 : 0.5)
        }
    }
    
    // MARK: - Helper Views
    
    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.textPrimary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
        }
    }
    
    private func nextButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Next")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.accent)
                .cornerRadius(16)
        }
    }
}

// MARK: - Card Components

struct FitnessLevelCard: View {
    let level: FitnessLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(level.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : Color.textPrimary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                
                Text(level.description)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : Color.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accent : Color.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accent : Color.textSecondary.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutTypeCard: View {
    let workoutType: WorkoutType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: workoutType.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color.accent)
                
                Text(workoutType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : Color.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accent : Color.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accent : Color.textSecondary.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EquipmentCard: View {
    let equipment: Equipment
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: equipment.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color.accent)
                
                Text(equipment.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : Color.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accent : Color.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accent : Color.textSecondary.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DurationCard: View {
    let duration: WorkoutDuration
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(duration.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : Color.textPrimary)
                    
                    Text("\(duration.minutes) minutes average")
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : Color.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accent : Color.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accent : Color.textSecondary.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimeCard: View {
    let time: WorkoutTime
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(time.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : Color.textPrimary)
                    
                    Text("Around \(time.timeString)")
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : Color.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accent : Color.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accent : Color.textSecondary.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color.accent)
                
                Text(goal.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : Color.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accent : Color.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accent : Color.textSecondary.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Completion View

struct WorkoutSetupCompletionView: View {
    @EnvironmentObject var workoutPlanManager: WorkoutPlanManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.successGreen.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.successGreen)
                }
                
                // Success message
                VStack(spacing: 16) {
                    Text("Workout Plan Created!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("Your personalized workouts have been scheduled in your calendar. Check the Calendar tab to see your upcoming workouts.")
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Stats
                VStack(spacing: 16) {
                    HStack(spacing: 24) {
                                        WorkoutStatCard(title: "Workouts", value: "\(workoutPlanManager.personalizedPlans.count)", icon: "dumbbell.fill")
                WorkoutStatCard(title: "Days/Week", value: "\(workoutPlanManager.preferences.daysPerWeek)", icon: "calendar")
                    }
                    
                    HStack(spacing: 24) {
                                        WorkoutStatCard(title: "Duration", value: "\(workoutPlanManager.preferences.workoutDuration.minutes)min", icon: "clock.fill")
                WorkoutStatCard(title: "Time", value: workoutPlanManager.preferences.preferredTime.timeString, icon: "alarm.fill")
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("View My Calendar")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.accent)
                            .cornerRadius(16)
                    }
                    
                    Button(action: {
                        workoutPlanManager.resetPersonalization()
                        dismiss()
                    }) {
                        Text("Start Over")
                            .font(.subheadline)
                            .foregroundColor(Color.accent)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 100)
        }
    }
}

struct WorkoutStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.accent)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.background)
        .cornerRadius(12)
    }
} 