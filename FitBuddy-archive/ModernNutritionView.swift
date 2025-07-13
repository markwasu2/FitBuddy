import SwiftUI
import PhotosUI

struct ModernNutritionView: View {
    @EnvironmentObject var nutritionViewModel: NutritionViewModel
    @State private var showingImagePicker = false
    @State private var showingFoodDetail = false
    @State private var selectedEntry: NutritionEntry?
    @State private var selectedImage: UIImage?
    @State private var showingManualEntry = false
    @State private var selectedMealType: MealType = .breakfast
    
    enum MealType: String, CaseIterable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snacks = "Snacks"
        
        var icon: String {
            switch self {
            case .breakfast: return "sunrise.fill"
            case .lunch: return "sun.max.fill"
            case .dinner: return "moon.fill"
            case .snacks: return "leaf.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .breakfast: return .brandWarning
            case .lunch: return .brandSuccess
            case .dinner: return .brandSecondary
            case .snacks: return .brandPrimary
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with calorie progress
                    headerSection
                    
                    // Meal type selector
                    mealTypeSelector
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Today's nutrition summary
                    nutritionSummarySection
                    
                    // Food entries for selected meal
                    foodEntriesSection
                }
            }
            .background(Color.background)
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if let image = newValue {
                    processCapturedImage(image)
                }
            }
            .sheet(isPresented: $showingFoodDetail) {
                if let entry = selectedEntry {
                    ModernFoodDetailSheet(entry: entry) { updatedEntry in
                        // Handle save
                    }
                }
            }
            .sheet(isPresented: $showingManualEntry) {
                ModernManualEntrySheet()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: .spacing24) {
            // Calorie progress ring
            ZStack {
                ModernProgressRing(
                    progress: nutritionViewModel.totalCalories / nutritionViewModel.calorieGoal,
                    size: 140,
                    lineWidth: 10,
                    color: .brandPrimary
                )
                
                VStack(spacing: .spacing4) {
                    Text("\(Int(nutritionViewModel.totalCalories))")
                        .font(.displaySmall)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("calories")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                    
                    Text("Goal: \(Int(nutritionViewModel.calorieGoal))")
                        .font(.captionMedium)
                        .foregroundColor(.textTertiary)
                }
            }
            
            // Macro breakdown
            HStack(spacing: .spacing20) {
                MacroProgressView(
                    title: "Protein",
                    value: nutritionViewModel.entries.reduce(0) { $0 + $1.macros.protein_g },
                    goal: 150,
                    color: .proteinColor
                )
                
                MacroProgressView(
                    title: "Carbs",
                    value: nutritionViewModel.entries.reduce(0) { $0 + $1.macros.carbs_g },
                    goal: 250,
                    color: .carbsColor
                )
                
                MacroProgressView(
                    title: "Fat",
                    value: nutritionViewModel.entries.reduce(0) { $0 + $1.macros.fat_g },
                    goal: 65,
                    color: .fatColor
                )
            }
        }
        .padding(.horizontal, .spacing20)
        .padding(.top, .spacing16)
    }
    
    private var mealTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacing12) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    ModernMealTypeButton(
                        mealType: mealType,
                        isSelected: selectedMealType == mealType
                    ) {
                        selectedMealType = mealType
                    }
                }
            }
            .padding(.horizontal, .spacing20)
        }
        .padding(.vertical, .spacing12)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("Quick Add", subtitle: "Log your food quickly")
            
            HStack(spacing: .spacing12) {
                ModernQuickActionButton(
                    title: "Camera",
                    subtitle: "Snap & Track",
                    icon: "camera.fill",
                    color: .brandPrimary
                ) {
                    showingImagePicker = true
                }
                
                ModernQuickActionButton(
                    title: "Manual",
                    subtitle: "Add Food",
                    icon: "plus.circle.fill",
                    color: .brandSuccess
                ) {
                    showingManualEntry = true
                }
                
                ModernQuickActionButton(
                    title: "Barcode",
                    subtitle: "Scan Code",
                    icon: "barcode.viewfinder",
                    color: .brandWarning
                ) {
                    // TODO: Implement barcode scanning
                }
            }
            .padding(.horizontal, .spacing20)
        }
    }
    
    private var nutritionSummarySection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("Today's Summary", subtitle: "Your nutrition overview")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: .spacing16) {
                ModernMetricCard(
                    title: "Calories",
                    value: "\(Int(nutritionViewModel.totalCalories))",
                    subtitle: "Goal: \(Int(nutritionViewModel.calorieGoal))",
                    icon: "flame.fill",
                    color: .brandPrimary
                )
                
                ModernMetricCard(
                    title: "Water",
                    value: "\(nutritionViewModel.waterIntake) oz",
                    subtitle: "Goal: 64 oz",
                    icon: "drop.fill",
                    color: .brandSecondary
                )
                
                ModernMetricCard(
                    title: "Protein",
                    value: "\(Int(nutritionViewModel.entries.reduce(0) { $0 + $1.macros.protein_g }))g",
                    subtitle: "Goal: 150g",
                    icon: "leaf.fill",
                    color: .proteinColor
                )
                
                ModernMetricCard(
                    title: "Fiber",
                    value: "\(Int(nutritionViewModel.entries.reduce(0) { $0 + $1.macros.fiber_g }))g",
                    subtitle: "Goal: 25g",
                    icon: "chart.bar.fill",
                    color: .fiberColor
                )
            }
            .padding(.horizontal, .spacing20)
        }
    }
    
    private var foodEntriesSection: some View {
        VStack(spacing: .spacing16) {
            ModernSectionHeader("\(selectedMealType.rawValue)", subtitle: "Your logged foods")
            
            let mealEntries = nutritionViewModel.entries.filter { entry in
                // Filter by meal type (simplified for now)
                true
            }
            
            if mealEntries.isEmpty {
                ModernEmptyState(
                    icon: selectedMealType.icon,
                    title: "No \(selectedMealType.rawValue) Logged",
                    subtitle: "Start logging your \(selectedMealType.rawValue.lowercased()) to see it here",
                    action: {
                        showingImagePicker = true
                    },
                    actionTitle: "Log \(selectedMealType.rawValue)"
                )
                .padding(.horizontal, .spacing20)
            } else {
                VStack(spacing: .spacing12) {
                    ForEach(mealEntries, id: \.id) { entry in
                        ModernFoodEntryRow(entry: entry) {
                            selectedEntry = entry
                            showingFoodDetail = true
                        }
                    }
                }
                .padding(.horizontal, .spacing20)
            }
        }
    }
    
    private func processCapturedImage(_ image: UIImage) {
        // Process the captured image for nutrition analysis
        nutritionViewModel.analyzeImage(image) { result in
            switch result {
            case .success(let entry):
                // Handle successful analysis
                break
            case .failure(let error):
                // Handle error
                print("Error analyzing image: \(error)")
            }
        }
    }
}

