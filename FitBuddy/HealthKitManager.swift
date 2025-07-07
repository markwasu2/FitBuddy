import Foundation
import SwiftUI
import HealthKit

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var todaySteps: Int = 0
    @Published var todayActiveCalories: Double = 0
    @Published var todayTotalCalories: Double = 0
    @Published var todayDistance: Double = 0
    @Published var todayHeartRate: Double = 0
    @Published var todaySleepHours: Double = 0
    @Published var todayBodyFatPercentage: Double = 0
    @Published var weeklySteps: [Double] = Array(repeating: 0, count: 7)
    @Published var weeklyCalories: [Double] = Array(repeating: 0, count: 7)
    @Published var weeklyDistance: [Double] = Array(repeating: 0, count: 7)
    @Published var weeklySleep: [Double] = Array(repeating: 0, count: 7)
    
    // Goals and manual editing
    @Published var dailyStepGoal: Int = 10000
    @Published var dailyCalorieGoal: Int = 2000
    @Published var dailyHeartRateGoal: Int = 60
    @Published var dailySleepGoal: Double = 8.0
    @Published var targetWeight: Double = 150.0
    @Published var targetBodyFatPercentage: Double = 15.0
    
    // Calorie goals and food journaling
    @Published var consumedCalories: Double = 0
    @Published var foodEntries: [FoodEntry] = []
    
    // Manual editing flags
    @Published var isStepsManuallyEdited = false
    @Published var isCaloriesManuallyEdited = false
    @Published var isHeartRateManuallyEdited = false
    @Published var isSleepManuallyEdited = false
    @Published var isWeightManuallyEdited = false
    @Published var isBodyFatManuallyEdited = false
    
    init() {
        requestAuthorization()
        loadGoals()
        loadManualData()
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.fetchTodayData()
                    self?.fetchWeeklyData()
                }
                if let error = error {
                    print("HealthKit authorization error: \(error)")
                }
            }
        }
    }
    
    func fetchTodayData() {
        fetchTodaySteps()
        fetchTodayCalories()
        fetchTodayDistance()
        fetchTodayHeartRate()
        fetchTodaySleep()
        fetchTodayBodyFat()
        fetchTodayConsumedCalories()
    }
    
    private func fetchTodaySteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    self?.todaySteps = Int(sum.doubleValue(for: HKUnit.count()))
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchTodayCalories() {
        guard let activeCalorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let basalCalorieType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let activeQuery = HKStatisticsQuery(quantityType: activeCalorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    self?.todayActiveCalories = sum.doubleValue(for: HKUnit.kilocalorie())
                }
            }
        }
        
        let basalQuery = HKStatisticsQuery(quantityType: basalCalorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    let basalCalories = sum.doubleValue(for: HKUnit.kilocalorie())
                    self?.todayTotalCalories = (self?.todayActiveCalories ?? 0) + basalCalories
                }
            }
        }
        
        healthStore.execute(activeQuery)
        healthStore.execute(basalQuery)
    }
    
    private func fetchTodayDistance() {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    self?.todayDistance = sum.doubleValue(for: HKUnit.mile())
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchTodayHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let average = result?.averageQuantity() {
                    self?.todayHeartRate = average.doubleValue(for: HKUnit(from: "count/min"))
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchTodayConsumedCalories() {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    self?.consumedCalories = sum.doubleValue(for: HKUnit.kilocalorie())
                }
            }
        }
        healthStore.execute(query)
    }
    
    func fetchWeeklyData() {
        fetchWeeklySteps()
        fetchWeeklyCalories()
        fetchWeeklyDistance()
        fetchWeeklySleep()
    }
    
    private func fetchWeeklySteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        for i in 0..<7 {
            let dayStart = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? now
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? now
            let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: dayEnd, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
                DispatchQueue.main.async {
                    if let sum = result?.sumQuantity() {
                        self?.weeklySteps[i] = sum.doubleValue(for: HKUnit.count())
                    }
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchWeeklyCalories() {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        for i in 0..<7 {
            let dayStart = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? now
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? now
            let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: dayEnd, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
                DispatchQueue.main.async {
                    if let sum = result?.sumQuantity() {
                        self?.weeklyCalories[i] = sum.doubleValue(for: HKUnit.kilocalorie())
                    }
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchWeeklyDistance() {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        for i in 0..<7 {
            let dayStart = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? now
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? now
            let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: dayEnd, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
                DispatchQueue.main.async {
                    if let sum = result?.sumQuantity() {
                        self?.weeklyDistance[i] = sum.doubleValue(for: HKUnit.mile())
                    }
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchWeeklySleep() {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        for i in 0..<7 {
            let dayStart = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? now
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? now
            let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: dayEnd, options: .strictStartDate)
            
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, error in
                DispatchQueue.main.async {
                    var totalSleepHours: Double = 0
                    for sample in samples ?? [] {
                        if let sleepSample = sample as? HKCategorySample {
                            let duration = sleepSample.endDate.timeIntervalSince(sleepSample.startDate)
                            totalSleepHours += duration / 3600 // Convert seconds to hours
                        }
                    }
                    self?.weeklySleep[i] = totalSleepHours
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchTodaySleep() {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                var totalSleepHours: Double = 0
                for sample in samples ?? [] {
                    if let sleepSample = sample as? HKCategorySample {
                        let duration = sleepSample.endDate.timeIntervalSince(sleepSample.startDate)
                        totalSleepHours += duration / 3600 // Convert seconds to hours
                    }
                }
                self?.todaySleepHours = totalSleepHours
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchTodayBodyFat() {
        guard let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: bodyFatType, quantitySamplePredicate: predicate, options: .discreteAverage) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let average = result?.averageQuantity() {
                    self?.todayBodyFatPercentage = average.doubleValue(for: HKUnit.percent())
                }
            }
        }
        healthStore.execute(query)
    }
    
    // MARK: - Calorie Goal Management
    
    func loadCalorieGoal() {
        dailyCalorieGoal = UserDefaults.standard.integer(forKey: "dailyCalorieGoal")
        if dailyCalorieGoal == 0 {
            dailyCalorieGoal = 2000 // Default goal
        }
    }
    
    // MARK: - Food Journaling
    
    func addFoodEntry(_ entry: FoodEntry) {
        foodEntries.append(entry)
        saveFoodEntries()
        saveFoodToHealthKit(entry)
    }
    
    func removeFoodEntry(_ entry: FoodEntry) {
        foodEntries.removeAll { $0.id == entry.id }
        saveFoodEntries()
        // Note: Removing from HealthKit is more complex, so we'll just update the local count
        fetchTodayConsumedCalories()
    }
    
    private func saveFoodEntries() {
        if let encoded = try? JSONEncoder().encode(foodEntries) {
            UserDefaults.standard.set(encoded, forKey: "foodEntries")
        }
    }
    
    func loadFoodEntries() {
        if let data = UserDefaults.standard.data(forKey: "foodEntries"),
           let decoded = try? JSONDecoder().decode([FoodEntry].self, from: data) {
            foodEntries = decoded
        }
    }
    
    private func saveFoodToHealthKit(_ entry: FoodEntry) {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else { return }
        
        let calorieQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: entry.calories)
        let sample = HKQuantitySample(type: calorieType, quantity: calorieQuantity, start: entry.timestamp, end: entry.timestamp)
        
        healthStore.save(sample) { success, error in
            if let error = error {
                print("Error saving food to HealthKit: \(error)")
            }
        }
    }
    
    func refreshData() {
        fetchTodayData()
        fetchWeeklyData()
        loadFoodEntries()
    }
    
    // MARK: - Manual Editing Functions
    
    func updateSteps(_ steps: Int) {
        todaySteps = steps
        isStepsManuallyEdited = true
        saveManualData()
    }
    
    func updateCalories(_ calories: Double) {
        todayActiveCalories = calories
        isCaloriesManuallyEdited = true
        saveManualData()
    }
    
    func updateHeartRate(_ heartRate: Double) {
        todayHeartRate = heartRate
        isHeartRateManuallyEdited = true
        saveManualData()
    }
    
    func updateSleep(_ sleepHours: Double) {
        todaySleepHours = sleepHours
        isSleepManuallyEdited = true
        saveManualData()
    }
    
    func updateBodyFat(_ bodyFat: Double) {
        todayBodyFatPercentage = bodyFat
        isBodyFatManuallyEdited = true
        saveManualData()
    }
    
    // MARK: - Goal Management
    
    func updateStepGoal(_ goal: Int) {
        dailyStepGoal = goal
        saveGoals()
    }
    
    func updateCalorieGoal(_ goal: Int) {
        dailyCalorieGoal = goal
        saveGoals()
    }
    
    func updateHeartRateGoal(_ goal: Int) {
        dailyHeartRateGoal = goal
        saveGoals()
    }
    
    func updateSleepGoal(_ goal: Double) {
        dailySleepGoal = goal
        saveGoals()
    }
    
    func updateWeightGoal(_ goal: Double) {
        targetWeight = goal
        saveGoals()
    }
    
    func updateBodyFatGoal(_ goal: Double) {
        targetBodyFatPercentage = goal
        saveGoals()
    }
    
    private func saveGoals() {
        let goals: [String: Any] = [
            "dailyStepGoal": dailyStepGoal,
            "dailyCalorieGoal": dailyCalorieGoal,
            "dailyHeartRateGoal": dailyHeartRateGoal,
            "dailySleepGoal": dailySleepGoal,
            "targetWeight": targetWeight,
            "targetBodyFatPercentage": targetBodyFatPercentage
        ]
        UserDefaults.standard.set(goals, forKey: "healthGoals")
    }
    
    private func loadGoals() {
        if let goals = UserDefaults.standard.dictionary(forKey: "healthGoals") {
            dailyStepGoal = goals["dailyStepGoal"] as? Int ?? 10000
            dailyCalorieGoal = goals["dailyCalorieGoal"] as? Int ?? 2000
            dailyHeartRateGoal = goals["dailyHeartRateGoal"] as? Int ?? 60
            dailySleepGoal = goals["dailySleepGoal"] as? Double ?? 8.0
            targetWeight = goals["targetWeight"] as? Double ?? 150.0
            targetBodyFatPercentage = goals["targetBodyFatPercentage"] as? Double ?? 15.0
        }
    }
    
    private func saveManualData() {
        let manualData: [String: Any] = [
            "todaySteps": todaySteps,
            "todayActiveCalories": todayActiveCalories,
            "todayHeartRate": todayHeartRate,
            "todaySleepHours": todaySleepHours,
            "todayBodyFatPercentage": todayBodyFatPercentage,
            "isStepsManuallyEdited": isStepsManuallyEdited,
            "isCaloriesManuallyEdited": isCaloriesManuallyEdited,
            "isHeartRateManuallyEdited": isHeartRateManuallyEdited,
            "isSleepManuallyEdited": isSleepManuallyEdited,
            "isWeightManuallyEdited": isWeightManuallyEdited,
            "isBodyFatManuallyEdited": isBodyFatManuallyEdited
        ]
        UserDefaults.standard.set(manualData, forKey: "manualHealthData")
    }
    
    private func loadManualData() {
        if let data = UserDefaults.standard.dictionary(forKey: "manualHealthData") {
            todaySteps = data["todaySteps"] as? Int ?? 0
            todayActiveCalories = data["todayActiveCalories"] as? Double ?? 0
            todayHeartRate = data["todayHeartRate"] as? Double ?? 0
            todaySleepHours = data["todaySleepHours"] as? Double ?? 0
            todayBodyFatPercentage = data["todayBodyFatPercentage"] as? Double ?? 0
            isStepsManuallyEdited = data["isStepsManuallyEdited"] as? Bool ?? false
            isCaloriesManuallyEdited = data["isCaloriesManuallyEdited"] as? Bool ?? false
            isHeartRateManuallyEdited = data["isHeartRateManuallyEdited"] as? Bool ?? false
            isSleepManuallyEdited = data["isSleepManuallyEdited"] as? Bool ?? false
            isWeightManuallyEdited = data["isWeightManuallyEdited"] as? Bool ?? false
            isBodyFatManuallyEdited = data["isBodyFatManuallyEdited"] as? Bool ?? false
        }
    }
}

// MARK: - Food Entry Model

struct FoodEntry: Identifiable, Codable {
    var id = UUID()
    let name: String
    let calories: Double
    let timestamp: Date
    let mealType: MealType
    
    enum MealType: String, CaseIterable, Codable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
    }
} 