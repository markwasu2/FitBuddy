import Foundation
import SwiftUI

class WorkoutJournal: ObservableObject {
    @Published var entries: [String] = []
} 