import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService extends ChangeNotifier {
  HealthFactory? _health;
  bool _isAuthorized = false;
  bool _isLoading = false;

  // Health Data
  int _steps = 0;
  double _caloriesBurned = 0;
  double _activeCalories = 0;
  double _heartRate = 0;
  double _weight = 0;
  double _height = 0;
  double _bmi = 0;
  int _waterIntake = 0;
  int _sleepHours = 0;

  // Getters
  bool get isAuthorized => _isAuthorized;
  bool get isLoading => _isLoading;
  int get steps => _steps;
  double get caloriesBurned => _caloriesBurned;
  double get activeCalories => _activeCalories;
  double get heartRate => _heartRate;
  double get weight => _weight;
  double get height => _height;
  double get bmi => _bmi;
  int get waterIntake => _waterIntake;
  int get sleepHours => _sleepHours;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize Health Factory
      _health = HealthFactory(useHealthConnectIfAvailable: true);
      
      // Request permissions
      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.WEIGHT,
        HealthDataType.HEIGHT,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
      ];

      final granted = await _health!.requestAuthorization(types);
      _isAuthorized = granted;

      if (_isAuthorized) {
        await _fetchHealthData();
      }
    } catch (e) {
      print('Error initializing health service: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchHealthData() async {
    if (!_isAuthorized) return;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Fetch steps
      _steps = await _getSteps(startOfDay, now) ?? 0;

      // Fetch calories
      _caloriesBurned = await _getCaloriesBurned(startOfDay, now) ?? 0;
      _activeCalories = await _getActiveCalories(startOfDay, now) ?? 0;

      // Fetch heart rate (latest)
      _heartRate = await _getLatestHeartRate() ?? 0;

      // Fetch weight and height
      _weight = await _getLatestWeight() ?? 0;
      _height = await _getLatestHeight() ?? 0;

      // Calculate BMI
      if (_weight > 0 && _height > 0) {
        _bmi = _weight / ((_height / 100) * (_height / 100));
      }

      // Fetch sleep
      _sleepHours = await _getSleepHours(startOfDay, now) ?? 0;

      notifyListeners();
    } catch (e) {
      print('Error fetching health data: $e');
    }
  }

  Future<int?> _getSteps(DateTime start, DateTime end) async {
    try {
      final steps = await _health!.getTotalStepsInInterval(start, end);
      return steps;
    } catch (e) {
      print('Error getting steps: $e');
      return null;
    }
  }

  Future<double?> _getCaloriesBurned(DateTime start, DateTime end) async {
    try {
      final calories = await _health!.getHealthDataFromTypes(start, end, [HealthDataType.ACTIVE_ENERGY_BURNED]);
      if (calories.isNotEmpty) {
        return calories.fold(0.0, (sum, data) {
          final value = data.value as double?;
          return sum + (value ?? 0.0);
        });
      }
      return null;
    } catch (e) {
      print('Error getting calories burned: $e');
      return null;
    }
  }

  Future<double?> _getActiveCalories(DateTime start, DateTime end) async {
    try {
      final calories = await _health!.getHealthDataFromTypes(start, end, [HealthDataType.ACTIVE_ENERGY_BURNED]);
      if (calories.isNotEmpty) {
        return calories.fold(0.0, (sum, data) {
          final value = data.value as double?;
          return sum + (value ?? 0.0);
        });
      }
      return null;
    } catch (e) {
      print('Error getting active calories: $e');
      return null;
    }
  }

  Future<double?> _getLatestHeartRate() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 1));
      final heartRate = await _health!.getHealthDataFromTypes(start, now, [HealthDataType.HEART_RATE]);
      if (heartRate.isNotEmpty) {
        // Get the latest heart rate
        heartRate.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        return heartRate.first.value as double;
      }
      return null;
    } catch (e) {
      print('Error getting heart rate: $e');
      return null;
    }
  }

  Future<double?> _getLatestWeight() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final weight = await _health!.getHealthDataFromTypes(start, now, [HealthDataType.WEIGHT]);
      if (weight.isNotEmpty) {
        weight.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        return weight.first.value as double;
      }
      return null;
    } catch (e) {
      print('Error getting weight: $e');
      return null;
    }
  }

  Future<double?> _getLatestHeight() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 365));
      final height = await _health!.getHealthDataFromTypes(start, now, [HealthDataType.HEIGHT]);
      if (height.isNotEmpty) {
        height.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        return height.first.value as double;
      }
      return null;
    } catch (e) {
      print('Error getting height: $e');
      return null;
    }
  }

  Future<int?> _getSleepHours(DateTime start, DateTime end) async {
    try {
      final sleep = await _health!.getHealthDataFromTypes(start, end, [HealthDataType.SLEEP_ASLEEP]);
      if (sleep.isNotEmpty) {
        final totalMinutes = sleep.fold(0.0, (sum, data) {
          final duration = data.dateTo.difference(data.dateFrom);
          return sum + duration.inMinutes;
        });
        return (totalMinutes / 60).round(); // Convert to hours
      }
      return null;
    } catch (e) {
      print('Error getting sleep hours: $e');
      return null;
    }
  }

  Future<void> refreshData() async {
    if (_isAuthorized) {
      await _fetchHealthData();
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.WEIGHT,
        HealthDataType.HEIGHT,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
      ];

      final granted = await _health!.requestAuthorization(types);
      _isAuthorized = granted;
      notifyListeners();

      if (_isAuthorized) {
        await _fetchHealthData();
      }

      return granted;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  // Mock data for testing when health data is not available
  void setMockData() {
    _steps = 8432;
    _caloriesBurned = 324;
    _activeCalories = 280;
    _heartRate = 72;
    _weight = 75.0;
    _height = 175.0;
    _bmi = 24.5;
    _waterIntake = 2;
    _sleepHours = 7;
    notifyListeners();
  }
} 