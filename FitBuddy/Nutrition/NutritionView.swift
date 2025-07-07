import SwiftUI

struct NutritionView: View {
    @StateObject private var vm = NutritionViewModel()
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                NutritionSummaryRing(calories: vm.totalCalories, goal: vm.calorieGoal)
                List(vm.entries) { entry in NutritionRow(entry: entry) }
                Spacer()
                Button("Add Meal", action: vm.addMealTapped)
                    .buttonStyle(.borderedProminent)
            }
            .sheet(item: $vm.captureCoordinator) { coord in
                coord.view
            }
            .sheet(isPresented: $vm.showDetailSheet) {
                if let entry = vm.pendingEntry {
                    FoodDetailSheet(entry: entry, onSave: { newEntry in
                        vm.saveEntry(newEntry)
                        vm.showDetailSheet = false
                    })
                }
            }
            .navigationTitle("Nutrition")
        }
    }
}

struct NutritionSummaryRing: View {
    var calories: Double
    var goal: Double
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 16)
                Circle()
                    .trim(from: 0, to: min(calories/goal, 1))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(calories))/\(Int(goal)) kcal")
                    .font(.title2).bold()
            }
            .frame(width: 120, height: 120)
            Text("Today's Calories")
                .font(.caption)
        }
    }
}

struct NutritionRow: View {
    let entry: NutritionEntry
    var body: some View {
        HStack {
            if let img = UIImage(data: entry.photo) {
                Image(uiImage: img)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Meal photo")
            }
            VStack(alignment: .leading) {
                Text(entry.foodName)
                    .font(.headline)
                Text(entry.portion)
                    .font(.subheadline)
                Text("\(Int(entry.calories)) kcal")
                    .font(.caption)
            }
            Spacer()
            Text(entry.createdAt, style: .time)
                .font(.caption2)
        }
    }
} 