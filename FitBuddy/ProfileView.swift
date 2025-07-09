import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var showingEditProfile = false
    @State private var showingHealthMetrics = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingL) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Health Metrics
                    healthMetricsSection
                    
                    // Goals & Settings
                    goalsSettingsSection
                    
                    // App Info
                    appInfoSection
                }
                .padding(.spacingM)
            }
            .background(Color.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingHealthMetrics) {
                HealthMetricsView()
            }
        }
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        VStack(spacing: .spacingM) {
            // Avatar and Name
            VStack(spacing: .spacingS) {
                CleanIcon("person.circle.fill", size: 80, color: .accent)
                
                VStack(spacing: .spacingXS) {
                    Text(profileManager.name.isEmpty ? "FitBuddy User" : profileManager.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("user@example.com")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            
            // Edit Profile Button
            Button(action: { showingEditProfile = true }) {
                HStack {
                    CleanIcon("pencil", size: 16, color: .accent)
                    Text("Edit Profile")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.accent)
                }
                .padding(.horizontal, .spacingM)
                .padding(.vertical, .spacingS)
                .background(Color.accent.opacity(0.1))
                .cornerRadius(CGFloat.radiusM)
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - Health Metrics Section
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            CleanSectionHeader("Health Metrics")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: .spacingM) {
                metricCard(
                    title: "Heart Rate",
                    value: "\(Int(healthKitManager.todayHeartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .error
                )
                
                metricCard(
                    title: "Sleep",
                    value: String(format: "%.1f", healthKitManager.todaySleepHours),
                    unit: "hours",
                    icon: "bed.double.fill",
                    color: .info
                )
                
                metricCard(
                    title: "Weight",
                    value: String(format: "%.1f", Double(profileManager.weight)),
                    unit: "lbs",
                    icon: "scalemass.fill",
                    color: .warning
                )
                
                metricCard(
                    title: "Body Fat",
                    value: String(format: "%.1f", healthKitManager.todayBodyFatPercentage),
                    unit: "%",
                    icon: "chart.pie.fill",
                    color: .success
                )
            }
            
            Button(action: { showingHealthMetrics = true }) {
                HStack {
                    CleanIcon("slider.horizontal.3", size: 16, color: .accent)
                    Text("Edit Health Metrics")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.accent)
                }
                .frame(maxWidth: .infinity)
                .padding(.spacingM)
                .background(Color.accent.opacity(0.1))
                .cornerRadius(CGFloat.radiusM)
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - Goals & Settings Section
    private var goalsSettingsSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            CleanSectionHeader("Goals & Settings")
            
            VStack(spacing: .spacingS) {
                settingRow(
                    title: "Daily Calorie Goal",
                    value: "\(profileManager.dailyCalorieGoal) calories",
                    icon: "flame.fill",
                    color: .warning,
                    action: { /* Edit calorie goal */ }
                )
                
                settingRow(
                    title: "Daily Steps Goal",
                    value: "\(healthKitManager.dailyStepGoal) steps",
                    icon: "figure.walk",
                    color: .success,
                    action: { /* Edit steps goal */ }
                )
                
                settingRow(
                    title: "Workout Frequency",
                    value: "3 times/week",
                    icon: "dumbbell.fill",
                    color: .accent,
                    action: { /* Edit workout frequency */ }
                )
                
                settingRow(
                    title: "Notifications",
                    value: "On",
                    icon: "bell.fill",
                    color: .info,
                    action: { /* Toggle notifications */ }
                )
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            CleanSectionHeader("App Info")
            
            VStack(spacing: .spacingS) {
                infoRow("Version", "1.0.0")
                infoRow("Build", "1")
                infoRow("Last Updated", "Today")
                
                Divider()
                    .padding(.vertical, .spacingS)
                
                Button(action: { /* Privacy policy */ }) {
                    HStack {
                        CleanIcon("hand.raised.fill", size: 16, color: .textSecondary)
                        Text("Privacy Policy")
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        CleanIcon("chevron.right", size: 12, color: .textTertiary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { /* Terms of service */ }) {
                    HStack {
                        CleanIcon("doc.text.fill", size: 16, color: .textSecondary)
                        Text("Terms of Service")
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        CleanIcon("chevron.right", size: 12, color: .textTertiary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { /* Support */ }) {
                    HStack {
                        CleanIcon("questionmark.circle.fill", size: 16, color: .textSecondary)
                        Text("Support")
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        CleanIcon("chevron.right", size: 12, color: .textTertiary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.spacingM)
        .cleanCardStyle()
    }
    
    // MARK: - Helper Views
    private func metricCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                CleanIcon(icon, size: 20, color: color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text(title)
                    .font(.caption1)
                    .foregroundColor(.textSecondary)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(.spacingM)
        .background(Color.surface)
        .cornerRadius(CGFloat.radiusM)
    }
    
    private func settingRow(title: String, value: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: .spacingM) {
                CleanIcon(icon, size: 20, color: color)
                
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text(value)
                        .font(.caption1)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                CleanIcon("chevron.right", size: 12, color: .textTertiary)
            }
            .padding(.spacingS)
            .background(Color.surface)
            .cornerRadius(CGFloat.radiusM)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    @State private var userName = ""
    @State private var userEmail = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingL) {
                    // Profile Form
                    VStack(spacing: .spacingM) {
                        VStack(alignment: .leading, spacing: .spacingS) {
                            Text("Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            
                            TextField("Enter your name", text: $userName)
                                .cleanInputStyle()
                        }
                        
                        VStack(alignment: .leading, spacing: .spacingS) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            
                            TextField("Enter your email", text: $userEmail)
                                .cleanInputStyle()
                        }
                    }
                    .padding(.spacingM)
                    .cleanCardStyle()
                    
                    // Save Button
                    Button(action: saveProfile) {
                        Text("Save Changes")
                            .cleanButtonStyle()
                    }
                }
                .padding(.spacingM)
            }
            .background(Color.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                userName = profileManager.name
                userEmail = "user@example.com"
            }
        }
    }
    
    private func saveProfile() {
        profileManager.name = userName
        // Note: email is not stored in ProfileManager
        dismiss()
    }
}

// MARK: - Health Metrics View
struct HealthMetricsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    @State private var heartRate = 0
    @State private var sleepHours = 0.0
    @State private var weight = 0.0
    @State private var bodyFatPercentage = 0.0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingL) {
                    // Health Metrics Form
                    VStack(spacing: .spacingM) {
                        metricInput(
                            title: "Heart Rate",
                            value: Binding(
                                get: { Double(heartRate) },
                                set: { heartRate = Int($0) }
                            ),
                            unit: "BPM",
                            range: 40...200
                        )
                        
                        metricInput(
                            title: "Sleep Hours",
                            value: $sleepHours,
                            unit: "hours",
                            range: 0...24
                        )
                        
                        metricInput(
                            title: "Weight",
                            value: $weight,
                            unit: "lbs",
                            range: 50...500
                        )
                        
                        metricInput(
                            title: "Body Fat",
                            value: $bodyFatPercentage,
                            unit: "%",
                            range: 5...50
                        )
                    }
                    .padding(.spacingM)
                    .cleanCardStyle()
                    
                    // Save Button
                    Button(action: saveMetrics) {
                        Text("Save Changes")
                            .cleanButtonStyle()
                    }
                }
                .padding(.spacingM)
            }
            .background(Color.background)
            .navigationTitle("Health Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMetrics()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                sleepHours = healthKitManager.todaySleepHours
            }
        }
    }
    
    private func metricInput(title: String, value: Binding<Double>, unit: String, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            
            HStack {
                TextField("Enter value", value: value, format: .number)
                    .cleanInputStyle()
                
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
    }
    
    private func saveMetrics() {
        // Note: These update methods don't exist in HealthKitManager
        // The values are read-only from HealthKit
        dismiss()
    }
} 