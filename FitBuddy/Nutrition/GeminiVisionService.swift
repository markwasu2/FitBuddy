import UIKit

struct FoodVisionResult: Codable {
    var foodName: String
    var portion: String
    var style: String?
}

struct GeminiVisionService {
    func recognizeFood(in image: UIImage) async throws -> FoodVisionResult {
        let jpegData = image.jpegData(compressionQuality: 0.8)!
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ""
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=\(apiKey)")!
        let body: [String: Any] = [
            "contents": [
                ["image": ["data": jpegData.base64EncodedString()]],
                ["text": "Identify the food items, portion size, and cooking style. Respond JSON."]
            ]
        ]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        let result = try JSONDecoder().decode(FoodVisionResult.self, from: data)
        return result
    }
} 