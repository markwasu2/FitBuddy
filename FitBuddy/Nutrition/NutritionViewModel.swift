import SwiftUI
import Combine

@MainActor
final class NutritionViewModel: ObservableObject {
    @Published var entries: [NutritionEntry] = []
    @Published var totalCalories: Double = 0
    @Published var calorieGoal: Double = 2000
    @Published var captureCoordinator: FoodCaptureCoordinator?
    @Published var showDetailSheet: Bool = false
    @Published var pendingEntry: NutritionEntry?

    private var cancellables = Set<AnyCancellable>()

    init() {
        loadEntries()
        // TODO: Load calorieGoal from user profile
        $entries
            .map { $0.map(\.calories).reduce(0, +) }
            .assign(to: &$totalCalories)
    }

    func addMealTapped() {
        let coordinator = FoodCaptureCoordinator()
        coordinator.isPresented = true
        coordinator.onImagePicked = { [weak self] image in
            Task {
                do {
                    let vision = try await GeminiVisionService().recognizeFood(in: image)
                    let entry = NutritionEntry(
                        id: UUID(),
                        photo: image.jpegData(compressionQuality: 0.7) ?? Data(),
                        foodName: vision.foodName,
                        portion: vision.portion,
                        calories: 0,
                        macros: Macros(calories: 0, protein_g: 0, carbs_g: 0, fat_g: 0),
                        createdAt: Date()
                    )
                    await MainActor.run {
                        self?.pendingEntry = entry
                        self?.showDetailSheet = true
                    }
                } catch {
                    // Handle error (show toast)
                }
            }
        }
        captureCoordinator = coordinator
    }

    func saveEntry(_ entry: NutritionEntry) {
        entries.insert(entry, at: 0)
        saveEntries()
        // TODO: Sync with HealthKit
    }

    private func loadEntries() {
        // Load from CoreData/Firestore/UserDefaults
    }
    private func saveEntries() {
        // Save to CoreData/Firestore/UserDefaults
    }
} 