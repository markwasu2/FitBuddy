import Foundation

struct WorkoutEntry: Identifiable {
    let id = UUID()
    var date: Date
    var exercises: [ExerciseItem]
    var type: String
    var duration: Int
    var mood: String
    var difficulty: String
    var calories: Int = 0
} 