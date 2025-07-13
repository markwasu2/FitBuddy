import UIKit

struct FoodVisionResult: Codable {
    var foodName: String
    var portion: String
    var style: String?
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: Content
}

struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
}

struct GeminiVisionService {
    func recognizeFood(in image: UIImage) async throws -> FoodVisionResult {
        let jpegData = image.jpegData(compressionQuality: 0.8)!
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ""
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=\(apiKey)")!
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "inlineData": [
                                "mimeType": "image/jpeg",
                                "data": jpegData.base64EncodedString()
                            ]
                        ],
                        [
                            "text": """
                            Analyze this food image and provide a JSON response with the following structure:
                            {
                                "foodName": "detailed description of the food",
                                "portion": "estimated portion size",
                                "style": "cooking style or preparation method"
                            }
                            
                            Be specific about the food items, ingredients, and portion size. Consider the visual appearance, colors, and arrangement of the food.
                            """
                        ]
                    ]
                ]
            ]
        ]
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        // Check if we got a valid response
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "GeminiVisionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Gemini API"])
        }
        
        // Parse the Gemini response
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let text = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw NSError(domain: "GeminiVisionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No text response from Gemini"])
        }
        
        // Try to extract JSON from the response
        let jsonStart = text.firstIndex(of: "{")
        let jsonEnd = text.lastIndex(of: "}")
        
        if let start = jsonStart, let end = jsonEnd {
            let jsonString = String(text[start...end])
            let jsonData = jsonString.data(using: .utf8)!
            let result = try JSONDecoder().decode(FoodVisionResult.self, from: jsonData)
            return result
        } else {
            // Fallback: create a basic result from the text
            return FoodVisionResult(
                foodName: text.prefix(100).description,
                portion: "1 serving",
                style: nil
            )
        }
    }
} 