import SwiftUI
import Foundation

// MARK: - CALENDAR VIEW

struct WorkoutCalendarView: View {
    @EnvironmentObject var workoutJournal: WorkoutJournal
    @State private var selectedDate: Date = Date()
    @State private var showDaily = false
    private let calendar = Calendar.current
    private let today = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CalendarGrid(selectedDate: $selectedDate, workoutJournal: workoutJournal)
                    .padding(.top, 12)
                Spacer(minLength: 0)
                NavigationLink(value: selectedDate) {
                    EmptyView()
                }
                .navigationDestination(for: Date.self) { date in
                    DailyWorkoutView(date: date).environmentObject(workoutJournal)
                }
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("Calendar")
            .onChange(of: selectedDate) { oldValue, newValue in 
                showDaily = true 
            }
        }
    }
}

struct CalendarGrid: View {
    @Binding var selectedDate: Date
    @ObservedObject var workoutJournal: WorkoutJournal
    private let calendar = Calendar.current
    private let days = ["S","M","T","W","T","F","S"]
    private let accent = Color.accent

    private var monthDates: [Date] {
        let today = Date()
        let comps = calendar.dateComponents([.year, .month], from: today)
        let firstOfMonth = calendar.date(from: comps)!
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        var dates: [Date] = []
        for _ in 1..<firstWeekday { dates.append(Date.distantPast) }
        for day in range {
            if let d = calendar.date(bySetting: .day, value: day, of: firstOfMonth) {
                dates.append(d)
            }
        }
        return dates
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(Date(), format: .dateTime.year().month())
                    .font(.title2)
                    .foregroundColor(.textPrimary)
                Spacer()
            }.padding(.horizontal)
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { d in
                    Text(d).font(.caption).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(monthDates, id: \.self) { date in
                    if calendar.isDate(date, equalTo: Date.distantPast, toGranularity: .day) {
                        Color.clear.frame(height: 36)
                    } else {
                        let isToday = calendar.isDateInToday(date)
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let hasWorkout = workoutJournal.entry(for: date) != nil
                        Button(action: { selectedDate = date }) {
                            VStack(spacing: 2) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.body)
                                    .foregroundColor(isToday ? .accent : .textPrimary)
                                    .frame(width: 32, height: 32)
                                    .background(isSelected ? Color.accent.opacity(0.15) : .clear)
                                    .clipShape(Circle())
                                if hasWorkout {
                                    Circle()
                                        .fill(isToday ? Color.accent : Color.accent)
                                        .frame(width: 6, height: 6)
                                } else {
                                    Spacer().frame(height: 6)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(height: 36)
                        .animation(.spring(), value: isSelected)
                    }
                }
            }
        }
        .cleanCardStyle()
        .padding(.horizontal, .spacingM)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - DAILY WORKOUT VIEW

struct DailyWorkoutView: View {
    @EnvironmentObject var workoutJournal: WorkoutJournal
    let date: Date
    @State private var entry: WorkoutEntry = WorkoutEntry(date: Date(), exercises: [], type: "", duration: 0, mood: "good", difficulty: "moderate")
    @State private var showPicker = false
    @State private var showSaved = false
    @State private var progress: Double = 0
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(date, format: .dateTime.weekday().month().day().year())
                    .font(.title2)
                    .foregroundColor(.textPrimary)
                Spacer()
                ProgressRing(progress: progress)
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal)
            if entry.exercises.isEmpty {
                Text("No exercises yet.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .padding(.top, 40)
            } else {
                ChecklistCard(entry: $entry)
                    .onChange(of: entry.exercises) { oldValue, newValue in
                        updateProgress()
                    }
            }
            Button(action: { showPicker = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accent)
                    Text("Add Exercise")
                        .font(.body)
                        .foregroundColor(.accent)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.background)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            Spacer()
            Button(action: save) {
                Text("Save")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accent)
                    .cornerRadius(14)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Color.background.ignoresSafeArea())
        .sheet(isPresented: $showPicker) {
            ExercisePickerSheet(selected: $entry.exercises)
        }
        .onAppear {
            if let e = workoutJournal.entry(for: date) {
                entry = e
            } else {
                entry = WorkoutEntry(date: date, exercises: [], type: "", duration: 0, mood: "good", difficulty: "moderate")
            }
            updateProgress()
        }
    }
    func save() {
        workoutJournal.upsert(entry)
        dismiss()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    func updateProgress() {
        let total = entry.exercises.count
        let done = entry.exercises.filter { $0.isCompleted }.count
        withAnimation(.spring()) {
            progress = total == 0 ? 0 : Double(done) / Double(total)
        }
    }
}

