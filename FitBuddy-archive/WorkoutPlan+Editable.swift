import Foundation

// MARK: - WorkoutPlan Editable Extension

extension WorkoutPlan {
    func bulletPoints() -> [String] {
        var points: [String] = []
        
        // Add plan overview
        points.append("📋 \(title)")
        points.append("⏱️ Duration: \(formattedDuration)")
        points.append("💪 Difficulty: \(difficulty)")
        
        // Add exercises grouped by muscle groups
        let groupedExercises = Dictionary(grouping: exercises) { $0.muscleGroup }
        
        for (muscleGroup, muscleExercises) in groupedExercises {
            points.append("")
            points.append("**\(muscleGroup.uppercased())**")
            
            for exercise in muscleExercises {
                let status = exercise.isCompleted ? "✅" : "⭕"
                points.append("\(status) \(exercise.name): \(exercise.formattedSets)")
            }
        }
        
        return points
    }
}

// MARK: - Exercise Completion Tracking

extension Exercise {
    var isCompleted: Bool {
        // This would be tracked in the workout journal
        // For now, return false as default
        return false
    }
} 