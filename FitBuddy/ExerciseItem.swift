import Foundation

struct ExerciseItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var isCompleted: Bool = false
} 