// MARK: - Modern Meal Type Button
struct ModernMealTypeButton: View {
    let mealType: ModernNutritionView.MealType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: .spacing8) {
                ModernIcon(mealType.icon, size: 24, color: isSelected ? mealType.color : .textSecondary)
                
                Text(mealType.rawValue)
                    .font(.labelMedium)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? mealType.color : .textSecondary)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: .radius16)
                    .fill(isSelected ? mealType.color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: .radius16)
                            .stroke(isSelected ? mealType.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Quick Action Button
struct ModernQuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: .spacing8) {
                ModernIcon(icon, size: 24, color: color)
                
                VStack(spacing: .spacing2) {
                    Text(title)
                        .font(.labelMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.captionMedium)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.spacing16)
            .modernCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Food Entry Row
struct ModernFoodEntryRow: View {
    let entry: NutritionEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: .spacing12) {
                // Food image or placeholder
                if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: .radius8))
                } else {
                    RoundedRectangle(cornerRadius: .radius8)
                        .fill(Color.textTertiary.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            ModernIcon("camera", size: 20, color: .textTertiary)
                        )
                }
                
                VStack(alignment: .leading, spacing: .spacing4) {
                    Text(entry.foodName)
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text("\(Int(entry.calories)) calories")
                        .font(.captionMedium)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: .spacing4) {
                    Text(entry.timestamp, style: .time)
                        .font(.captionMedium)
                        .foregroundColor(.textTertiary)
                    
                    HStack(spacing: .spacing4) {
                        Text("P: \(Int(entry.macros.protein_g))g")
                            .font(.captionSmall)
                            .foregroundColor(.proteinColor)
                        
                        Text("C: \(Int(entry.macros.carbs_g))g")
                            .font(.captionSmall)
                            .foregroundColor(.carbsColor)
                        
                        Text("F: \(Int(entry.macros.fat_g))g")
                            .font(.captionSmall)
                            .foregroundColor(.fatColor)
                    }
                }
            }
            .padding(.spacing12)
            .modernCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Food Detail Sheet
