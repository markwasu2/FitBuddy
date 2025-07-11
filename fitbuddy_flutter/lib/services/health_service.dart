import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService extends ChangeNotifier {
  HealthFactory health = HealthFactory();
  bool _isAuthorized = false;
  List<HealthDataPoint> _healthData = [];
  
  bool get isAuthorized => _isAuthorized;
  List<HealthDataPoint> get healthData => _healthData;

  Future<bool> requestPermissions() async {
    try {
      // Request health permissions
      List<HealthDataType> types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.WEIGHT,
        HealthDataType.HEIGHT,
        HealthDataType.BODY_MASS_INDEX,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
      ];

      bool granted = await health.requestAuthorization(types);
      _isAuthorized = granted;
      notifyListeners();
      return granted;
    } catch (e) {
      print('Error requesting health permissions: $e');
      return false;
    }
  }

  Future<void> fetchHealthData() async {
    if (!_isAuthorized) {
      await requestPermissions();
    }

    try {
      DateTime now = DateTime.now();
      DateTime startDate = DateTime(now.year, now.month, now.day - 7);

      List<HealthDataPoint> data = await health.getHealthDataFromTypes(
        startDate,
        now,
        [
          HealthDataType.STEPS,
          HealthDataType.HEART_RATE,
          HealthDataType.WEIGHT,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
      );

      _healthData = data;
      notifyListeners();
    } catch (e) {
      print('Error fetching health data: $e');
    }
  }

  Future<int> getTodaySteps() async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);

      List<HealthDataPoint> steps = await health.getHealthDataFromTypes(
        startOfDay,
        now,
        [HealthDataType.STEPS],
      );

      int totalSteps = 0;
      for (var point in steps) {
        totalSteps += (point.value as num).toInt();
      }

      return totalSteps;
    } catch (e) {
      print('Error getting steps: $e');
      return 0;
    }
  }

  Future<double> getTodayCalories() async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);

      List<HealthDataPoint> calories = await health.getHealthDataFromTypes(
        startOfDay,
        now,
        [HealthDataType.ACTIVE_ENERGY_BURNED],
      );

      double totalCalories = 0;
      for (var point in calories) {
        totalCalories += (point.value as num).toDouble();
      }

      return totalCalories;
    } catch (e) {
      print('Error getting calories: $e');
      return 0;
    }
  }
} 