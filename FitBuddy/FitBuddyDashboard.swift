import SwiftUI
import HealthKit

// MARK: - DASHBOARD-SPECIFIC EXTENSIONS

enum Trend { case up, down, flat }

extension Color {
    // Remove custom dashboard colors
    // Use main palette only
}

extension Font {
    static let h1     = Font.system(size: 28, weight: .bold)
    static let h2     = Font.system(size: 22, weight: .semibold)
}

extension View {
    func fhCard() -> some View {
        self.padding(20)
            .background(Color.bgSecondary)
            .cornerRadius(18)
            .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
    }
}

// MARK: - DASHBOARD

struct FitBuddyDashboard: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var workoutJournal: WorkoutJournal
    @State private var showProfileEdit = false
    @State private var showCalorieSettings = false
    @State private var showFoodJournal = false
    @State private var showEditMetric = false
    @State private var editingMetric: String = ""
    @State private var isRefreshing = false

    var today: Date { Date() }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    // (A) Greeting banner
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hi, \(profileManager.name.isEmpty ? "Friend" : profileManager.name) 👋")
                                .font(.h1)
                                .foregroundColor(.textPrimary)
                            Text(today, format: .dateTime.weekday().month().day())
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // (B) Today's Goals Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Goals")
                            .font(.h2)
                            .foregroundColor(.textPrimary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            EditableMetricCard(
                                title: "Steps",
                                value: Double(healthKitManager.todaySteps),
                                unit: "steps",
                                goal: Double(healthKitManager.dailyStepGoal),
                                trend: getTrend(for: healthKitManager.weeklySteps),
                                latestWeekData: healthKitManager.weeklySteps,
                                isManuallyEdited: healthKitManager.isStepsManuallyEdited,
                                onEdit: { editMetric("Steps", Double(healthKitManager.todaySteps), Double(healthKitManager.dailyStepGoal), "steps") },
                                onGoalEdit: { editMetric("Steps", Double(healthKitManager.todaySteps), Double(healthKitManager.dailyStepGoal), "steps") }
                            )
                            
                            EditableMetricCard(
                                title: "Calories",
                                value: healthKitManager.todayActiveCalories,
                                unit: "kcal",
                                goal: Double(healthKitManager.dailyCalorieGoal),
                                trend: getTrend(for: healthKitManager.weeklyCalories),
                                latestWeekData: healthKitManager.weeklyCalories,
                                isManuallyEdited: healthKitManager.isCaloriesManuallyEdited,
                                onEdit: { editMetric("Calories", healthKitManager.todayActiveCalories, Double(healthKitManager.dailyCalorieGoal), "kcal") },
                                onGoalEdit: { editMetric("Calories", healthKitManager.todayActiveCalories, Double(healthKitManager.dailyCalorieGoal), "kcal") }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // (C) Biometrics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        EditableMetricCard(
                            title: "Heart Rate",
                            value: healthKitManager.todayHeartRate,
                            unit: "bpm",
                            goal: Double(healthKitManager.dailyHeartRateGoal),
                            trend: .flat,
                            latestWeekData: Array(repeating: healthKitManager.todayHeartRate, count: 7),
                            isManuallyEdited: healthKitManager.isHeartRateManuallyEdited,
                            onEdit: { editMetric("Heart Rate", healthKitManager.todayHeartRate, Double(healthKitManager.dailyHeartRateGoal), "bpm") },
                            onGoalEdit: { editMetric("Heart Rate", healthKitManager.todayHeartRate, Double(healthKitManager.dailyHeartRateGoal), "bpm") }
                        )
                        
                        EditableMetricCard(
                            title: "Sleep",
                            value: healthKitManager.todaySleepHours,
                            unit: "hrs",
                            goal: healthKitManager.dailySleepGoal,
                            trend: getTrend(for: healthKitManager.weeklySleep),
                            latestWeekData: healthKitManager.weeklySleep,
                            isManuallyEdited: healthKitManager.isSleepManuallyEdited,
                            onEdit: { editMetric("Sleep", healthKitManager.todaySleepHours, healthKitManager.dailySleepGoal, "hrs") },
                            onGoalEdit: { editMetric("Sleep", healthKitManager.todaySleepHours, healthKitManager.dailySleepGoal, "hrs") }
                        )
                        
                        EditableMetricCard(
                            title: "Weight",
                            value: Double(profileManager.weight),
                            unit: "lbs",
                            goal: healthKitManager.targetWeight,
                            trend: .flat,
                            latestWeekData: Array(repeating: Double(profileManager.weight), count: 7),
                            isManuallyEdited: healthKitManager.isWeightManuallyEdited,
                            onEdit: { editMetric("Weight", Double(profileManager.weight), healthKitManager.targetWeight, "lbs") },
                            onGoalEdit: { editMetric("Weight", Double(profileManager.weight), healthKitManager.targetWeight, "lbs") }
                        )
                        
                        EditableMetricCard(
                            title: "Body Fat",
                            value: healthKitManager.todayBodyFatPercentage,
                            unit: "%",
                            goal: healthKitManager.targetBodyFatPercentage,
                            trend: .flat,
                            latestWeekData: Array(repeating: healthKitManager.todayBodyFatPercentage, count: 7),
                            isManuallyEdited: healthKitManager.isBodyFatManuallyEdited,
                            onEdit: { editMetric("Body Fat", healthKitManager.todayBodyFatPercentage, healthKitManager.targetBodyFatPercentage, "%") },
                            onGoalEdit: { editMetric("Body Fat", healthKitManager.todayBodyFatPercentage, healthKitManager.targetBodyFatPercentage, "%") }
                        )
                        
                        // Calorie tracking card
                        CalorieTrackingCard(
                            consumed: healthKitManager.consumedCalories,
                            goal: Double(healthKitManager.dailyCalorieGoal),
                            burned: healthKitManager.todayActiveCalories
                        )
                        
                        MetricCard(
                            title: "Distance", 
                            value: healthKitManager.todayDistance, 
                            unit: "mi", 
                            trend: getTrend(for: healthKitManager.weeklyDistance), 
                            latestWeekData: healthKitManager.weeklyDistance
                        )
                    }
                    .padding(.horizontal)

                    // (D) Log Activity Section
                    LogActivitySection()
                        .padding(.horizontal)

                    // (E) Weekly Rings
                    ActivityRingGrid(
                        steps: healthKitManager.weeklySteps, 
                        calories: healthKitManager.weeklyCalories, 
                        workouts: Array(repeating: Double(workoutJournal.entries.count), count: 7)
                    )
                    .padding(.horizontal)

                    // (F) Latest Workouts
                    WorkoutHistorySection(entries: workoutJournal.entries)
                        .padding(.horizontal)
                    
                    // (G) Food Journal Section
                    FoodJournalSection(entries: healthKitManager.foodEntries)
                        .padding(.horizontal)
                }
                .padding(.top, 24)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .refreshable {
                isRefreshing = true
                healthKitManager.refreshData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { isRefreshing = false }
            }

            // Floating Action Buttons
            VStack(spacing: 16) {
                // Food Journal Button
                Button(action: { showFoodJournal = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.primaryCoral)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
                }
                
                // Settings Button
                Button(action: { showCalorieSettings = true }) {
                    Image(systemName: "slider.vertical.3")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.accentBlue)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.trailing, 28)
            .padding(.bottom, 28)
            .sheet(isPresented: $showProfileEdit) {
                ProfileEditView()
                    .environmentObject(profileManager)
            }
            .sheet(isPresented: $showCalorieSettings) {
                CalorieSettingsView()
                    .environmentObject(healthKitManager)
                    .environmentObject(profileManager)
            }
            .sheet(isPresented: $showFoodJournal) {
                FoodJournalView()
                    .environmentObject(healthKitManager)
            }
            .sheet(isPresented: $showEditMetric) {
                EditMetricDialog(
                    title: editingMetric,
                    currentValue: getCurrentValue(),
                    currentGoal: getCurrentGoal(),
                    unit: getCurrentUnit(),
                    onSave: { value, goal in
                        saveMetricChanges(value: value, goal: goal)
                    },
                    onCancel: {
                        showEditMetric = false
                    }
                )
            }
        }
        .onAppear {
            healthKitManager.loadCalorieGoal()
            healthKitManager.loadFoodEntries()
        }
    }
    
    private func editMetric(_ title: String, _ currentValue: Double, _ currentGoal: Double, _ unit: String) {
        editingMetric = title
        showEditMetric = true
    }
    
    private func getCurrentValue() -> Double {
        switch editingMetric {
        case "Steps":
            return Double(healthKitManager.todaySteps)
        case "Calories":
            return healthKitManager.todayActiveCalories
        case "Heart Rate":
            return healthKitManager.todayHeartRate
        case "Sleep":
            return healthKitManager.todaySleepHours
        case "Weight":
            return Double(profileManager.weight)
        case "Body Fat":
            return healthKitManager.todayBodyFatPercentage
        default:
            return 0
        }
    }
    
    private func getCurrentGoal() -> Double {
        switch editingMetric {
        case "Steps":
            return Double(healthKitManager.dailyStepGoal)
        case "Calories":
            return Double(healthKitManager.dailyCalorieGoal)
        case "Heart Rate":
            return Double(healthKitManager.dailyHeartRateGoal)
        case "Sleep":
            return healthKitManager.dailySleepGoal
        case "Weight":
            return healthKitManager.targetWeight
        case "Body Fat":
            return healthKitManager.targetBodyFatPercentage
        default:
            return 0
        }
    }
    
    private func getCurrentUnit() -> String {
        switch editingMetric {
        case "Steps":
            return "steps"
        case "Calories":
            return "kcal"
        case "Heart Rate":
            return "bpm"
        case "Sleep":
            return "hrs"
        case "Weight":
            return "lbs"
        case "Body Fat":
            return "%"
        default:
            return ""
        }
    }
    
    private func saveMetricChanges(value: Double, goal: Double) {
        switch editingMetric {
        case "Steps":
            healthKitManager.updateSteps(Int(value))
            healthKitManager.updateStepGoal(Int(goal))
        case "Calories":
            healthKitManager.updateCalories(value)
            healthKitManager.updateCalorieGoal(Int(goal))
        case "Heart Rate":
            healthKitManager.updateHeartRate(value)
            healthKitManager.updateHeartRateGoal(Int(goal))
        case "Sleep":
            healthKitManager.updateSleep(value)
            healthKitManager.updateSleepGoal(goal)
        case "Weight":
            profileManager.weight = Int(value)
            profileManager.saveProfile()
            healthKitManager.updateWeightGoal(goal)
        case "Body Fat":
            healthKitManager.updateBodyFat(value)
            healthKitManager.updateBodyFatGoal(goal)
        default:
            break
        }
        showEditMetric = false
    }
    
    private func getTrend(for data: [Double]) -> Trend {
        guard data.count >= 2 else { return .flat }
        let recent = data.suffix(3).reduce(0, +) / Double(data.suffix(3).count)
        let older = data.prefix(4).reduce(0, +) / Double(data.prefix(4).count)
        
        if recent > older * 1.1 {
            return .up
        } else if recent < older * 0.9 {
            return .down
        } else {
            return .flat
        }
    }
}

