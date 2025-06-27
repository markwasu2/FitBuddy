import SwiftUI

struct ProfileEditSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var profile: ProfileManager
    
    // Local state for editing
    @State private var name: String = ""
    @State private var weightValue: Int = 70
    @State private var weightUnit: String = "lbs"
    @State private var heightValue: Int = 170
    @State private var heightUnit: String = "cm"
    @State private var age: Int = 25
    @State private var level: String = ""
    @State private var equipment: Set<String> = []
    
    // Height conversion state
    @State private var heightMode: String = "cm" // "cm" or "ft"
    @State private var feet: Int = 5
    @State private var inches: Int = 8
    
    private let equipmentOptions = ["Body-weight", "Yoga Mat", "Jump Rope", "Resistance Bands", "Pull-up Bar", "Treadmill"]
    private let levelOptions = ["Beginner", "Intermediate", "Advanced"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Name Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(#8E8E93))
                            TextField("Enter your name", text: $name)
                                .font(.system(size: 17))
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.words)
                        }
                        
                        // Weight Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weight")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(#8E8E93))
                            HStack(spacing: 16) {
                                Picker("Weight Value", selection: $weightValue) {
                                    ForEach(30...350, id: \.self) { value in
                                        Text("\(value)").tag(value)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(maxWidth: .infinity)
                                
                                Picker("Weight Unit", selection: $weightUnit) {
                                    Text("lbs").tag("lbs")
                                    Text("kg").tag("kg")
                                }
                                .pickerStyle(.wheel)
                                .frame(maxWidth: .infinity)
                            }
                            .onChange(of: weightUnit) { _ in
                                // Convert weight when unit changes
                                if weightUnit == "kg" {
                                    weightValue = Int(Double(weightValue) * 2.20462)
                                } else {
                                    weightValue = Int(Double(weightValue) / 2.20462)
                                }
                            }
                        }
                        
                        // Height Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Height")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(#8E8E93))
                            
                            Picker("Height Mode", selection: $heightMode) {
                                Text("Centimeters").tag("cm")
                                Text("Feet & Inches").tag("ft")
                            }
                            .pickerStyle(.segmented)
                            .padding(.bottom, 8)
                            
                            if heightMode == "cm" {
                                Picker("Height CM", selection: $heightValue) {
                                    ForEach(100...250, id: \.self) { value in
                                        Text("\(value) cm").tag(value)
                                    }
                                }
                                .pickerStyle(.wheel)
                            } else {
                                HStack(spacing: 16) {
                                    Picker("Feet", selection: $feet) {
                                        ForEach(3...8, id: \.self) { value in
                                            Text("\(value) ft").tag(value)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(maxWidth: .infinity)
                                    
                                    Picker("Inches", selection: $inches) {
                                        ForEach(0...11, id: \.self) { value in
                                            Text("\(value) in").tag(value)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(maxWidth: .infinity)
                                }
                                .onChange(of: feet) { _ in updateHeightCM() }
                                .onChange(of: inches) { _ in updateHeightCM() }
                            }
                        }
                        
                        // Age Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(#8E8E93))
                            Picker("Age", selection: $age) {
                                ForEach(10...100, id: \.self) { value in
                                    Text("\(value) years").tag(value)
                                }
                            }
                            .pickerStyle(.wheel)
                        }
                        
                        // Fitness Level Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fitness Level")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(#8E8E93))
                            HStack(spacing: 12) {
                                ForEach(levelOptions, id: \.self) { option in
                                    Button(action: { level = option }) {
                                        Text(option)
                                            .font(.system(size: 15, weight: .medium))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(level == option ? Color(#007BFF) : Color.clear)
                                            .foregroundColor(level == option ? .white : Color(#007BFF))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color(#007BFF), lineWidth: 1)
                                            )
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                        
                        // Equipment Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Equipment")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(#8E8E93))
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(equipmentOptions, id: \.self) { option in
                                    Button(action: {
                                        if equipment.contains(option) {
                                            equipment.remove(option)
                                        } else {
                                            equipment.insert(option)
                                        }
                                    }) {
                                        Text(option)
                                            .font(.system(size: 13, weight: .medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(equipment.contains(option) ? Color(#007BFF) : Color(#F2F2F7))
                                            .foregroundColor(equipment.contains(option) ? .white : .black)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100) // Space for save button
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: saveProfile) {
                Text("Save")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(hasChanges ? Color(#007BFF) : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!hasChanges)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }
    
    private var hasChanges: Bool {
        name != profile.profile.name ||
        weightValue != profile.profile.weight ||
        heightValue != profile.profile.height ||
        age != profile.profile.age ||
        level != profile.profile.level ||
        equipment != Set(profile.profile.equipment)
    }
    
    private func loadCurrentProfile() {
        name = profile.profile.name
        weightValue = profile.profile.weight
        weightUnit = "lbs"
        heightValue = profile.profile.height
        heightUnit = "cm"
        age = profile.profile.age
        level = profile.profile.level
        equipment = Set(profile.profile.equipment)
        
        // Convert height to feet/inches for display
        let totalInches = Int(Double(heightValue) / 2.54)
        feet = totalInches / 12
        inches = totalInches % 12
    }
    
    private func updateHeightCM() {
        let totalInches = feet * 12 + inches
        heightValue = Int(Double(totalInches) * 2.54)
    }
    
    private func saveProfile() {
        // Convert weight to lbs if needed
        let weightInLbs = weightUnit == "kg" ? Int(Double(weightValue) * 2.20462) : weightValue
        
        profile.profile.name = name
        profile.profile.weight = weightInLbs
        profile.profile.height = heightValue
        profile.profile.age = age
        profile.profile.level = level
        profile.profile.equipment = Array(equipment)
        
        profile.save()
        presentationMode.wrappedValue.dismiss()
    }
} 