import Foundation
import SwiftUI
import EventKit

// MARK: - Fitness Level Assessment
enum FitnessLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var description: String {
        switch self {
        case .beginner:
            return "New to fitness or returning after a long break"
        case .intermediate:
            return "Regular exercise routine, some experience"
        case .advanced:
            return "Consistent training, high fitness level"
        }
    }
}

// MARK: - Workout Preferences
struct WorkoutPreferences: Codable {
    var fitnessLevel: FitnessLevel = .beginner
    var preferredWorkoutTypes: [WorkoutType] = []
    var availableEquipment: [Equipment] = []
    var workoutDuration: WorkoutDuration = .medium
    var daysPerWeek: Int = 3
    var preferredTime: WorkoutTime = .evening
    var goals: [FitnessGoal] = []
    
    var isComplete: Bool {
        !preferredWorkoutTypes.isEmpty && !availableEquipment.isEmpty && !goals.isEmpty
    }
}

enum WorkoutType: String, CaseIterable, Codable {
    case strength = "Strength Training"
    case cardio = "Cardio"
    case yoga = "Yoga"
    case hiit = "HIIT"
    case pilates = "Pilates"
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case boxing = "Boxing"
    case dance = "Dance"
    
    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .yoga: return "figure.mind.and.body"
        case .hiit: return "bolt.fill"
        case .pilates: return "figure.core.training"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .boxing: return "figure.boxing"
        case .dance: return "figure.dance"
        }
    }
}

enum Equipment: String, CaseIterable, Codable {
    case none = "No Equipment"
    case dumbbells = "Dumbbells"
    case resistanceBands = "Resistance Bands"
    case yogaMat = "Yoga Mat"
    case pullUpBar = "Pull-up Bar"
    case treadmill = "Treadmill"
    case stationaryBike = "Stationary Bike"
    case fullGym = "Full Gym Access"
    
    var icon: String {
        switch self {
        case .none: return "figure.walk"
        case .dumbbells: return "dumbbell.fill"
        case .resistanceBands: return "bandage.fill"
        case .yogaMat: return "rectangle.fill"
        case .pullUpBar: return "minus.rectangle.fill"
        case .treadmill: return "figure.run"
        case .stationaryBike: return "bicycle"
        case .fullGym: return "building.2.fill"
        }
    }
}

enum WorkoutDuration: String, CaseIterable, Codable {
    case short = "15-30 minutes"
    case medium = "30-45 minutes"
    case long = "45-60 minutes"
    case extended = "60+ minutes"
    
    var minutes: Int {
        switch self {
        case .short: return 25
        case .medium: return 37
        case .long: return 52
        case .extended: return 75
        }
    }
}

enum WorkoutTime: String, CaseIterable, Codable {
    case morning = "Morning (6-9 AM)"
    case afternoon = "Afternoon (12-3 PM)"
    case evening = "Evening (6-9 PM)"
    case flexible = "Flexible"
    
    var timeString: String {
        switch self {
        case .morning: return "7:00 AM"
        case .afternoon: return "1:00 PM"
        case .evening: return "6:00 PM"
        case .flexible: return "6:00 PM"
        }
    }
}

enum FitnessGoal: String, CaseIterable, Codable {
    case weightLoss = "Weight Loss"
    case muscleGain = "Muscle Gain"
    case endurance = "Endurance"
    case flexibility = "Flexibility"
    case strength = "Strength"
    case generalFitness = "General Fitness"
    case stressRelief = "Stress Relief"
    
    var icon: String {
        switch self {
        case .weightLoss: return "scalemass.fill"
        case .muscleGain: return "dumbbell.fill"
        case .endurance: return "heart.fill"
        case .flexibility: return "figure.flexibility"
        case .strength: return "bolt.fill"
        case .generalFitness: return "figure.walk"
        case .stressRelief: return "brain.head.profile"
        }
    }
}

// MARK: - Personalized Workout Plan
struct PersonalizedWorkoutPlan: Codable, Identifiable {
    var id: UUID = UUID()
    let title: String
    let description: String
    let exercises: [PersonalizedExercise]
    let duration: Int // minutes
    let difficulty: FitnessLevel
    let equipment: [Equipment]
    let targetMuscleGroups: [String]
    let workoutType: WorkoutType
    let scheduledDays: [WeekDay]
    let preferences: WorkoutPreferences
    
    var formattedDuration: String {
        return "\(duration) min"
    }
    
    var formattedSchedule: String {
        let dayNames = scheduledDays.map { $0.shortName }.joined(separator: ", ")
        return "\(dayNames) at \(preferences.preferredTime.timeString)"
    }
}