struct ChecklistCard: View {
    @Binding var entry: WorkoutEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach($entry.exercises) { $ex in
                HStack {
                    Toggle(isOn: $ex.isCompleted) {
                        Text("\(ex.name)")
                            .font(.body)
                            .foregroundColor(.textPrimary)
                    }
                    .toggleStyle(ChecklistToggleStyle())
                    .onChange(of: ex.isCompleted) { oldValue, newValue in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .padding(.vertical, 8)
                if ex.id != entry.exercises.last?.id {
                    Divider().padding(.leading, 36)
                }
            }
        }
        .cleanCardStyle()
        .padding(.horizontal, .spacingM)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

struct ChecklistToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .foregroundColor(configuration.isOn ? .accent : .textSecondary)
                .font(.system(size: 24))
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
    }
}

// MARK: - PROGRESS RING

struct ProgressRing: View {
    var progress: Double
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.textSecondary.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: progress)
        }
    }
}

// MARK: - EXERCISE PICKER SHEET

struct ExercisePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selected: [ExerciseItem]
    @State private var search: String = ""
    @State private var tempSelected: Set<ExerciseItem> = []
    let allExercises: [ExerciseItem] = [
        ExerciseItem(name: "Bench Press"),
        ExerciseItem(name: "Squat"),
        ExerciseItem(name: "Deadlift"),
        ExerciseItem(name: "Push Ups"),
        ExerciseItem(name: "Plank"),
        ExerciseItem(name: "Running"),
        ExerciseItem(name: "Yoga"),
    ]
    var filtered: [ExerciseItem] {
        if search.isEmpty { return allExercises }
        return allExercises.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    TextField("Search", text: $search)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filtered, id: \.id) { ex in
                            Button(action: {
                                if tempSelected.contains(ex) {
                                    tempSelected.remove(ex)
                                } else {
                                    tempSelected.insert(ex)
                                }
                            }) {
                                HStack {
                                    Image(systemName: tempSelected.contains(ex) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(tempSelected.contains(ex) ? .accent : .textSecondary)
                                    Text(ex.name)
                                        .font(.body)
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                            }
                            .background(Color.background)
                        }
                    }
                }
                .background(Color.background)
                Button(action: {
                    selected.append(contentsOf: tempSelected.filter { !selected.contains($0) })
                    dismiss()
                }) {
                    Text("Add Selected")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .cornerRadius(14)
                }
                .padding()
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - WORKOUT JOURNAL LIST

struct WorkoutJournalList: View {
    @EnvironmentObject var workoutJournal: WorkoutJournal
    private let calendar = Calendar.current
    var body: some View {
        NavigationView {
            workoutJournalListSection
        }
    }

    private var workoutJournalListSection: some View {
        List {
            ForEach(workoutJournal.entries) { entry in
                NavigationLink(destination: DailyWorkoutView(date: entry.date).environmentObject(workoutJournal)) {
                    JournalCell(entry: entry)
                }
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
        .background(Color.background)
        .navigationTitle("Journal")
    }
    func delete(at offsets: IndexSet) {
        for idx in offsets {
            if idx < workoutJournal.entries.count {
                let entry = workoutJournal.entries[idx]
                workoutJournal.delete(entry)
            }
        }
    }
}

struct JournalCell: View {
    let entry: WorkoutEntry
    var emoji: String {
        let names = entry.exercises.map { $0.name.lowercased() }
        if names.contains(where: { $0.contains("run") }) { return "🏃‍♂️" }
        if names.contains(where: { $0.contains("yoga") }) { return "🧘" }
        if names.contains(where: { $0.contains("bench") || $0.contains("squat") || $0.contains("deadlift") }) { return "🔥" }
        return "💪"
    }
    var percent: Int {
        let total = entry.exercises.count
        let done = entry.exercises.filter { $0.isCompleted }.count
        return total == 0 ? 0 : Int(Double(done) / Double(total) * 100)
    }
    var calories: [Double] {
        let c = Double(entry.calories)
        return c > 0 ? [c * 0.7, c * 0.8, c * 0.9, c] : [60, 80, 100, 120]
    }
    var body: some View {
        HStack(spacing: 12) {
            Text(emoji).font(.largeTitle)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date, format: .dateTime.month().day().year())
                    .font(.body)
                    .foregroundColor(.textPrimary)
                Text("\(entry.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            // Replace Sparkline with a simple progress view
            ProgressView(value: calories.last ?? 0, total: 2000)
                .progressViewStyle(LinearProgressViewStyle(tint: .accent))
            Text(percent == 100 ? "100%" : "\(percent)%")
                .font(.caption)
                .foregroundColor(percent == 100 ? .accent : .accent)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - SPARKLINE
// Using Sparkline from PeregrineDashboard.swift 