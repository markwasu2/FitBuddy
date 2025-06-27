import SwiftUI
import HealthKit

// MARK: - DASHBOARD-SPECIFIC EXTENSIONS

extension Color {
    static let bgCard      = Color(red: 0.976, green: 0.980, blue: 0.988)
    static let accentMint  = Color(red: 0.0, green: 0.776, blue: 0.635)
    static let glyphGray   = Color(red: 0.702, green: 0.718, blue: 0.753)
    static let textDim     = Color(red: 0.427, green: 0.435, blue: 0.455)
    static let dangerRed   = Color(red: 1.0, green: 0.231, blue: 0.188)
}

extension Font {
    static let h1     = Font.system(size: 28, weight: .bold)
    static let h2     = Font.system(size: 22, weight: .semibold)
}

extension View {
    func fhCard() -> some View {
        self.padding(20)
            .background(Color.bgCard)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - DASHBOARD

struct FitBuddyDashboard: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var workoutJournal: WorkoutJournal
    @State private var showProfileEdit = false
    @State private var isRefreshing = false

    var today: Date { Date() }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    // (A) Greeting banner
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hi, \(profileManager.name.isEmpty ? "Friend" : profileManager.name) 👋")
                                .font(.h1)
                                .foregroundColor(.textPrimary)
                            Text(today, format: .dateTime.weekday().month().day())
                                .font(.caption)
                                .foregroundColor(.textDim)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // (B) Biometrics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        MetricCard(title: "Steps", value: 8432, unit: "steps", trend: .up, latestWeekData: generateMockData())
                        MetricCard(title: "Active Calories", value: 456, unit: "kcal", trend: .flat, latestWeekData: generateMockData())
                        MetricCard(title: "Heart Rate", value: 72, unit: "bpm", trend: .down, latestWeekData: generateMockData())
                        MetricCard(title: "Distance", value: 6.2, unit: "km", trend: .up, latestWeekData: generateMockData())
                        MetricCard(title: "Hydration", value: 2.1, unit: "L", trend: .flat, latestWeekData: generateMockData())
                        MetricCard(title: "Weight", value: Double(profileManager.weight), unit: "lbs", trend: .flat, latestWeekData: generateMockData())
                    }
                    .padding(.horizontal)

                    // (C) Weekly Rings
                    ActivityRingGrid(steps: generateMockData(), calories: generateMockData(), workouts: generateMockData())
                        .padding(.horizontal)

                    // (D) Latest Workouts
                    WorkoutHistorySection(entries: [])
                        .padding(.horizontal)
                }
                .padding(.top, 24)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .refreshable {
                isRefreshing = true
                // Mock refresh - in a real app this would fetch actual data
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { isRefreshing = false }
            }

            // Floating Edit Button
            Button(action: { showProfileEdit = true }) {
                Image(systemName: "slider.vertical.3")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.accentBlue)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 28)
            .padding(.bottom, 28)
            .sheet(isPresented: $showProfileEdit) {
                ProfileEditView()
                    .environmentObject(profileManager)
            }
        }
    }
    
    private func generateMockData() -> [Double] {
        return (0..<7).map { _ in Double.random(in: 50...100) }
    }
}

// MARK: - METRIC CARD

enum Trend { case up, down, flat }

struct MetricCard: View {
    let title: String
    let value: Double
    let unit: String
    let trend: Trend
    let latestWeekData: [Double]

    @State private var appear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.caption).foregroundColor(.textDim)
                Spacer()
                TrendGlyph(trend: trend)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value, format: .number)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.textDim)
            }
            Sparkline(data: latestWeekData)
                .stroke(Color.accentBlue, lineWidth: 1.5)
                .frame(height: 22)
        }
        .fhCard()
        .opacity(appear ? 1 : 0)
        .scaleEffect(appear ? 1 : 0.95)
        .onAppear {
            withAnimation(.spring(response: 0.45).delay(Double.random(in: 0...0.2))) {
                appear = true
            }
        }
    }
}

struct TrendGlyph: View {
    let trend: Trend
    var body: some View {
        switch trend {
        case .up:
            Image(systemName: "arrow.up")
                .foregroundColor(.accentMint)
        case .down:
            Image(systemName: "arrow.down")
                .foregroundColor(.dangerRed)
        case .flat:
            Image(systemName: "equal")
                .foregroundColor(.glyphGray)
        }
    }
}

// MARK: - ACTIVITY RINGS

struct ActivityRingGrid: View {
    let steps: [Double]
    let calories: [Double]
    let workouts: [Double]
    var body: some View {
        HStack(spacing: 20) {
            ActivityRingView(title: "Steps", value: steps.last ?? 0, goal: 10000, color: .accentBlue, data: steps)
            ActivityRingView(title: "Calories", value: calories.last ?? 0, goal: 500, color: .accentMint, data: calories)
            ActivityRingView(title: "Workouts", value: workouts.last ?? 0, goal: 5, color: .dangerRed, data: workouts)
        }
    }
}

struct ActivityRingView: View {
    let title: String
    let value: Double
    let goal: Double
    let color: Color
    let data: [Double]

    var progress: Double { min(value / goal, 1.0) }

