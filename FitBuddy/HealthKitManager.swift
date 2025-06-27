import Foundation
import SwiftUI

class HealthKitManager: ObservableObject {
    @Published var healthData: [String: Any] = [:]
} 