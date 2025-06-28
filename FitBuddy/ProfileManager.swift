import Foundation
import SwiftUI

class ProfileManager: ObservableObject {
    @Published var name: String = "User"
    @Published var age: Int = 25
    @Published var weight: Int = 150
    @Published var height: Int = 170
    @Published var equipment: [String] = []
    @Published var fitnessLevel: String = "Intermediate"
    @Published var isOnboarded: Bool = true
    @Published var isOnboardingComplete: Bool = true
    @Published var gender: String = "Not specified"
    @Published var goals: [String] = []
    
    func completeOnboarding() {
        isOnboarded = true
        isOnboardingComplete = true
    }
    
    func update(name: String, age: Int, weightLbs: Int, heightInches: Int, intensity: Int, equipment: [String]) {
        self.name = name
        self.age = age
        self.weight = weightLbs
        self.height = heightInches
        self.fitnessLevel = ["Beginner", "Intermediate", "Advanced", "Elite"][min(max(intensity/3,0),3)]
        self.equipment = equipment
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
    }
    
    private func extractNumber(from text: String) -> Int? {
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        return numbers.first
    }
    
    func saveProfile() {}
} 