// MARK: - CALORIE TRACKING CARD

struct CalorieTrackingCard: View {
    let consumed: Double
    let goal: Double
    let burned: Double
    
    var remaining: Double {
        goal - consumed + burned
    }
    
    var progress: Double {
        min(consumed / goal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Calories").font(.caption).foregroundColor(.textSecondary)
                Spacer()
                Text("\(Int(remaining)) left")
                    .font(.caption)
                    .foregroundColor(remaining > 0 ? .primaryCoral : .mutedTerracotta)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(consumed))")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text("/ \(Int(goal))")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.bgSecondary)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(progress > 1.0 ? Color.mutedTerracotta : Color.primaryCoral)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("Burned: \(Int(burned))")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("Net: \(Int(consumed - burned))")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
        }
        .fhCard()
    }
}

// MARK: - FOOD JOURNAL SECTION

struct FoodJournalSection: View {
    let entries: [FoodEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Food")
                    .font(.h2)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(entries.count) items")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            if entries.isEmpty {
                Text("No food logged today")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(entries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                        FoodEntryRow(entry: entry)
                    }
                }
            }
        }
        .fhCard()
    }
}

struct FoodEntryRow: View {
    let entry: FoodEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text(entry.mealType.rawValue)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(entry.calories)) cal")
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text(entry.timestamp, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.bgPrimary)
        .cornerRadius(8)
    }
}

