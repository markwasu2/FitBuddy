import SwiftUI
import Combine

struct CalorieEstimate {
    let foodName: String
    let portion: String
    let calories: Double
    let macros: Macros
}

@MainActor
final class NutritionViewModel: ObservableObject {
    @Published var entries: [NutritionEntry] = []
    @Published var totalCalories: Double = 0
    @Published var calorieGoal: Double = 2000
    
    private var cancellables = Set<AnyCancellable>()
    private let geminiService = GeminiVisionService()

    init() {
        loadEntries()
        // TODO: Load calorieGoal from user profile
        $entries
            .map { $0.map(\.calories).reduce(0, +) }
            .assign(to: &$totalCalories)
    }

    func analyzeFood(image: UIImage, description: String) async throws -> CalorieEstimate {
        // Use Gemini Vision to analyze the food image and description
        let vision = try await geminiService.recognizeFood(in: image)
        
        // For now, we'll use a simplified estimation based on the vision results
        // In a real implementation, you'd send the prompt to Gemini and parse the response
        
        let estimatedCalories = estimateCalories(for: vision.foodName, portion: vision.portion)
        let macros = estimateMacros(for: vision.foodName, calories: estimatedCalories)
        
        return CalorieEstimate(
            foodName: vision.foodName,
            portion: vision.portion,
            calories: estimatedCalories,
            macros: macros
        )
    }
    
    private func estimateCalories(for foodName: String, portion: String) -> Double {
        // Simplified calorie estimation based on food type
        let lowercased = foodName.lowercased()
        
        if lowercased.contains("chicken") || lowercased.contains("meat") {
            return 250
        } else if lowercased.contains("rice") || lowercased.contains("pasta") {
            return 200
        } else if lowercased.contains("salad") || lowercased.contains("vegetables") {
            return 150
        } else if lowercased.contains("fish") || lowercased.contains("seafood") {
            return 180
        } else if lowercased.contains("bread") || lowercased.contains("sandwich") {
            return 300
        } else if lowercased.contains("soup") {
            return 120
        } else if lowercased.contains("pizza") {
            return 400
        } else if lowercased.contains("burger") {
            return 500
        } else {
            return 250 // Default estimate
        }
    }
    
    private func estimateMacros(for foodName: String, calories: Double) -> Macros {
        let lowercased = foodName.lowercased()
        
        if lowercased.contains("chicken") || lowercased.contains("meat") {
            return Macros(calories: calories, protein_g: calories * 0.4 / 4, carbs_g: calories * 0.1 / 4, fat_g: calories * 0.5 / 9)
        } else if lowercased.contains("rice") || lowercased.contains("pasta") {
            return Macros(calories: calories, protein_g: calories * 0.1 / 4, carbs_g: calories * 0.8 / 4, fat_g: calories * 0.1 / 9)
        } else if lowercased.contains("salad") || lowercased.contains("vegetables") {
            return Macros(calories: calories, protein_g: calories * 0.2 / 4, carbs_g: calories * 0.6 / 4, fat_g: calories * 0.2 / 9)
        } else if lowercased.contains("fish") || lowercased.contains("seafood") {
            return Macros(calories: calories, protein_g: calories * 0.5 / 4, carbs_g: calories * 0.05 / 4, fat_g: calories * 0.45 / 9)
        } else {
            // Default macro distribution
            return Macros(calories: calories, protein_g: calories * 0.25 / 4, carbs_g: calories * 0.5 / 4, fat_g: calories * 0.25 / 9)
        }
    }

    func saveEntry(_ entry: NutritionEntry) {
        entries.insert(entry, at: 0)
        saveEntries()
        // TODO: Sync with HealthKit
    }

    private func loadEntries() {
        // Load from CoreData/Firestore/UserDefaults
        // For now, we'll use sample data
        entries = [
            NutritionEntry(
                id: UUID(),
                photo: Data(),
                foodName: "Grilled Chicken Salad",
                portion: "1 large bowl",
                calories: 320,
                macros: Macros(calories: 320, protein_g: 35, carbs_g: 15, fat_g: 12),
                createdAt: Date()
            )
        ]
    }
    
    private func saveEntries() {
        // Save to CoreData/Firestore/UserDefaults
    }
} 