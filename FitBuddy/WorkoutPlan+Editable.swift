import Foundation

// MARK: - WorkoutPlan Editable Extension

extension WorkoutPlan {
    mutating func apply(_ patch: PlanPatch) {
        switch patch.type {
        case .addExercise:
            if let day = patch.day, let exerciseName = patch.exercise {
                addExercise(exerciseName, to: day)
            }
        case .removeExercise:
            if let exerciseName = patch.exercise {
                removeExercise(exerciseName)
            }
        case .changeDate:
            // Handle date changes
            break
        case .changeIntensity:
            if let exerciseName = patch.exercise, let value = patch.value {
                changeIntensity(for: exerciseName, to: value)
            }
        case .changeEquipment:
            if let value = patch.value {
                // Note: equipment is let, so we can't modify it directly
                // This would need to be handled at the plan creation level
                print("Equipment change requested: \(value)")
            }
        }
    }
    
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
    
    private mutating func addExercise(_ exerciseName: String, to day: Int) {
        _ = Exercise(
            id: UUID(),
            name: exerciseName,
            sets: 3,
            reps: 10,
            weight: nil,
            duration: nil,
            restTime: 60,
            instructions: "Perform \(exerciseName) with proper form",
            muscleGroup: "General",
            equipment: nil
        )
        
        // Note: exercises is let, so we can't modify it directly
        // This would need to be handled at the plan creation level
        print("Adding exercise \(exerciseName) to day \(day)")
    }
    
    private mutating func removeExercise(_ exerciseName: String) {
        // Note: exercises is let, so we can't modify it directly
        // This would need to be handled at the plan creation level
        print("Removing exercise \(exerciseName)")
    }
    
    private mutating func changeIntensity(for exerciseName: String, to value: String) {
        // Parse intensity changes like "25 reps" or "50 lbs"
        // Note: exercises is let, so we can't modify it directly
        // This would need to be handled at the plan creation level
        print("Changing intensity for \(exerciseName) to \(value)")
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