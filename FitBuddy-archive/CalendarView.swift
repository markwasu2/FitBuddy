import SwiftUI
import EventKit

struct CalendarView: View {
    @EnvironmentObject var workoutPlanManager: WorkoutPlanManager
    @State private var selectedDate = Date()
    @State private var showingWorkoutDetail = false
    @State private var selectedWorkoutPlan: PersonalizedWorkoutPlan?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingL) {
                    // Header
                    headerSection
                    
                    // Calendar Grid
                    calendarSection
                    
                    // Today's Workouts
                    todaysWorkoutsSection
                    
                    // Upcoming Workouts
                    upcomingWorkoutsSection
                }
                .padding(.spacingM)
            }
            .background(Color.background)
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingWorkoutDetail) {
                if let workoutPlan = selectedWorkoutPlan {
                    WorkoutDetailView(workoutPlan: workoutPlan)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text("Workout Schedule")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Plan and track your fitness journey")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Button(action: { /* Sync calendar */ }) {
                    CleanIcon("arrow.clockwise", size: 24, color: .accent)
                }
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            CleanSectionHeader("Calendar")
            
            VStack(spacing: .spacingM) {
                // Month Header
                HStack {
                    Button(action: { /* Previous month */ }) {
                        CleanIcon("chevron.left", size: 20, color: .textSecondary)
                    }
                    
                    Spacer()
                    
                    Text(monthYearString)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: { /* Next month */ }) {
                        CleanIcon("chevron.right", size: 20, color: .textSecondary)
                    }
                }
                
                // Calendar Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: .spacingS) {
                    ForEach(weekdayHeaders, id: \.self) { day in
                        Text(day)
                            .font(.caption1)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }
                    
                    ForEach(calendarDays, id: \.self) { date in
                        calendarDayView(date)
                    }
                }
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - Today's Workouts Section
    private var todaysWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            CleanSectionHeader("Today's Workouts")
            
            let todaysWorkouts = workoutPlanManager.getWorkoutsForDate(selectedDate)
            
            if todaysWorkouts.isEmpty {
                CleanEmptyState(
                    icon: "figure.run",
                    title: "No Workouts Today",
                    subtitle: "Take a rest day or schedule a workout"
                )
            } else {
                LazyVStack(spacing: .spacingS) {
                    ForEach(todaysWorkouts) { workoutPlan in
                        workoutRow(workoutPlan)
                    }
                }
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - Upcoming Workouts Section
    private var upcomingWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            CleanSectionHeader("Upcoming Workouts")
            
            let upcomingWorkouts = workoutPlanManager.personalizedPlans.prefix(3)
            
            if upcomingWorkouts.isEmpty {
                CleanEmptyState(
                    icon: "figure.run",
                    title: "No Upcoming Workouts",
                    subtitle: "Schedule your next workout"
                )
            } else {
                LazyVStack(spacing: .spacingS) {
                    ForEach(Array(upcomingWorkouts), id: \.id) { workoutPlan in
                        upcomingWorkoutRow(workoutPlan)
                    }
                }
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - Helper Views
    private func calendarDayView(_ date: Date) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let hasWorkout = !workoutPlanManager.getWorkoutsForDate(date).isEmpty
        
        return Button(action: { selectedDate = date }) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption1)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .secondary : .textPrimary)
                
                if hasWorkout {
                    Circle()
                        .fill(Color.accent)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 32, height: 32)
            .background(isSelected ? Color.accent : Color.clear)
            .cornerRadius(CGFloat.radiusS)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func workoutRow(_ workoutPlan: PersonalizedWorkoutPlan) -> some View {
        Button(action: {
            selectedWorkoutPlan = workoutPlan
            showingWorkoutDetail = true
        }) {
            HStack(spacing: .spacingM) {
                CleanIcon("figure.run", size: 24, color: .accent)
                
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(workoutPlan.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text(workoutPlan.formattedDuration)
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: .spacingXS) {
                    Text(workoutPlan.difficulty.rawValue)
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, .spacingS)
                        .padding(.vertical, 2)
                        .background(Color.textTertiary.opacity(0.1))
                        .cornerRadius(CGFloat.radiusS)
                    
                    CleanIcon("chevron.right", size: 12, color: .textTertiary)
                }
            }
            .padding(.spacingS)
            .background(Color.surface)
            .cornerRadius(CGFloat.radiusM)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func upcomingWorkoutRow(_ workoutPlan: PersonalizedWorkoutPlan) -> some View {
        HStack(spacing: .spacingM) {
            CleanIcon("figure.run", size: 20, color: .accent)
            
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(workoutPlan.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text(workoutPlan.formattedDuration)
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Text(workoutPlan.difficulty.rawValue)
                .font(.caption1)
                .foregroundColor(.textSecondary)
        }
        .padding(.spacingS)
        .background(Color.surface)
        .cornerRadius(CGFloat.radiusM)
    }
    
    // MARK: - Helper Properties
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var weekdayHeaders: [String] {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
    
    private var calendarDays: [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offsetDays = firstWeekday - 1
        
        let startDate = calendar.date(byAdding: .day, value: -offsetDays, to: startOfMonth) ?? selectedDate
        
        return (0..<42).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: startDate)
        }
    }
}

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    let workoutPlan: PersonalizedWorkoutPlan
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingL) {
                    // Header
                    VStack(spacing: .spacingM) {
                        CleanIcon("figure.run", size: 64, color: .accent)
                        
                        VStack(spacing: .spacingS) {
                            Text(workoutPlan.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            
                            Text(workoutPlan.formattedDuration)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.spacingL)
                    
                    // Workout Info
                    VStack(spacing: .spacingM) {
                        infoRow("Difficulty", workoutPlan.difficulty.rawValue)
                        infoRow("Equipment", workoutPlan.equipment.map { $0.rawValue }.joined(separator: ", "))
                        infoRow("Focus", workoutPlan.workoutType.rawValue)
                    }
                    .padding(.spacingM)
                    .cleanCardStyle()
                    
                    // Exercises
                    if !workoutPlan.exercises.isEmpty {
                        VStack(alignment: .leading, spacing: .spacingM) {
                            CleanSectionHeader("Exercises")
                            
                            LazyVStack(spacing: .spacingS) {
                                ForEach(workoutPlan.exercises, id: \.name) { exercise in
                                    exerciseRow(exercise)
                                }
                            }
                        }
                        .padding(.spacingM)
                        .cleanCardStyle()
                    }
                }
                .padding(.spacingM)
            }
            .background(Color.background)
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
        }
    }
    
    private func exerciseRow(_ exercise: PersonalizedExercise) -> some View {
        HStack(spacing: .spacingM) {
            CleanIcon("dumbbell.fill", size: 20, color: .accent)
            
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text(exercise.formattedSets)
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(.spacingS)
        .background(Color.surface)
        .cornerRadius(CGFloat.radiusM)
    }
} 