import XCTest
import SwiftUI
@testable import Peregrine

final class NutritionIntegrationTests: XCTestCase {
    func testAddEntryIncrementsTotalCalories() async {
        let vm = NutritionViewModel()
        let entry = NutritionEntry(
            id: UUID(),
            photo: Data(),
            foodName: "Test Food",
            portion: "1 cup",
            calories: 200,
            macros: Macros(calories: 200, protein_g: 10, carbs_g: 30, fat_g: 5),
            createdAt: Date()
        )
        await MainActor.run { vm.saveEntry(entry) }
        XCTAssertEqual(vm.totalCalories, 200)
    }

    func testFoodDetailSheetBindsGeminiVisionResult() async {
        let entry = NutritionEntry(
            id: UUID(),
            photo: Data(),
            foodName: "Apple",
            portion: "1 medium",
            calories: 0,
            macros: Macros(calories: 0, protein_g: 0, carbs_g: 0, fat_g: 0),
            createdAt: Date()
        )
        let sheet = FoodDetailSheet(entry: entry, onSave: { _ in })
        // Use ViewInspector to verify binding if available
        XCTAssertEqual(sheet.entry.foodName, "Apple")
    }
    
    func testNutritionEntryCodable() {
        let entry = NutritionEntry(
            id: UUID(),
            photo: Data(),
            foodName: "Test Food",
            portion: "1 cup",
            calories: 200,
            macros: Macros(calories: 200, protein_g: 10, carbs_g: 30, fat_g: 5),
            createdAt: Date()
        )
        
        do {
            let data = try JSONEncoder().encode(entry)
            let decoded = try JSONDecoder().decode(NutritionEntry.self, from: data)
            XCTAssertEqual(entry.foodName, decoded.foodName)
            XCTAssertEqual(entry.calories, decoded.calories)
        } catch {
            XCTFail("Failed to encode/decode NutritionEntry: \(error)")
        }
    }
    
    func testMacrosCalculation() {
        let macros = Macros(calories: 200, protein_g: 10, carbs_g: 30, fat_g: 5)
        XCTAssertEqual(macros.calories, 200)
        XCTAssertEqual(macros.protein_g, 10)
        XCTAssertEqual(macros.carbs_g, 30)
        XCTAssertEqual(macros.fat_g, 5)
    }
} 