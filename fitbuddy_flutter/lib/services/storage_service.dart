import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/food_entry.dart';

class StorageService extends ChangeNotifier {
  static const String _userBoxName = 'user_box';
  static const String _foodEntriesBoxName = 'food_entries_box';
  static const String _onboardingKey = 'onboarding_completed';
  static const String _userKey = 'current_user';

  late Box<User> _userBox;
  late Box<FoodEntry> _foodEntriesBox;
  late SharedPreferences _prefs;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(FoodEntryAdapter());
    
    // Open boxes
    await Hive.openBox<User>(_userBoxName);
    await Hive.openBox<FoodEntry>(_foodEntriesBoxName);
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // User management
  Future<void> saveUser(User user) async {
    await _userBox.put(_userKey, user);
    notifyListeners();
  }

  User? getCurrentUser() {
    return _userBox.get(_userKey);
  }

  Future<void> updateUser(User user) async {
    user.updatedAt = DateTime.now();
    await saveUser(user);
  }

  // Food entries management
  Future<void> saveFoodEntry(FoodEntry entry) async {
    await _foodEntriesBox.add(entry);
    notifyListeners();
  }

  List<FoodEntry> getFoodEntriesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _foodEntriesBox.values.where((entry) {
      return entry.date.isAfter(startOfDay) && entry.date.isBefore(endOfDay);
    }).toList();
  }

  List<FoodEntry> getAllFoodEntries() {
    return _foodEntriesBox.values.toList();
  }

  Future<void> deleteFoodEntry(String id) async {
    final entry = _foodEntriesBox.values.firstWhere((entry) => entry.id == id);
    await entry.delete();
    notifyListeners();
  }

  // Onboarding
  Future<bool> getOnboardingCompleted() async {
    await _initPrefs();
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    await _initPrefs();
    await _prefs.setBool(_onboardingKey, true);
  }

  // Nutrition goals
  Future<void> saveNutritionGoals(Map<String, double> goals) async {
    await _initPrefs();
    final goalsMap = goals.map((key, value) => MapEntry(key, value.toString()));
    await _prefs.setString('nutrition_goals', goalsMap.toString());
  }

  Map<String, double> getNutritionGoals() {
    // Default goals
    return {
      'calories': 2000,
      'protein': 150,
      'carbs': 250,
      'fat': 65,
      'fiber': 25,
    };
  }

  // Workout data
  Future<void> saveWorkoutData(Map<String, dynamic> workoutData) async {
    await _initPrefs();
    // Implementation for workout data storage
  }

  // Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    await _userBox.clear();
    await _foodEntriesBox.clear();
    await _initPrefs();
    await _prefs.clear();
    notifyListeners();
  }
} 