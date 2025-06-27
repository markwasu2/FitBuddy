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
                                .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                            TextField("Enter your name", text: $name)
                                .font(.system(size: 17))
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.words)
                        }
                        
                        // Weight Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weight")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
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
                            .onChange(of: weightUnit) { oldValue, newValue in
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
                                .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                            
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
                                .onChange(of: feet) { oldValue, newValue in updateHeightCM() }
                                .onChange(of: inches) { oldValue, newValue in updateHeightCM() }
                            }
                        }
                        
                        // Age Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
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
                                .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                            HStack(spacing: 12) {
                                ForEach(levelOptions, id: \.self) { option in
                                    Button(action: { level = option }) {
                                        Text(option)
                                            .font(.system(size: 15, weight: .medium))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(level == option ? Color(red: 0/255, green: 123/255, blue: 255/255) : Color.clear)
                                            .foregroundColor(level == option ? .white : Color(red: 0/255, green: 123/255, blue: 255/255))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color(red: 0/255, green: 123/255, blue: 255/255), lineWidth: 1)
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
                                .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
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
                                            .background(equipment.contains(option) ? Color(red: 0/255, green: 123/255, blue: 255/255) : Color(red: 242/255, green: 242/255, blue: 247/255))
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
                    .background(hasChanges ? Color(red: 0/255, green: 123/255, blue: 255/255) : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!hasChanges)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }
    
    private var hasChanges: Bool {
        name != profile.name ||
        weightValue != profile.weight ||
        heightValue != profile.height ||
        age != profile.age ||
        level != profile.fitnessLevel ||
        equipment != Set(profile.equipment)
    }
    
    private func loadCurrentProfile() {
        name = profile.name
        weightValue = profile.weight
        weightUnit = "lbs"
        heightValue = profile.height
        heightUnit = "cm"
        age = profile.age
        level = profile.fitnessLevel
        equipment = Set(profile.equipment)
        
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
        
        profile.name = name
        profile.weight = weightInLbs
        profile.height = heightValue
        profile.age = age
        profile.fitnessLevel = level
        profile.equipment = Array(equipment)
        
        profile.saveProfile()
        presentationMode.wrappedValue.dismiss()
    }
} 