    var body: some View {
        VStack(spacing: 6) {
            TimelineView(.animation) { _ in
                ZStack {
                    Circle()
                        .stroke(Color.bgCard, lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.7), value: progress)
                }
                .frame(width: 54, height: 54)
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.textDim)
            Text("\(Int(value))")
                .font(.body)
                .foregroundColor(.textPrimary)
        }
        .frame(width: 70)
    }
}

// MARK: - WORKOUT HISTORY

struct WorkoutHistorySection: View {
    let entries: [WorkoutEntry]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest Workouts")
                .font(.h2)
                .foregroundColor(.textPrimary)
            ForEach(entries.prefix(3)) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.type)
                            .font(.body)
                            .foregroundColor(.textPrimary)
                        Text(entry.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.textDim)
                    }
                    Spacer()
                    Text("\(entry.duration) min")
                        .font(.caption)
                        .foregroundColor(.textDim)
                }
                .fhCard()
            }
        }
    }
}

// MARK: - PROFILE EDIT SHEET

struct ProfileEditView: View {
    @EnvironmentObject var profile: ProfileManager
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var weight: Int = 150
    @State private var weightUnit: String = "lbs"
    @State private var heightCm: Int = 170
    @State private var heightFt: Int = 5
    @State private var heightIn: Int = 8
    @State private var heightMode: String = "cm"
    @State private var age: Int = 25
    @State private var level: String = ""
    @State private var equipment: Set<String> = []
    @State private var hasChanges = false

    let levelOptions = ["Beginner", "Intermediate", "Advanced"]
    let equipmentOptions = ["Body-weight", "Yoga Mat", "Jump Rope", "Resistance Bands", "Pull-up Bar", "Treadmill"]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name").font(.caption).foregroundColor(.textDim)
                    TextField("Enter your name", text: $name)
                        .font(.body)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight").font(.caption).foregroundColor(.textDim)
                    HStack {
                        Picker("", selection: $weight) {
                            ForEach(70...350, id: \.self) { v in
                                Text("\(v)").tag(v)
                            }
                        }
                        .frame(width: 80)
                        Picker("", selection: $weightUnit) {
                            Text("lbs").tag("lbs")
                            Text("kg").tag("kg")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height").font(.caption).foregroundColor(.textDim)
                    Picker("", selection: $heightMode) {
                        Text("cm").tag("cm")
                        Text("ft/in").tag("ft")
                    }
                    .pickerStyle(.segmented)
                    if heightMode == "cm" {
                        Picker("", selection: $heightCm) {
                            ForEach(100...220, id: \.self) { v in
                                Text("\(v) cm").tag(v)
                            }
                        }
                        .frame(width: 120)
                    } else {
                        HStack {
                            Picker("", selection: $heightFt) {
                                ForEach(3...7, id: \.self) { v in
                                    Text("\(v) ft").tag(v)
                                }
                            }
                            .frame(width: 80)
                            Picker("", selection: $heightIn) {
                                ForEach(0...11, id: \.self) { v in
                                    Text("\(v) in").tag(v)
                                }
                            }
                            .frame(width: 80)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age").font(.caption).foregroundColor(.textDim)
                    Picker("", selection: $age) {
                        ForEach(10...100, id: \.self) { v in
                            Text("\(v)").tag(v)
                        }
                    }
                    .frame(width: 80)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fitness Level").font(.caption).foregroundColor(.textDim)
                    HStack {
                        ForEach(levelOptions, id: \.self) { opt in
                            Button(action: { level = opt }) {
                                Text(opt)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(level == opt ? Color.accentBlue : Color.bgCard)
                                    .foregroundColor(level == opt ? .white : .textPrimary)
                                    .cornerRadius(14)
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Equipment").font(.caption).foregroundColor(.textDim)
                    WrapHStack(items: equipmentOptions, selected: $equipment)
                }
                Spacer()
                Button(action: saveProfile) {
                    Text("Save")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasChanges ? Color.accentBlue : Color.glyphGray)
                        .cornerRadius(14)
                }
                .disabled(!hasChanges)
                .padding(.bottom, 12)
            }
            .padding()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: loadProfile)
        }
    }

    func loadProfile() {
        name = profile.name
        weight = profile.weight
        weightUnit = "lbs"
        heightCm = profile.height
        heightMode = "cm"
        age = profile.age
        level = profile.fitnessLevel
        equipment = Set(profile.equipment)
    }

    func saveProfile() {
        profile.name = name
        profile.weight = weight
        profile.height = heightMode == "cm" ? heightCm : Int(Double(heightFt * 12 + heightIn) * 2.54)
        profile.age = age
        profile.fitnessLevel = level
        profile.equipment = Array(equipment)
        profile.saveProfile()
        dismiss()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

struct WrapHStack: View {
    let items: [String]
    @Binding var selected: Set<String>
    var body: some View {
        let rows = items.chunked(into: 3)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        Button(action: {
                            if selected.contains(item) { selected.remove(item) }
                            else { selected.insert(item) }
                        }) {
                            Text(item)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selected.contains(item) ? Color.accentBlue : Color.bgCard)
                                .foregroundColor(selected.contains(item) ? .white : .textPrimary)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
} 