// MARK: - METRIC CARD

struct MetricCard: View {
    let title: String
    let value: Double
    let unit: String
    let trend: Trend
    let latestWeekData: [Double]

    @State private var appear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.caption).foregroundColor(.textSecondary)
                Spacer()
                TrendGlyph(trend: trend)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value, format: .number)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            Sparkline(data: latestWeekData)
                .stroke(Color.primaryCoral, lineWidth: 1.5)
                .frame(height: 22)
        }
        .fhCard()
        .opacity(appear ? 1 : 0)
        .scaleEffect(appear ? 1 : 0.95)
        .onAppear {
            withAnimation(.spring(response: 0.45).delay(Double.random(in: 0...0.2))) {
                appear = true
            }
        }
    }
}

// MARK: - EDITABLE METRIC CARD

struct EditableMetricCard: View {
    let title: String
    let value: Double
    let unit: String
    let goal: Double
    let trend: Trend
    let latestWeekData: [Double]
    let isManuallyEdited: Bool
    let onEdit: () -> Void
    let onGoalEdit: () -> Void

    @State private var appear = false

    var progress: Double {
        goal > 0 ? min(value / goal, 1.0) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.caption).foregroundColor(.textSecondary)
                Spacer()
                HStack(spacing: 4) {
                    if isManuallyEdited {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.primaryCoral)
                            .font(.caption)
                    }
                    TrendGlyph(trend: trend)
                }
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value, format: .number)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .onTapGesture {
                onEdit()
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.bgSecondary)
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(progress > 1.0 ? Color.mutedTerracotta : Color.primaryCoral)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
            .onTapGesture {
                onGoalEdit()
            }
            
            HStack {
                Text("Goal: \(Int(goal))")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            
            Sparkline(data: latestWeekData)
                .stroke(Color.primaryCoral, lineWidth: 1.5)
                .frame(height: 22)
        }
        .fhCard()
        .opacity(appear ? 1 : 0)
        .scaleEffect(appear ? 1 : 0.95)
        .onAppear {
            withAnimation(.spring(response: 0.45).delay(Double.random(in: 0...0.2))) {
                appear = true
            }
        }
    }
}

