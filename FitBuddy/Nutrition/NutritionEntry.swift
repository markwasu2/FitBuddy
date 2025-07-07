import Foundation

struct Macros: Codable {
    var calories: Double
    var protein_g: Double
    var carbs_g: Double
    var fat_g: Double
}

struct NutritionEntry: Identifiable, Codable {
    var id: UUID
    var photo: Data   // compressed JPEG
    var foodName: String
    var portion: String
    var calories: Double
    var macros: Macros
    var createdAt: Date
} 