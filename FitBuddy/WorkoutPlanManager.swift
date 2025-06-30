import Foundation
import SwiftUI

class WorkoutPlanManager: ObservableObject {
    @Published var plans: [WorkoutPlan] = []
} 