import Foundation
import SwiftUI

class ProfileManager: ObservableObject {
    @Published var name: String = "User"
    @Published var age: Int = 25
    @Published var weight: Int = 150
    @Published var height: Int = 170
    @Published var bodyFatPercentage: Double = 15.0
    @Published var equipment: [String] = []
    @Published var fitnessLevel: String = "Intermediate"
    @Published var isOnboarded: Bool = true
    @Published var isOnboardingComplete: Bool = true
    @Published var gender: String = "Not specified"
    @Published var goals: [String] = []
    @Published var dailyCalorieGoal: Int = 2000
    
    init() {
        loadProfile()
    }
    
    func completeOnboarding() {
        isOnboarded = true
        isOnboardingComplete = true
        saveProfile()
    }
    
    func update(name: String, age: Int, weightLbs: Int, heightInches: Int, intensity: Int, equipment: [String]) {
        self.name = name
        self.age = age
        self.weight = weightLbs
        self.height = heightInches
        self.fitnessLevel = ["Beginner", "Intermediate", "Advanced", "Elite"][min(max(intensity/3,0),3)]
        self.equipment = equipment
        saveProfile()
    }
    
    func updateCalorieGoal(_ goal: Int) {
        dailyCalorieGoal = goal
        saveProfile()
    }
    
    func updateProfile(_ text: String) {
        let lowercased = text.lowercased()
        
        // Parse weight updates
        if lowercased.contains("lbs") || lowercased.contains("pounds") {
            if let weight = extractNumber(from: text) {
                self.weight = weight
            }
        }
        
        // Parse height updates
        if lowercased.contains("inches") || lowercased.contains("tall") {
            if let height = extractNumber(from: text) {
                self.height = height
            }
        }
        
        // Parse age updates
        if lowercased.contains("age") || lowercased.contains("years old") {
            if let age = extractNumber(from: text) {
                self.age = age
            }
        }
        
        // Parse calorie goal updates
        if lowercased.contains("calorie") || lowercased.contains("kcal") {
            if let calories = extractNumber(from: text) {
                self.dailyCalorieGoal = calories
            }
        }
        
        // Parse equipment updates
        if lowercased.contains("equipment") || lowercased.contains("have") {
            let equipmentKeywords = ["dumbbells", "barbell", "kettlebell", "resistance bands", "pull-up bar", "bench"]
            let foundEquipment = equipmentKeywords.filter { lowercased.contains($0) }
            if !foundEquipment.isEmpty {
                self.equipment = foundEquipment
            }
        }
        
        // Parse goals updates
        if lowercased.contains("goal") || lowercased.contains("want to") {
            let goalKeywords = ["lose weight", "build muscle", "improve endurance", "get stronger", "stay healthy"]
            let foundGoals = goalKeywords.filter { lowercased.contains($0) }
            if !foundGoals.isEmpty {
                self.goals = foundGoals
            }
        }
        
        saveProfile()
    }
    
    private func extractNumber(from text: String) -> Int? {
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        return numbers.first
    }
    
    func saveProfile() {
        let profileData = [
            "name": name,
            "age": age,
            "weight": weight,
            "height": height,
            "bodyFatPercentage": bodyFatPercentage,
            "fitnessLevel": fitnessLevel,
            "equipment": equipment,
            "gender": gender,
            "goals": goals,
            "dailyCalorieGoal": dailyCalorieGoal,
            "isOnboarded": isOnboarded,
            "isOnboardingComplete": isOnboardingComplete
        ] as [String : Any]
        
        UserDefaults.standard.set(profileData, forKey: "userProfile")
    }
    
    func loadProfile() {
        if let profileData = UserDefaults.standard.dictionary(forKey: "userProfile") {
            name = profileData["name"] as? String ?? "User"
            age = profileData["age"] as? Int ?? 25
            weight = profileData["weight"] as? Int ?? 150
            height = profileData["height"] as? Int ?? 170
            bodyFatPercentage = profileData["bodyFatPercentage"] as? Double ?? 15.0
            fitnessLevel = profileData["fitnessLevel"] as? String ?? "Intermediate"
            equipment = profileData["equipment"] as? [String] ?? []
            gender = profileData["gender"] as? String ?? "Not specified"
            goals = profileData["goals"] as? [String] ?? []
            dailyCalorieGoal = profileData["dailyCalorieGoal"] as? Int ?? 2000
            isOnboarded = profileData["isOnboarded"] as? Bool ?? true
            isOnboardingComplete = profileData["isOnboardingComplete"] as? Bool ?? true
        }
    }
} 