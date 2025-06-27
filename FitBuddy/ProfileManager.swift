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
    
    func completeOnboarding() {
        isOnboarded = true
    }
    
    func update(name: String, age: Int, weightLbs: Int, heightInches: Int, intensity: Int, equipment: [String]) {
        self.name = name
        self.age = age
        self.weight = weightLbs
        self.height = heightInches
        self.fitnessLevel = ["Beginner", "Intermediate", "Advanced", "Elite"][min(max(intensity/3,0),3)]
        self.equipment = equipment
    }
    
    func saveProfile() {}
} 