struct PersonalizedExercise: Codable, Identifiable {
    var id: UUID = UUID()
    let name: String
    let sets: Int
    let reps: Int
    let weight: Double?
    let duration: Int? // seconds
    let restTime: Int // seconds
    let instructions: String
    let muscleGroup: String
    let equipment: Equipment?
    let difficulty: FitnessLevel
    let alternatives: [String] // Alternative exercises for different equipment
    
    var formattedSets: String {
        if let duration = duration {
            return "\(sets) sets × \(duration)s"
        } else {
            return "\(sets) sets × \(reps) reps"
        }
    }
    
    var formattedRest: String {
        return "\(restTime)s rest"
    }
}

enum WeekDay: String, CaseIterable, Codable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    var shortName: String {
        String(rawValue.prefix(3))
    }
    
    var calendarWeekday: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}

// MARK: - Enhanced Workout Plan Manager
class WorkoutPlanManager: ObservableObject {
    @Published var plans: [WorkoutPlan] = []
    @Published var personalizedPlans: [PersonalizedWorkoutPlan] = []
    @Published var preferences: WorkoutPreferences = WorkoutPreferences()
    @Published var isPersonalizationComplete = false
    
    private let eventStore = EKEventStore()
    private let googleCalendarService = GoogleCalendarService()
    
    init() {
        loadPreferences()
        loadPersonalizedPlans()
        requestCalendarAccess()
    }
    
