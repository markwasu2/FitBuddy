import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_entry.dart';
import '../models/user.dart';

class StorageService extends ChangeNotifier {
  static const String _foodEntriesBox = 'food_entries';
  static const String _userBox = 'user_data';
  static const String _preferencesBox = 'preferences';
  static const String _workoutDataBox = 'workout_data';
  
  late Box<FoodEntry> _foodEntriesBoxInstance;
  late Box<User> _userBoxInstance;
  late Box _preferencesBoxInstance;
  late Box _workoutDataBoxInstance;
  
  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(FoodEntryAdapter());
    Hive.registerAdapter(UserAdapter());
  }

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Open Hive boxes
      _foodEntriesBoxInstance = await Hive.openBox<FoodEntry>(_foodEntriesBox);
      _userBoxInstance = await Hive.openBox<User>(_userBox);
      _preferencesBoxInstance = await Hive.openBox(_preferencesBox);
      _workoutDataBoxInstance = await Hive.openBox(_workoutDataBox);
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing storage service: $e');
    }
  }

  // Food Entries Management
  Future<void> saveFoodEntry(FoodEntry entry) async {
    await _ensureInitialized();
    await _foodEntriesBoxInstance.put(entry.id, entry);
    notifyListeners();
  }

  Future<void> deleteFoodEntry(String id) async {
    await _ensureInitialized();
    await _foodEntriesBoxInstance.delete(id);
    notifyListeners();
  }

  List<FoodEntry> getAllFoodEntries() {
    if (!_isInitialized) return [];
    return _foodEntriesBoxInstance.values.toList();
  }

  List<FoodEntry> getFoodEntriesForDate(DateTime date) {
    if (!_isInitialized) return [];
    return _foodEntriesBoxInstance.values
        .where((entry) => _isSameDay(entry.date, date))
        .toList();
  }

  List<FoodEntry> getFoodEntriesForDateRange(DateTime start, DateTime end) {
    if (!_isInitialized) return [];
    return _foodEntriesBoxInstance.values
        .where((entry) => entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
                          entry.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  // User Data Management
  Future<void> saveUser(User user) async {
    await _ensureInitialized();
    await _userBoxInstance.put(user.id, user);
    notifyListeners();
  }

  User? getUser(String id) {
    if (!_isInitialized) return null;
    return _userBoxInstance.get(id);
  }

  Future<void> deleteUser(String id) async {
    await _ensureInitialized();
    await _userBoxInstance.delete(id);
    notifyListeners();
  }

  // Preferences Management
  Future<void> savePreference(String key, dynamic value) async {
    await _ensureInitialized();
    await _preferencesBoxInstance.put(key, value);
    notifyListeners();
  }

  T? getPreference<T>(String key, {T? defaultValue}) {
    if (!_isInitialized) return defaultValue;
    return _preferencesBoxInstance.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> removePreference(String key) async {
    await _ensureInitialized();
    await _preferencesBoxInstance.delete(key);
    notifyListeners();
  }

  // Workout Data Management
  Future<void> saveWorkoutData(String key, Map<String, dynamic> data) async {
    await _ensureInitialized();
    await _workoutDataBoxInstance.put(key, data);
    notifyListeners();
  }

  Map<String, dynamic>? getWorkoutData(String key) {
    if (!_isInitialized) return null;
    return _workoutDataBoxInstance.get(key) as Map<String, dynamic>?;
  }

  List<Map<String, dynamic>> getAllWorkoutData() {
    if (!_isInitialized) return [];
    return _workoutDataBoxInstance.values
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  // Analytics and Statistics
  Map<String, double> getNutritionStats(DateTime start, DateTime end) {
    final entries = getFoodEntriesForDateRange(start, end);
    
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    
    for (final entry in entries) {
      totalCalories += entry.calories;
      totalProtein += entry.protein;
      totalCarbs += entry.carbs;
      totalFat += entry.fat;
      totalFiber += entry.fiber;
    }
    
    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'fiber': totalFiber,
    };
  }

  Map<String, double> getWeeklyNutritionStats() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return getNutritionStats(startOfWeek, endOfWeek);
  }

  Map<String, double> getMonthlyNutritionStats() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return getNutritionStats(startOfMonth, endOfMonth);
  }

  // Utility Methods
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  // Data Export/Import
  Future<Map<String, dynamic>> exportData() async {
    await _ensureInitialized();
    
    return {
      'food_entries': getAllFoodEntries().map((e) => e.toJson()).toList(),
      'user_data': _userBoxInstance.values.map((u) => u.toJson()).toList(),
      'preferences': _preferencesBoxInstance.toMap(),
      'workout_data': getAllWorkoutData(),
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    await _ensureInitialized();
    
    // Clear existing data
    await _foodEntriesBoxInstance.clear();
    await _userBoxInstance.clear();
    await _preferencesBoxInstance.clear();
    await _workoutDataBoxInstance.clear();
    
    // Import food entries
    if (data['food_entries'] != null) {
      for (final entryData in data['food_entries']) {
        final entry = FoodEntry.fromJson(entryData);
        await saveFoodEntry(entry);
      }
    }
    
    // Import user data
    if (data['user_data'] != null) {
      for (final userData in data['user_data']) {
        final user = User.fromJson(userData);
        await saveUser(user);
      }
    }
    
    // Import preferences
    if (data['preferences'] != null) {
      final prefs = data['preferences'] as Map;
      for (final entry in prefs.entries) {
        await savePreference(entry.key, entry.value);
      }
    }
    
    // Import workout data
    if (data['workout_data'] != null) {
      final workouts = data['workout_data'] as List;
      for (int i = 0; i < workouts.length; i++) {
        await saveWorkoutData('workout_$i', workouts[i]);
      }
    }
    
    notifyListeners();
  }

  // Onboarding Management
  Future<void> setOnboardingCompleted(bool completed) async {
    await _ensureInitialized();
    await _preferencesBoxInstance.put('onboarding_completed', completed);
    notifyListeners();
  }

  bool getOnboardingCompleted() {
    if (!_isInitialized) return false;
    return _preferencesBoxInstance.get('onboarding_completed', defaultValue: false) as bool;
  }

  // Cleanup
  Future<void> clearAllData() async {
    await _ensureInitialized();
    
    await _foodEntriesBoxInstance.clear();
    await _userBoxInstance.clear();
    await _preferencesBoxInstance.clear();
    await _workoutDataBoxInstance.clear();
    
    notifyListeners();
  }

  @override
  void dispose() {
    _foodEntriesBoxInstance.close();
    _userBoxInstance.close();
    _preferencesBoxInstance.close();
    _workoutDataBoxInstance.close();
    super.dispose();
  }
} 