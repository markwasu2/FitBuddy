import Foundation
import SwiftUI

class NotificationManager: ObservableObject {
    @Published var notifications: [String] = []
} 