    // MARK: - Preferences Management
    func updatePreferences(_ newPreferences: WorkoutPreferences) {
        preferences = newPreferences
        savePreferences()
        
        if preferences.isComplete {
            generatePersonalizedWorkouts()
        }
    }
    
    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "workoutPreferences")
        }
    }
    
    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: "workoutPreferences"),
           let decoded = try? JSONDecoder().decode(WorkoutPreferences.self, from: data) {
            preferences = decoded
        }
    }
    
    // MARK: - Personalized Workout Generation
    func generatePersonalizedWorkouts() {
        personalizedPlans.removeAll()
        
        // Generate workouts based on preferences
        for workoutType in preferences.preferredWorkoutTypes {
            let plan = createPersonalizedPlan(for: workoutType)
            personalizedPlans.append(plan)
        }
        
        savePersonalizedPlans()
        scheduleWorkoutsInCalendar()
        
        isPersonalizationComplete = true
    }
    
    private func createPersonalizedPlan(for workoutType: WorkoutType) -> PersonalizedWorkoutPlan {
        let exercises = generateExercises(for: workoutType)
        let scheduledDays = generateSchedule()
        
        return PersonalizedWorkoutPlan(
            title: "\(workoutType.rawValue) - \(preferences.fitnessLevel.rawValue)",
            description: "Personalized \(workoutType.rawValue) workout for \(preferences.fitnessLevel.rawValue) level",
            exercises: exercises,
            duration: preferences.workoutDuration.minutes,
            difficulty: preferences.fitnessLevel,
            equipment: preferences.availableEquipment,
            targetMuscleGroups: getTargetMuscleGroups(for: workoutType),
            workoutType: workoutType,
            scheduledDays: scheduledDays,
            preferences: preferences
        )
    }
    
    private func generateExercises(for workoutType: WorkoutType) -> [PersonalizedExercise] {
        var exercises: [PersonalizedExercise] = []
        
        switch workoutType {
        case .strength:
            exercises = generateStrengthExercises()
        case .cardio:
            exercises = generateCardioExercises()
        case .yoga:
            exercises = generateYogaExercises()
        case .hiit:
            exercises = generateHIITExercises()
        case .pilates:
            exercises = generatePilatesExercises()
        case .running:
            exercises = generateRunningExercises()
        case .cycling:
            exercises = generateCyclingExercises()
        case .swimming:
            exercises = generateSwimmingExercises()
        case .boxing:
            exercises = generateBoxingExercises()
        case .dance:
            exercises = generateDanceExercises()
        }
        
        return exercises
    }
    
    private func generateStrengthExercises() -> [PersonalizedExercise] {
        let baseExercises = [
            ("Push-ups", 3, 10, nil, nil, 60, "Standard push-ups", "Chest", .none),
            ("Squats", 3, 15, nil, nil, 60, "Bodyweight squats", "Legs", .none),
            ("Plank", 3, nil, nil, 30, 60, "Hold plank position", "Core", .none),
            ("Lunges", 3, 10, nil, nil, 60, "Alternating lunges", "Legs", .none)
        ]
        
        return baseExercises.map { name, sets, reps, weight, duration, rest, instructions, muscle, equipment in
            PersonalizedExercise(
                name: name,
                sets: sets,
                reps: reps ?? 0,
                weight: weight,
                duration: duration,
                restTime: rest,
                instructions: instructions,
                muscleGroup: muscle,
                equipment: equipment,
                difficulty: preferences.fitnessLevel,
                alternatives: []
            )
        }
    }
    
    private func generateCardioExercises() -> [PersonalizedExercise] {
        return [
            PersonalizedExercise(
                name: "Jumping Jacks",
                sets: 3,
                reps: 0,
                weight: nil,
                duration: 60,
                restTime: 30,
                instructions: "Jump while raising arms overhead",
                muscleGroup: "Full Body",
                equipment: .none,
                difficulty: preferences.fitnessLevel,
                alternatives: ["High Knees", "Mountain Climbers"]
            ),
            PersonalizedExercise(
                name: "Burpees",
                sets: 3,
                reps: 0,
                weight: nil,
                duration: 45,
                restTime: 60,
                instructions: "Squat, push-up, jump sequence",
                muscleGroup: "Full Body",
                equipment: .none,
                difficulty: preferences.fitnessLevel,
                alternatives: ["Squat Thrusts", "Modified Burpees"]
            )
        ]
    }
    
    private func generateYogaExercises() -> [PersonalizedExercise] {
        return [
            PersonalizedExercise(
                name: "Sun Salutation",
                sets: 3,
                reps: 0,
                weight: nil,
                duration: 120,
                restTime: 30,
                instructions: "Complete sun salutation sequence",
                muscleGroup: "Full Body",
                equipment: .yogaMat,
                difficulty: preferences.fitnessLevel,
                alternatives: ["Modified Sun Salutation"]
            )
        ]
    }
    
    private func generateHIITExercises() -> [PersonalizedExercise] {
        return [
            PersonalizedExercise(
                name: "High Intensity Intervals",
                sets: 8,
                reps: 0,
                weight: nil,
                duration: 30,
                restTime: 15,
                instructions: "30 seconds work, 15 seconds rest",
                muscleGroup: "Full Body",
                equipment: .none,
                difficulty: preferences.fitnessLevel,
                alternatives: ["Modified Intervals"]
            )
        ]
    }
    
    private func generatePilatesExercises() -> [PersonalizedExercise] {
        return [
            PersonalizedExercise(
                name: "Hundred",
                sets: 1,
                reps: 0,
                weight: nil,
                duration: 60,
                restTime: 30,
                instructions: "Classic Pilates hundred exercise",
                muscleGroup: "Core",
                equipment: .yogaMat,
                difficulty: preferences.fitnessLevel,
                alternatives: ["Modified Hundred"]
            )
        ]
    }
    
    private func generateRunningExercises() -> [PersonalizedExercise] {
        return [
            PersonalizedExercise(
                name: "Interval Running",
                sets: 5,
                reps: 0,
                weight: nil,
                duration: 300,
                restTime: 120,
                instructions: "5 minutes run, 2 minutes walk",
                muscleGroup: "Cardiovascular",
                equipment: .none,
                difficulty: preferences.fitnessLevel,
                alternatives: ["Walking", "Jogging"]
            )
        ]
    }
    
    private func generateCyclingExercises() -> [PersonalizedExercise] {
        return [
            PersonalizedExercise(
                name: "Cycling Intervals",
                sets: 4,
                reps: 0,
                weight: nil,
                duration: 600,
                restTime: 180,
                instructions: "10 minutes cycling, 3 minutes rest",
                muscleGroup: "Cardiovascular",
                equipment: .stationaryBike,
                difficulty: preferences.fitnessLevel,
                alternatives: ["Outdoor Cycling"]
            )
        ]
    }
    
    private func generateSwimmingExercises() -> [PersonalizedExercise] {
        return [
            PersonalizedExercise(
                name: "Swimming Laps",
                sets: 4,
                reps: 0,
                weight: nil,
                duration: 300,
                restTime: 60,
                instructions: "5 minutes swimming, 1 minute rest",
                muscleGroup: "Full Body",
                equipment: .none,
                difficulty: preferences.fitnessLevel,
                alternatives: ["Water Aerobics"]
            )
        ]
    }
    
    private func generateBoxingExercises() -> [PersonalizedExercise] {
        return [
            PersonalizedExercise(
                name: "Shadow Boxing",
                sets: 3,
                reps: 0,
                weight: nil,
                duration: 180,
                restTime: 60,
                instructions: "3 minutes shadow boxing combinations",
                muscleGroup: "Upper Body",
                equipment: .none,
                difficulty: preferences.fitnessLevel,
                alternatives: ["Heavy Bag Work"]
            )
        ]
    }
    
    private func generateDanceExercises() -> [PersonalizedExercise] {
        return [
            PersonalizedExercise(
                name: "Dance Cardio",
                sets: 1,
                reps: 0,
                weight: nil,
                duration: 1200,
                restTime: 0,
                instructions: "20 minutes dance cardio routine",
                muscleGroup: "Full Body",
                equipment: .none,
                difficulty: preferences.fitnessLevel,
                alternatives: ["Zumba", "Hip Hop Dance"]
            )
        ]
    }
    
    private func generateSchedule() -> [WeekDay] {
        let allDays: [WeekDay] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
        let daysPerWeek = preferences.daysPerWeek
        
        // Distribute workouts evenly
        var selectedDays: [WeekDay] = []
        let step = allDays.count / daysPerWeek
        
        for i in 0..<daysPerWeek {
            let index = i * step
            if index < allDays.count {
                selectedDays.append(allDays[index])
            }
        }
        
        return selectedDays
    }
    
    private func getTargetMuscleGroups(for workoutType: WorkoutType) -> [String] {
        switch workoutType {
        case .strength:
            return ["Full Body", "Core", "Upper Body", "Lower Body"]
        case .cardio, .hiit:
            return ["Cardiovascular", "Full Body"]
        case .yoga, .pilates:
            return ["Core", "Flexibility", "Balance"]
        case .running, .cycling:
            return ["Cardiovascular", "Lower Body"]
        case .swimming:
            return ["Full Body", "Cardiovascular"]
        case .boxing:
            return ["Upper Body", "Core", "Cardiovascular"]
        case .dance:
            return ["Full Body", "Cardiovascular", "Coordination"]
        }
    }
    
    // MARK: - Calendar Integration
    private func requestCalendarAccess() {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        print("Calendar access granted")
                    } else {
                        print("Calendar access denied: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        print("Calendar access granted")
                    } else {
                        print("Calendar access denied: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
    }
    
    func scheduleWorkoutsInCalendar() {
        for plan in personalizedPlans {
            for day in plan.scheduledDays {
                scheduleWorkout(plan, on: day)
            }
        }
    }
    
    private func scheduleWorkout(_ plan: PersonalizedWorkoutPlan, on day: WeekDay) {
        let calendar = Calendar.current
        let now = Date()
        
        // Find next occurrence of this weekday
        var nextDate = now
        while calendar.component(.weekday, from: nextDate) != day.calendarWeekday {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
        }
        
        // Set the time based on preferences
        let timeString = plan.preferences.preferredTime.timeString
        let scheduledDate = parseDateTime(date: nextDate, time: timeString)
        
        // Add to iOS Calendar
        addToIOSCalendar(title: plan.title, date: scheduledDate, description: plan.description)
        
        // Add to Google Calendar (if configured)
        addToGoogleCalendar(title: plan.title, date: scheduledDate, description: plan.description)
        
        print("🎯 Scheduled: \(plan.title) on \(day.rawValue) at \(timeString)")
    }
    
    private func parseDateTime(date: Date, time: String) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Parse time string (e.g., "7:00 AM", "6:00 PM")
        let timeComponents = parseTimeString(time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        return calendar.date(from: components) ?? date
    }
    
    private func parseTimeString(_ timeString: String) -> (hour: Int, minute: Int) {
        let lowercased = timeString.lowercased()
        
        if lowercased.contains("am") || lowercased.contains("pm") {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            if let date = formatter.date(from: timeString) {
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                return (components.hour ?? 9, components.minute ?? 0)
            }
        }
        
        return (9, 0)
    }
    
    private func addToIOSCalendar(title: String, date: Date, description: String) {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = description
        event.startDate = date
        event.endDate = Calendar.current.date(byAdding: .minute, value: 60, to: date) ?? date
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ Added to iOS Calendar: \(title)")
        } catch {
            print("❌ Failed to add to iOS Calendar: \(error.localizedDescription)")
        }
    }
    
    private func addToGoogleCalendar(title: String, date: Date, description: String) {
        googleCalendarService.addWorkoutToGoogleCalendar(title: title, date: date, description: description) { success in
            if success {
                print("✅ Added to Google Calendar: \(title)")
            } else {
                print("❌ Failed to add to Google Calendar: \(title)")
            }
        }
    }
    
    // MARK: - Persistence
    private func savePersonalizedPlans() {
        if let encoded = try? JSONEncoder().encode(personalizedPlans) {
            UserDefaults.standard.set(encoded, forKey: "personalizedWorkoutPlans")
        }
    }
    
    private func loadPersonalizedPlans() {
        if let data = UserDefaults.standard.data(forKey: "personalizedWorkoutPlans"),
           let decoded = try? JSONDecoder().decode([PersonalizedWorkoutPlan].self, from: data) {
            personalizedPlans = decoded
            isPersonalizationComplete = !personalizedPlans.isEmpty
        }
    }
    
    // MARK: - Public Methods
    func resetPersonalization() {
        personalizedPlans.removeAll()
        preferences = WorkoutPreferences()
        isPersonalizationComplete = false
        savePreferences()
        savePersonalizedPlans()
    }
    
    func getWorkoutsForDate(_ date: Date) -> [PersonalizedWorkoutPlan] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        return personalizedPlans.filter { plan in
            plan.scheduledDays.contains { day in
                day.calendarWeekday == weekday
            }
        }
    }
} 