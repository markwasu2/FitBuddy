import Foundation
import SwiftUI

class CalendarManager: ObservableObject {
    @Published var events: [String] = []
} 