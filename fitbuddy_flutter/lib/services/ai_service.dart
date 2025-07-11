import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<String> suggestions;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.suggestions = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AIService extends ChangeNotifier {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent';
  static const String _visionUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-002:generateContent';
  
  String? _apiKey = 'AIzaSyAvdCoeqHcLwhPfeQLGEPQ1WSFXNZBh1v4';
  bool _isLoading = false;
  String? _lastResponse;
  List<ChatMessage> _messages = [];
  
  bool get isLoading => _isLoading;
  String? get lastResponse => _lastResponse;
  List<ChatMessage> get messages => _messages;

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  void addMessage(String text, {bool isUser = false, List<String> suggestions = const []}) {
    _messages.add(ChatMessage(
      text: text,
      isUser: isUser,
      suggestions: suggestions,
    ));
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
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
      final errorMsg = 'Gemini API key not set. Please set your API key in settings.';
      debugPrint(errorMsg);
      if (kDebugMode) {
        return errorMsg;
      }
      return 'Sorry, AI is not configured.';
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
      debugPrint('Gemini prompt:');
      debugPrint(prompt);

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

      debugPrint('Gemini API response: ${response.statusCode}');
      debugPrint(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        _lastResponse = text;
        notifyListeners();
        return text;
      } else {
        final errorMsg = 'Failed to get workout recommendation: ${response.statusCode} ${response.body}';
        debugPrint(errorMsg);
        if (kDebugMode) {
          return errorMsg;
        }
        return 'Sorry, I could not generate a workout. (AI error)';
      }
    } catch (e, stack) {
      debugPrint('Error getting workout recommendation: $e');
      debugPrint(stack.toString());
      if (kDebugMode) {
        return 'Error: $e';
      }
      return 'Sorry, I had trouble responding. Please try again.';
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

  /// Sends the full chat history to Gemini and gets a context-aware response.
  Future<void> sendAgenticMessage(String userMessage) async {
    if (_apiKey == null) {
      throw Exception('API key not set');
    }
    _isLoading = true;
    notifyListeners();

    // Add user message to chat log
    _messages.add(ChatMessage(text: userMessage, isUser: true));
    notifyListeners();

    try {
      // Build the chat history for Gemini
      final List<Map<String, dynamic>> parts = _messages.map((msg) => {
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text}
        ]
      }).toList();

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': parts,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        // Optionally extract suggestions from the response (if you want to fine-tune this later)
        _messages.add(ChatMessage(text: text, isUser: false));
        _lastResponse = text;
        notifyListeners();
      } else {
        throw Exception('Failed to get agentic response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in agentic chat: $e');
      _messages.add(ChatMessage(text: 'Sorry, I had trouble responding. Please try again.', isUser: false));
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Export chat log for fine-tuning or personalization
  List<Map<String, dynamic>> exportChatLog() {
    return _messages.map((msg) => {
      'role': msg.isUser ? 'user' : 'model',
      'text': msg.text,
      'timestamp': msg.timestamp.toIso8601String(),
    }).toList();
  }

  /// Import chat log (for future fine-tuning)
  void importChatLog(List<Map<String, dynamic>> chatLog) {
    _messages = chatLog.map((entry) => ChatMessage(
      text: entry['text'],
      isUser: entry['role'] == 'user',
      timestamp: DateTime.parse(entry['timestamp']),
    )).toList();
    notifyListeners();
  }
} 