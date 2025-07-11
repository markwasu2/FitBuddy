import SwiftUI

struct CalorieSettingsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var calorieGoal: String = ""
    @State private var showingGoalCalculator = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Calorie Goals")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Set your daily calorie target")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding(.top)
                
                // Current Goal Display
                VStack(spacing: 16) {
                    Text("Current Daily Goal")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    Text("\(healthKitManager.dailyCalorieGoal)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.accent)
                    
                    Text("calories")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding()
                .background(Color.background)
                .cornerRadius(16)
                
                // Quick Goal Presets
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Goals")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        GoalPresetButton(title: "Weight Loss", calories: 1500, color: .error)
                        GoalPresetButton(title: "Maintenance", calories: 2000, color: .accent)
                        GoalPresetButton(title: "Muscle Gain", calories: 2500, color: .secondary)
                        GoalPresetButton(title: "Athlete", calories: 3000, color: .accent)
                    }
                }
                
                // Custom Goal Input
                VStack(alignment: .leading, spacing: 16) {
                    Text("Custom Goal")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    HStack {
                        TextField("Enter calories", text: $calorieGoal)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Set") {
                            if let goal = Int(calorieGoal), goal > 0 {
                                healthKitManager.updateCalorieGoal(goal)
                                profileManager.updateCalorieGoal(goal)
                                calorieGoal = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(calorieGoal.isEmpty || Int(calorieGoal) == nil)
                    }
                }
                
                // Goal Calculator Button
                Button(action: { showingGoalCalculator = true }) {
                    HStack {
                        Image(systemName: "calculator")
                        Text("Calculate My Goal")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingGoalCalculator) {
                CalorieGoalCalculatorView()
                    .environmentObject(healthKitManager)
                    .environmentObject(profileManager)
            }
        }
    }
}

struct GoalPresetButton: View {
    let title: String
    let calories: Int
    let color: Color
    
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var profileManager: ProfileManager
    
    var body: some View {
        Button(action: {
            healthKitManager.updateCalorieGoal(calories)
            profileManager.updateCalorieGoal(calories)
        }) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text("\(calories)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text("cal")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.background)
            .cornerRadius(12)
        }
    }
}

struct CalorieGoalCalculatorView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var gender: String = "Male"
    @State private var activityLevel: String = "Moderate"
    @State private var goal: String = "Maintain"
    
    private var calculatedGoal: Int {
        guard let ageInt = Int(age),
              let weightDouble = Double(weight),
              let heightDouble = Double(height) else { return 2000 }
        
        // Convert height from inches to centimeters for BMR calculation
        let heightCm = heightDouble * 2.54
        
        // BMR calculation using Mifflin-St Jeor Equation
        let bmr: Double
        if gender == "Male" {
            bmr = (10 * weightDouble) + (6.25 * heightCm) - (5 * Double(ageInt)) + 5
        } else {
            bmr = (10 * weightDouble) + (6.25 * heightCm) - (5 * Double(ageInt)) - 161
        }
        
        // Activity multiplier
        let activityMultiplier: Double
        switch activityLevel {
        case "Sedentary": activityMultiplier = 1.2
        case "Light": activityMultiplier = 1.375
        case "Moderate": activityMultiplier = 1.55
        case "Active": activityMultiplier = 1.725
        case "Very Active": activityMultiplier = 1.9
        default: activityMultiplier = 1.55
        }
        
        let tdee = bmr * activityMultiplier
        
        // Goal adjustment
        switch goal {
        case "Lose Weight": return Int(tdee - 500)
        case "Maintain": return Int(tdee)
        case "Gain Weight": return Int(tdee + 500)
        default: return Int(tdee)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Calorie Calculator")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Calculate your personalized daily calorie goal")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Input Form
                    VStack(spacing: 20) {
                        // Age
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            TextField("Enter age", text: $age)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Weight
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weight (lbs)")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            TextField("Enter weight", text: $weight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Height
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Height (inches)")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            TextField("Enter height", text: $height)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Gender
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            Picker("Gender", selection: $gender) {
                                Text("Male").tag("Male")
                                Text("Female").tag("Female")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // Activity Level
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity Level")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            Picker("Activity Level", selection: $activityLevel) {
                                Text("Sedentary").tag("Sedentary")
                                Text("Light").tag("Light")
                                Text("Moderate").tag("Moderate")
                                Text("Active").tag("Active")
                                Text("Very Active").tag("Very Active")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.background)
                            .cornerRadius(8)
                        }
                        
                        // Goal
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Goal")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            Picker("Goal", selection: $goal) {
                                Text("Lose Weight").tag("Lose Weight")
                                Text("Maintain").tag("Maintain")
                                Text("Gain Weight").tag("Gain Weight")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    
                    // Result
                    VStack(spacing: 16) {
                        Text("Your Daily Calorie Goal")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text("\(calculatedGoal)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.accent)
                        
                        Text("calories")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        Button("Set This Goal") {
                            healthKitManager.updateCalorieGoal(calculatedGoal)
                            profileManager.updateCalorieGoal(calculatedGoal)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                    .background(Color.background)
                    .cornerRadius(16)
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Pre-fill with profile data
                age = String(profileManager.age)
                weight = String(profileManager.weight)
                height = String(profileManager.height)
            }
        }
    }
} 