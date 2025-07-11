import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService extends ChangeNotifier {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  static const String _visionUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent';
  
  String? _apiKey;
  bool _isLoading = false;
  String? _lastResponse;
  
  bool get isLoading => _isLoading;
  String? get lastResponse => _lastResponse;

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  Future<String?> analyzeFoodImage(String imageBase64) async {
    if (_apiKey == null) {
      throw Exception('API key not set');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_visionUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Analyze this food image and provide nutritional information in JSON format with the following structure: {"name": "food name", "calories": number, "protein": number, "carbs": number, "fat": number, "fiber": number, "description": "brief description"}'
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': imageBase64
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        _lastResponse = text;
        notifyListeners();
        return text;
      } else {
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error analyzing food image: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getWorkoutRecommendation({
    required String fitnessLevel,
    required List<String> goals,
    required int availableTime,
    String? equipment,
  }) async {
    if (_apiKey == null) {
      throw Exception('API key not set');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final prompt = '''
Generate a personalized workout plan in JSON format with the following structure:
{
  "workout_name": "Workout Name",
  "duration_minutes": number,
  "difficulty": "beginner/intermediate/advanced",
  "exercises": [
    {
      "name": "Exercise Name",
      "sets": number,
      "reps": number,
      "rest_seconds": number,
      "instructions": "How to perform"
    }
  ],
  "tips": ["tip1", "tip2"]
}

User Profile:
- Fitness Level: $fitnessLevel
- Goals: ${goals.join(', ')}
- Available Time: ${availableTime} minutes
- Equipment: ${equipment ?? 'Bodyweight only'}

Make it realistic and achievable for the given time and fitness level.
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        _lastResponse = text;
        notifyListeners();
        return text;
      } else {
        throw Exception('Failed to get workout recommendation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting workout recommendation: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getNutritionAdvice({
    required double currentWeight,
    required double targetWeight,
    required String activityLevel,
    required List<String> dietaryRestrictions,
  }) async {
    if (_apiKey == null) {
      throw Exception('API key not set');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final prompt = '''
Provide personalized nutrition advice in JSON format with the following structure:
{
  "daily_calories": number,
  "macros": {
    "protein_grams": number,
    "carbs_grams": number,
    "fat_grams": number
  },
  "meal_suggestions": [
    {
      "meal": "breakfast/lunch/dinner/snack",
      "suggestions": ["suggestion1", "suggestion2"]
    }
  ],
  "tips": ["tip1", "tip2", "tip3"]
}

User Profile:
- Current Weight: ${currentWeight}kg
- Target Weight: ${targetWeight}kg
- Activity Level: $activityLevel
- Dietary Restrictions: ${dietaryRestrictions.join(', ')}

Provide realistic and healthy advice for weight management.
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        _lastResponse = text;
        notifyListeners();
        return text;
      } else {
        throw Exception('Failed to get nutrition advice: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting nutrition advice: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 