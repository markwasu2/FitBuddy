import SwiftUI

struct FoodDetailSheet: View {
    @State var entry: NutritionEntry
    var onSave: (NutritionEntry) -> Void

    @State private var isEstimating = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let img = UIImage(data: entry.photo) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                TextField("Food name", text: $entry.foodName)
                    .textFieldStyle(.roundedBorder)
                TextField("Portion (e.g. 1 cup, 100g)", text: $entry.portion)
                    .textFieldStyle(.roundedBorder)
                if isEstimating {
                    ProgressView("Estimating nutrition…")
                } else {
                    Button("Estimate Nutrition") {
                        Task {
                            isEstimating = true
                            do {
                                let macros = try await CalorieEstimator.estimate(food: entry.foodName, portion: entry.portion)
                                entry.calories = macros.calories
                                entry.macros = macros
                                isEstimating = false
                            } catch {
                                self.error = "Could not estimate nutrition."
                                isEstimating = false
                            }
                        }
                    }
                }
                if let error = error {
                    Text(error).foregroundColor(.red)
                }
                Spacer()
                Button("Save") { onSave(entry) }
                    .buttonStyle(.borderedProminent)
                    .disabled(entry.calories == 0)
            }
            .padding()
            .navigationTitle("Meal Details")
        }
    }
} 