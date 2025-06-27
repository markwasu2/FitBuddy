import Foundation
import SwiftUI

class GPTService: ObservableObject {
    func sendMessage(_ message: String) -> String {
        return "AI response to: \(message)"
    }
} 