struct ModernFoodDetailSheet: View {
    let entry: NutritionEntry
    let onSave: (NutritionEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing24) {
                    // Food image
                    if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: .radius16))
                    }
                    
                    // Nutrition details
                    VStack(spacing: .spacing16) {
                        ModernSectionHeader("Nutrition Facts", subtitle: "Per serving")
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: .spacing16) {
                            ModernMetricCard(
                                title: "Calories",
                                value: "\(Int(entry.calories))",
                                subtitle: "kcal",
                                icon: "flame.fill",
                                color: .brandPrimary
                            )
                            
                            ModernMetricCard(
                                title: "Protein",
                                value: "\(Int(entry.macros.protein_g))g",
                                subtitle: "Goal: 150g",
                                icon: "leaf.fill",
                                color: .proteinColor
                            )
                            
                            ModernMetricCard(
                                title: "Carbs",
                                value: "\(Int(entry.macros.carbs_g))g",
                                subtitle: "Goal: 250g",
                                icon: "chart.bar.fill",
                                color: .carbsColor
                            )
                            
                            ModernMetricCard(
                                title: "Fat",
                                value: "\(Int(entry.macros.fat_g))g",
                                subtitle: "Goal: 65g",
                                icon: "drop.fill",
                                color: .fatColor
                            )
                        }
                    }
                }
                .padding(.spacing20)
            }
            .background(Color.background)
            .navigationTitle(entry.foodName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.labelMedium)
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
}

// MARK: - Modern Manual Entry Sheet
struct ModernManualEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing24) {
                    Text("Add Food Manually")
                        .font(.headlineMedium)
                        .foregroundColor(.textPrimary)
                    
                    VStack(spacing: .spacing16) {
                        TextField("Food name", text: $foodName)
                            .modernInputStyle()
                        
                        TextField("Calories", text: $calories)
                            .modernInputStyle()
                            .keyboardType(.numberPad)
                        
                        HStack(spacing: .spacing12) {
                            TextField("Protein (g)", text: $protein)
                                .modernInputStyle()
                                .keyboardType(.numberPad)
                            
                            TextField("Carbs (g)", text: $carbs)
                                .modernInputStyle()
                                .keyboardType(.numberPad)
                            
                            TextField("Fat (g)", text: $fat)
                                .modernInputStyle()
                                .keyboardType(.numberPad)
                        }
                    }
                    
                    Button("Add Food") {
                        // Add food logic
                        dismiss()
                    }
                    .modernButtonStyle()
                    .disabled(foodName.isEmpty || calories.isEmpty)
                }
                .padding(.spacing24)
            }
            .background(Color.background)
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.labelMedium)
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
} 