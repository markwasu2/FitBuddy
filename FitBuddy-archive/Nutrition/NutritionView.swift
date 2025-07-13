import SwiftUI
import PhotosUI

struct NutritionView: View {
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
            case .breakfast: return .orange
            case .lunch: return .yellow
            case .dinner: return .purple
            case .snacks: return .green
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
                    FoodDetailSheet(entry: entry) { updatedEntry in
                        // Handle save
                    }
                }
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualEntrySheet()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Calorie progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: min(nutritionViewModel.totalCalories / nutritionViewModel.calorieGoal, 1.0))
                    .stroke(Color.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: nutritionViewModel.totalCalories)
                
                VStack(spacing: 4) {
                    Text("\(Int(nutritionViewModel.totalCalories))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("calories")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            
            // Macro breakdown
            HStack(spacing: 20) {
                MacroProgressView(
                    title: "Protein",
                    value: nutritionViewModel.entries.reduce(0) { $0 + $1.macros.protein_g },
                    goal: 150,
                    color: .blue
                )
                
                MacroProgressView(
                    title: "Carbs",
                    value: nutritionViewModel.entries.reduce(0) { $0 + $1.macros.carbs_g },
                    goal: 250,
                    color: .green
                )
                
                MacroProgressView(
                    title: "Fat",
                    value: nutritionViewModel.entries.reduce(0) { $0 + $1.macros.fat_g },
                    goal: 65,
                    color: .orange
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var mealTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    NutritionMealTypeButton(
                        mealType: mealType,
                        isSelected: selectedMealType == mealType
                    ) {
                        selectedMealType = mealType
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 10)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Add")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Camera",
                    subtitle: "Snap & Track",
                    icon: "camera.fill",
                    color: .accent
                ) {
                    showingImagePicker = true
                }
                
                QuickActionButton(
                    title: "Manual",
                    subtitle: "Add Food",
                    icon: "plus.circle.fill",
                    color: .success
                ) {
                    showingManualEntry = true
                }
                
                QuickActionButton(
                    title: "Barcode",
                    subtitle: "Scan Code",
                    icon: "barcode.viewfinder",
                    color: .warning
                ) {
                    // TODO: Implement barcode scanning
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var nutritionSummarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to detailed nutrition view
                }
                .font(.subheadline)
                .foregroundColor(.accent)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    NutritionSummaryCard(
                        title: "Calories",
                        value: "\(Int(nutritionViewModel.totalCalories))",
                        subtitle: "Goal: \(Int(nutritionViewModel.calorieGoal))",
                        icon: "flame.fill",
                        color: .warning,
                        progress: nutritionViewModel.totalCalories / nutritionViewModel.calorieGoal
                    )
                    
                    NutritionSummaryCard(
                        title: "Protein",
                        value: "\(Int(nutritionViewModel.entries.reduce(0) { $0 + $1.macros.protein_g }))g",
                        subtitle: "Goal: 150g",
                        icon: "dumbbell.fill",
                        color: .blue,
                        progress: nutritionViewModel.entries.reduce(0) { $0 + $1.macros.protein_g } / 150
                    )
                    
                    NutritionSummaryCard(
                        title: "Water",
                        value: "8",
                        subtitle: "Goal: 8 cups",
                        icon: "drop.fill",
                        color: .blue,
                        progress: 0.5
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var foodEntriesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("\(selectedMealType.rawValue) Foods")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button("Add Food") {
                    showingManualEntry = true
                }
                .font(.subheadline)
                .foregroundColor(.accent)
            }
            .padding(.horizontal, 20)
            
            if nutritionViewModel.entries.isEmpty {
                EmptyStateView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(nutritionViewModel.entries.prefix(10), id: \.id) { entry in
                        ModernFoodEntryRow(entry: entry) {
                            selectedEntry = entry
                            showingFoodDetail = true
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func processCapturedImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let entry = NutritionEntry(
            id: UUID(),
            photo: imageData,
            foodName: "Analyzing...",
            portion: "1 serving",
            calories: 0,
            macros: Macros(calories: 0, protein_g: 0, carbs_g: 0, fat_g: 0),
            createdAt: Date()
        )
        
        nutritionViewModel.saveEntry(entry)
        selectedImage = nil
    }
}

// MARK: - Supporting Views

struct MacroProgressView: View {
    let title: String
    let value: Double
    let goal: Double
    let color: Color
    
    private var progress: Double {
        min(value / goal, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
            }
            
            VStack(spacing: 2) {
                Text("\(Int(value))g")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

struct NutritionMealTypeButton: View {
    let mealType: NutritionView.MealType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mealType.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : mealType.color)
                
                Text(mealType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .textPrimary)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? mealType.color : Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? mealType.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NutritionSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
        .padding(16)
        .background(Color.surface)
        .cornerRadius(12)
        .frame(width: 160)
    }
}

struct ModernFoodEntryRow: View {
    let entry: NutritionEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Food image
                if let uiImage = UIImage(data: entry.photo) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.textTertiary.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .foregroundColor(.textTertiary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.foodName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    Text(entry.portion)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(entry.calories))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("cal")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(12)
            .background(Color.surface)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)
            
            VStack(spacing: 8) {
                Text("No foods logged yet")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text("Start by taking a photo or adding food manually")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct ManualEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var foodName = ""
    @State private var portion = ""
    @State private var calories = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: .spacingL) {
                VStack(spacing: .spacingM) {
                    TextField("Food Name", text: $foodName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("Portion", text: $portion)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("Calories", text: $calories)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                Button("Save Entry") {
                    // TODO: Save entry
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding(.spacingM)
            .background(Color.background)
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accent)
                }
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        // Check if camera is available
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            // Fallback to photo library if camera is not available
            picker.sourceType = .photoLibrary
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                
                // Process the image for nutrition analysis
                Task {
                    await processImageForNutrition(image)
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        private func processImageForNutrition(_ image: UIImage) async {
            // Convert image to data for storage
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
            
            // Create a nutrition entry with the captured image
            let entry = NutritionEntry(
                id: UUID(),
                photo: imageData,
                foodName: "Analyzing...",
                portion: "1 serving",
                calories: 0,
                macros: Macros(calories: 0, protein_g: 0, carbs_g: 0, fat_g: 0),
                createdAt: Date()
            )
            
            // Add to nutrition view model
            DispatchQueue.main.async {
                // This would need to be injected or accessed via environment
                // For now, we'll just store the image
                print("Image captured for nutrition analysis")
            }
        }
    }
} 