struct TrendGlyph: View {
    let trend: Trend
    var body: some View {
        switch trend {
        case .up:
            Image(systemName: "arrow.up")
                .foregroundColor(.primaryCoral)
        case .down:
            Image(systemName: "arrow.down")
                .foregroundColor(.mutedTerracotta)
        case .flat:
            Image(systemName: "equal")
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - ACTIVITY RINGS

struct ActivityRingGrid: View {
    let steps: [Double]
    let calories: [Double]
    let workouts: [Double]
    var body: some View {
        HStack(spacing: 20) {
            ActivityRingView(title: "Steps", value: steps.last ?? 0, goal: 10000, color: .primaryCoral, data: steps)
            ActivityRingView(title: "Calories", value: calories.last ?? 0, goal: 500, color: .primaryCoral, data: calories)
            ActivityRingView(title: "Workouts", value: workouts.last ?? 0, goal: 5, color: .mutedTerracotta, data: workouts)
        }
    }
}

struct ActivityRingView: View {
    let title: String
    let value: Double
    let goal: Double
    let color: Color
    let data: [Double]

    var progress: Double { min(value / goal, 1.0) }

    var body: some View {
        VStack(spacing: 6) {
            TimelineView(.animation) { _ in
                ZStack {
                    Circle()
                        .stroke(Color.bgSecondary, lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.7), value: progress)
                }
                .frame(width: 60, height: 60)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                Text("\(Int(value))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
            }
        }
    }
}

// MARK: - SPARKLINE

struct Sparkline: Shape {
    let data: [Double]
    
    func path(in rect: CGRect) -> Path {
        guard data.count > 1 else { return Path() }
        
        let maxValue = data.max() ?? 1
        let minValue = data.min() ?? 0
        let range = maxValue - minValue
        
        let xStep = rect.width / CGFloat(data.count - 1)
        let yStep = range > 0 ? rect.height / CGFloat(range) : 0
        
        var path = Path()
        let firstPoint = CGPoint(
            x: 0,
            y: rect.height - CGFloat(data[0] - minValue) * yStep
        )
        path.move(to: firstPoint)
        
        for i in 1..<data.count {
            let point = CGPoint(
                x: CGFloat(i) * xStep,
                y: rect.height - CGFloat(data[i] - minValue) * yStep
            )
            path.addLine(to: point)
        }
        
        return path
    }
}

// MARK: - WORKOUT HISTORY SECTION

struct WorkoutHistorySection: View {
    let entries: [WorkoutEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Workouts")
                    .font(.h2)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(entries.count) total")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            if entries.isEmpty {
                Text("No workouts yet")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(entries.prefix(3)) { entry in
                        WorkoutEntryRow(entry: entry)
                    }
                }
            }
        }
        .fhCard()
    }
}

