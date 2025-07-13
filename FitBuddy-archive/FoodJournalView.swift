import SwiftUI

struct FoodJournalView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddFood = false
    @State private var searchText = ""
    
    var filteredEntries: [FoodEntry] {
        if searchText.isEmpty {
            return healthKitManager.foodEntries.sorted(by: { $0.timestamp > $1.timestamp })
        } else {
            return healthKitManager.foodEntries
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted(by: { $0.timestamp > $1.timestamp })
        }
    }
    
    var todayEntries: [FoodEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return healthKitManager.foodEntries.filter { entry in
            Calendar.current.isDate(entry.timestamp, inSameDayAs: today)
        }
    }
    
    var totalCaloriesToday: Double {
        todayEntries.reduce(0) { $0 + $1.calories }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection
                searchBarSection
                foodEntriesSection
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("Food Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFood = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFood) {
                AddFoodView()
                    .environmentObject(healthKitManager)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Calories")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Text("\(Int(totalCaloriesToday)) / \(healthKitManager.dailyCalorieGoal)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accent)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.background, lineWidth: 8)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: min(totalCaloriesToday / Double(healthKitManager.dailyCalorieGoal), 1.0))
                        .stroke(Color.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 60, height: 60)
                        .animation(.easeInOut(duration: 0.3), value: totalCaloriesToday)
                }
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.background)
                        .frame(height: 8)
                        .cornerRadius(4)
                    Rectangle()
                        .fill(totalCaloriesToday > Double(healthKitManager.dailyCalorieGoal) ? Color.error : Color.accent)
                        .frame(width: geometry.size.width * min(totalCaloriesToday / Double(healthKitManager.dailyCalorieGoal), 1.0), height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.3), value: totalCaloriesToday)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color.background)
    }

    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
            TextField("Search foods...", text: $searchText)
        }
        .padding()
        .background(Color.background)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top)
    }

    private var foodEntriesSection: some View {
        Group {
            if filteredEntries.isEmpty {
                foodEmptyStateSection
            } else {
                foodListSection
            }
        }
    }

    private var foodEmptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundColor(.textSecondary)
            Text(searchText.isEmpty ? "No food logged today" : "No foods found")
                .font(.headline)
                .foregroundColor(.textPrimary)
            Text(searchText.isEmpty ? "Tap the + button to add your first meal" : "Try a different search term")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var foodListSection: some View {
        List {
            ForEach(filteredEntries) { entry in
                FoodJournalEntryRow(entry: entry) {
                    healthKitManager.removeFoodEntry(entry)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct FoodJournalEntryRow: View {
    let entry: FoodEntry
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Meal type icon
            VStack {
                Image(systemName: mealTypeIcon)
                    .font(.title2)
                    .foregroundColor(mealTypeColor)
                    .frame(width: 40, height: 40)
                    .background(mealTypeColor.opacity(0.1))
                    .clipShape(Circle())
            }
            
            // Food details
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                HStack {
                    Text(entry.mealType.rawValue)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Text("•")
                        .foregroundColor(.textSecondary)
                    
                    Text(entry.timestamp, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            // Calories
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(entry.calories))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.accent)
                
                Text("cal")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Food Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this food entry?")
        }
    }
    
    private var mealTypeIcon: String {
        switch entry.mealType {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .snack: return "leaf"
        }
    }
    
    private var mealTypeColor: Color {
        switch entry.mealType {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .blue
        case .snack: return .green
        }
    }
}

struct AddFoodView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var foodName = ""
    @State private var calories = ""
    @State private var selectedMealType: FoodEntry.MealType = .breakfast
    @State private var selectedTime = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Add Food")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Log your meal or snack")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding(.top)
                
                // Food name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Food Name")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    TextField("e.g., Grilled Chicken Breast", text: $foodName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Calories
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calories")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    TextField("Enter calories", text: $calories)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Meal type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal Type")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(FoodEntry.MealType.allCases, id: \.self) { mealType in
                            MealTypeButton(
                                mealType: mealType,
                                isSelected: selectedMealType == mealType
                            ) {
                                selectedMealType = mealType
                            }
                        }
                    }
                }
                
                // Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                }
                
                // Quick calorie presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Calories")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach([100, 200, 300, 400, 500, 600], id: \.self) { calorie in
                            Button(action: {
                                calories = String(calorie)
                            }) {
                                Text("\(calorie)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.background)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Add button
                Button(action: addFood) {
                    Text("Add Food")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canAddFood ? Color.accent : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!canAddFood)
            }
            .padding()
            .background(Color.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canAddFood: Bool {
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !calories.isEmpty &&
        Int(calories) != nil
    }
    
    private func addFood() {
        guard let calorieValue = Int(calories), calorieValue > 0 else { return }
        
        let entry = FoodEntry(
            name: foodName.trimmingCharacters(in: .whitespacesAndNewlines),
            calories: Double(calorieValue),
            timestamp: selectedTime,
            mealType: selectedMealType
        )
        
        healthKitManager.addFoodEntry(entry)
        dismiss()
    }
}

struct MealTypeButton: View {
    let mealType: FoodEntry.MealType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mealTypeIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : mealTypeColor)
                
                Text(mealType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? mealTypeColor : Color.background)
            .cornerRadius(12)
        }
    }
    
    private var mealTypeIcon: String {
        switch mealType {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .snack: return "leaf"
        }
    }
    
    private var mealTypeColor: Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .blue
        case .snack: return .green
        }
    }
} 