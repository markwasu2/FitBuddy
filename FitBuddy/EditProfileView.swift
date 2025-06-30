import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var age: Int = 25
    @State private var weight: Double = 70
    @State private var weightUnit: WeightUnit = .kg
    @State private var height: Double = 170
    @State private var heightUnit: HeightUnit = .cm
    @State private var feet: Int = 5
    @State private var inches: Int = 8
    @State private var intensity: Double = 5
    @State private var selectedEquipment: Set<String> = []
    
    private let equipmentOptions = [
        "Body-weight", "Yoga Mat", "Jump Rope", "Resistance Bands", "Dumbbells",
        "Kettlebell", "Barbell", "EZ Curl Bar", "Bench", "Pull-up Bar",
        "Squat Rack", "Smith Machine", "Cable Machine", "Treadmill", "Row Erg",
        "Spin Bike", "Elliptical", "Stair Climber", "TRX Straps", "Medicine Ball",
        "Slam Ball", "Battle Ropes", "Plyo Box", "Foam Roller", "Stability Ball",
        "BOSU", "Sled", "Climbing Wall"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Name Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Name")
                                .font(.headline)
                                .foregroundColor(Color.textSecondary)
                            
                            TextField("Enter your name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.title3)
                                .textInputAutocapitalization(.words)
                        }
                        .background(Color.bgSecondary)
                        .padding(.horizontal)
                        
                        // Weight Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Weight")
                                .font(.headline)
                                .foregroundColor(Color.textSecondary)
                            
                            VStack(spacing: 16) {
                                Picker("Weight Unit", selection: $weightUnit) {
                                    Text("kg").tag(WeightUnit.kg)
                                    Text("lbs").tag(WeightUnit.lbs)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                
                                HStack {
                                    WheelPickerDouble(value: $weight, range: 0...600, step: 1)
                                        .frame(height: 120)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(weightUnit == .kg ? "kg" : "lbs")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        
                                        Text("≈ \(convertedWeightText)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 60)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Height Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Height")
                                .font(.headline)
                                .foregroundColor(Color.textSecondary)
                            
                            VStack(spacing: 16) {
                                Picker("Height Unit", selection: $heightUnit) {
                                    Text("cm").tag(HeightUnit.cm)
                                    Text("ft·in").tag(HeightUnit.ftIn)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                
                                if heightUnit == .cm {
                                    HStack {
                                        WheelPickerDouble(value: $height, range: 50...250, step: 1)
                                            .frame(height: 120)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("cm")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                            
                                            Text("≈ \(convertedHeightText)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(width: 60)
                                    }
                                } else {
                                    HStack(spacing: 20) {
                                        VStack {
                                            Text("ft")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            WheelPicker(value: $feet, range: 0...8, step: 1)
                                                .frame(height: 120)
                                        }
                                        
                                        VStack {
                                            Text("in")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            WheelPicker(value: $inches, range: 0...11, step: 1)
                                                .frame(height: 120)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("ft·in")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                            
                                            Text("≈ \(convertedHeightText)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(width: 60)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Age Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Age")
                                .font(.headline)
                                .foregroundColor(Color.textSecondary)
                            
                            HStack {
                                WheelPicker(value: $age, range: 5...100, step: 1)
                                    .frame(height: 120)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("years")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .frame(width: 60)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Intensity Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fitness Intensity")
                                .font(.headline)
                                .foregroundColor(Color.textSecondary)
                            
                            VStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("1")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("10")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Slider(value: $intensity, in: 1...10, step: 1)
                                        .accentColor(.blue)
                                }
                                
                                Text(intensityLabel)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Equipment Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Available Equipment")
                                .font(.headline)
                                .foregroundColor(Color.textSecondary)
                            
                            ChipFlowLayout(items: equipmentOptions, selectedItems: $selectedEquipment)
                        }
                        .padding(.horizontal)
                        
                        // Bottom spacing for save button
                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
                
                // Save Button
                VStack {
                    Spacer()
                    SaveButton(isEnabled: canSave) {
                        saveProfile()
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
    }
    
    private var convertedWeightText: String {
        if weightUnit == .kg {
            let lbs = weight * 2.20462
            return String(format: "%.1f lbs", lbs)
        } else {
            let kg = weight / 2.20462
            return String(format: "%.1f kg", kg)
        }
    }
    
    private var convertedHeightText: String {
        if heightUnit == .cm {
            let totalInches = height / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)' \(inches)\""
        } else {
            let totalInches = Double(feet * 12 + inches)
            let cm = totalInches * 2.54
            return String(format: "%.0f cm", cm)
        }
    }
    
    private var intensityLabel: String {
        switch intensity {
        case 1...3: return "Beginner"
        case 4...6: return "Intermediate"
        case 7...8: return "Advanced"
        case 9...10: return "Elite"
        default: return "Intermediate"
        }
    }
    
    private var canSave: Bool {
        !name.isEmpty && age > 0
    }
    
    private func loadCurrentProfile() {
        name = profileManager.name
        age = profileManager.age
        weight = Double(profileManager.weight)
        height = Double(profileManager.height)
        selectedEquipment = Set(profileManager.equipment)
        
        // Convert fitness level to intensity
        switch profileManager.fitnessLevel.lowercased() {
        case "beginner": intensity = 3
        case "intermediate": intensity = 6
        case "advanced": intensity = 8
        default: intensity = 5
        }
    }
    
    private func saveProfile() {
        // Convert weight to lbs for storage
        let weightInLbs: Int
        if weightUnit == .kg {
            weightInLbs = Int(weight * 2.20462)
        } else {
            weightInLbs = Int(weight)
        }
        
        // Convert height to inches for storage
        let heightInInches: Int
        if heightUnit == .cm {
            heightInInches = Int(height / 2.54)
        } else {
            heightInInches = feet * 12 + inches
        }
        
        // Convert intensity to fitness level (handled by ProfileManager)
        switch intensity {
        case 1...3: break
        case 4...6: break
        case 7...8: break
        case 9...10: break
        default: break
        }
        
        profileManager.update(
            name: name,
            age: age,
            weightLbs: weightInLbs,
            heightInches: heightInInches,
            intensity: Int(intensity),
            equipment: Array(selectedEquipment)
        )
        profileManager.saveProfile()
        dismiss()
    }
}

enum WeightUnit {
    case kg, lbs
}

enum HeightUnit {
    case cm, ftIn
}

struct SaveButton: View {
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack {
                Image(systemName: "checkmark")
                Text("Save")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.blue : Color.gray)
            .cornerRadius(25)
        }
        .disabled(!isEnabled)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

#Preview {
    EditProfileView()
        .environmentObject(ProfileManager())
} 