struct WorkoutEntryRow: View {
    let entry: WorkoutEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.type)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text(entry.date, format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.duration) min")
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text(entry.difficulty)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.bgPrimary)
        .cornerRadius(8)
    }
}

// MARK: - PROFILE EDIT SHEET

struct ProfileEditView: View {
    @EnvironmentObject var profile: ProfileManager
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var weight: Int = 150
    @State private var weightUnit: String = "lbs"
    @State private var heightCm: Int = 170
    @State private var heightFt: Int = 5
    @State private var heightIn: Int = 8
    @State private var heightMode: String = "cm"
    @State private var age: Int = 25
    @State private var level: String = ""
    @State private var equipment: Set<String> = []
    @State private var hasChanges = false

    let levelOptions = ["Beginner", "Intermediate", "Advanced"]
    let equipmentOptions = ["Body-weight", "Yoga Mat", "Jump Rope", "Resistance Bands", "Pull-up Bar", "Treadmill"]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name").font(.caption).foregroundColor(.textSecondary)
                    TextField("Enter your name", text: $name)
                        .font(.body)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight").font(.caption).foregroundColor(.textSecondary)
                    HStack {
                        Picker("", selection: $weight) {
                            ForEach(70...350, id: \.self) { v in
                                Text("\(v)").tag(v)
                            }
                        }
                        .frame(width: 80)
                        Picker("", selection: $weightUnit) {
                            Text("lbs").tag("lbs")
                            Text("kg").tag("kg")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height").font(.caption).foregroundColor(.textSecondary)
                    Picker("", selection: $heightMode) {
                        Text("cm").tag("cm")
                        Text("ft/in").tag("ft")
                    }
                    .pickerStyle(.segmented)
                    if heightMode == "cm" {
                        Picker("", selection: $heightCm) {
                            ForEach(100...220, id: \.self) { v in
                                Text("\(v) cm").tag(v)
                            }
                        }
                        .frame(width: 120)
                    } else {
                        HStack {
                            Picker("", selection: $heightFt) {
                                ForEach(3...7, id: \.self) { v in
                                    Text("\(v) ft").tag(v)
                                }
                            }
                            .frame(width: 80)
                            Picker("", selection: $heightIn) {
                                ForEach(0...11, id: \.self) { v in
                                    Text("\(v) in").tag(v)
                                }
                            }
                            .frame(width: 80)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age").font(.caption).foregroundColor(.textSecondary)
                    Picker("", selection: $age) {
                        ForEach(10...100, id: \.self) { v in
                            Text("\(v)").tag(v)
                        }
                    }
                    .frame(width: 80)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fitness Level").font(.caption).foregroundColor(.textSecondary)
                    HStack {
                        ForEach(levelOptions, id: \.self) { opt in
                            Button(action: { level = opt }) {
                                Text(opt)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(level == opt ? Color.primaryCoral : Color.bgSecondary)
                                    .foregroundColor(level == opt ? .white : Color.textPrimary)
                                    .cornerRadius(14)
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Equipment").font(.caption).foregroundColor(.textSecondary)
                    WrapHStack(items: equipmentOptions, selected: $equipment)
                }
                Spacer()
                Button(action: saveProfile) {
                    Text("Save")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasChanges ? Color.primaryCoral : Color.textSecondary)
                        .cornerRadius(14)
                }
                .disabled(!hasChanges)
                .padding(.bottom, 12)
            }
            .padding()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: loadProfile)
        }
    }

    func loadProfile() {
        name = profile.name
        weight = profile.weight
        weightUnit = "lbs"
        heightCm = profile.height
        heightMode = "cm"
        age = profile.age
        level = profile.fitnessLevel
        equipment = Set(profile.equipment)
    }

    func saveProfile() {
        profile.name = name
        profile.weight = weight
        profile.height = heightMode == "cm" ? heightCm : Int(Double(heightFt * 12 + heightIn) * 2.54)
        profile.age = age
        profile.fitnessLevel = level
        profile.equipment = Array(equipment)
        profile.saveProfile()
        dismiss()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

struct WrapHStack: View {
    let items: [String]
    @Binding var selected: Set<String>
    var body: some View {
        let rows = items.chunked(into: 3)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        Button(action: {
                            if selected.contains(item) { selected.remove(item) }
                            else { selected.insert(item) }
                        }) {
                            Text(item)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selected.contains(item) ? Color.primaryCoral : Color.bgSecondary)
                                .foregroundColor(selected.contains(item) ? .white : Color.textPrimary)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
} 

// MARK: - EDIT METRIC DIALOG

struct EditMetricDialog: View {
    let title: String
    let currentValue: Double
    let currentGoal: Double
    let unit: String
    let onSave: (Double, Double) -> Void
    let onCancel: () -> Void
    
    @State private var value: Double
    @State private var goal: Double
    @State private var isEditingValue = true
    
    init(title: String, currentValue: Double, currentGoal: Double, unit: String, onSave: @escaping (Double, Double) -> Void, onCancel: @escaping () -> Void) {
        self.title = title
        self.currentValue = currentValue
        self.currentGoal = currentGoal
        self.unit = unit
        self.onSave = onSave
        self.onCancel = onCancel
        self._value = State(initialValue: currentValue)
        self._goal = State(initialValue: currentGoal)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    // Value editing
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current \(title)")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        HStack {
                            TextField("Value", value: $value, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            Text(unit)
                                .font(.body)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    // Goal editing
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Goal")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        HStack {
                            TextField("Goal", value: $goal, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            Text(unit)
                                .font(.body)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    onSave(value, goal)
                }) {
                    Text("Save Changes")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryCoral)
                        .cornerRadius(14)
                }
            }
            .padding()
            .navigationTitle("Edit \(title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
} 

// MARK: - LOG ACTIVITY SECTION

struct LogActivitySection: View {
    @EnvironmentObject var workoutJournal: WorkoutJournal
    @State private var showAddWorkout = false
    
    // Mock calendar workouts - in a real app, this would integrate with Calendar framework
    let calendarWorkouts = [
        CalendarWorkout(title: "Morning Run", date: Date(), duration: 30, type: "Running"),
        CalendarWorkout(title: "Gym Session", date: Date().addingTimeInterval(-86400), duration: 60, type: "Strength"),
        CalendarWorkout(title: "Yoga Class", date: Date().addingTimeInterval(-172800), duration: 45, type: "Yoga"),
        CalendarWorkout(title: "Swimming", date: Date().addingTimeInterval(-259200), duration: 40, type: "Swimming")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Log Activity")
                    .font(.h2)
                    .foregroundColor(.textPrimary)
                Spacer()
                Button(action: { showAddWorkout = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.primaryCoral)
                        .font(.title2)
                }
            }
            
            // Calendar workouts
            VStack(alignment: .leading, spacing: 12) {
                Text("Calendar Workouts")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                
                LazyVStack(spacing: 8) {
                    ForEach(calendarWorkouts) { workout in
                        CalendarWorkoutRow(workout: workout) {
                            addToJournal(workout)
                        }
                    }
                }
            }
            
            // Recent journal entries
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Journal Entries")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                
                if workoutJournal.entries.isEmpty {
                    Text("No workouts logged yet")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(workoutJournal.entries.prefix(3)) { entry in
                            JournalEntryRow(entry: entry)
                        }
                    }
                }
            }
        }
        .fhCard()
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutView(selectedDate: Date())
        }
    }
    
    private func addToJournal(_ workout: CalendarWorkout) {
        let entry = WorkoutEntry(
            date: workout.date,
            exercises: [],
            type: workout.type,
            duration: workout.duration,
            mood: "Good",
            difficulty: "Medium"
        )
        workoutJournal.upsert(entry)
    }
}

struct CalendarWorkout: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let duration: Int
    let type: String
}

struct CalendarWorkoutRow: View {
    let workout: CalendarWorkout
    let onAddToJournal: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text(workout.type)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(workout.duration) min")
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text(workout.date, format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Button(action: onAddToJournal) {
                Image(systemName: "plus.circle")
                    .foregroundColor(.primaryCoral)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.bgPrimary)
        .cornerRadius(8)
    }
}

struct JournalEntryRow: View {
    let entry: WorkoutEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.type)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text(entry.date, format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.duration) min")
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text(entry.difficulty)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.bgPrimary)
        .cornerRadius(8)
    }
}

 