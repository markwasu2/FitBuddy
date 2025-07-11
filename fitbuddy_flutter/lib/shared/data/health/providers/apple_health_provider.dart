import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../health_sample.dart';
import '../provider_id.dart';

class AppleHealthProvider {
  static const String _channelName = 'apple_health_provider';
  
  HealthFactory? _health;
  bool _isAuthorized = false;
  bool _isLoading = false;

  bool get isAuthorized => _isAuthorized;
  bool get isLoading => _isLoading;
  ProviderId get providerId => ProviderId.appleHealth;

  Future<void> initialize() async {
    _isLoading = true;
    
    try {
      _health = HealthFactory(useHealthConnectIfAvailable: false);
      
      // Request permissions for all health data types
      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.WEIGHT,
        HealthDataType.HEIGHT,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.FLIGHTS_CLIMBED,
        HealthDataType.WORKOUT,
      ];

      final granted = await _health!.requestAuthorization(types);
      _isAuthorized = granted;
      
      if (_isAuthorized) {
        debugPrint('Apple HealthKit authorized successfully');
      } else {
        debugPrint('Apple HealthKit authorization failed');
      }
    } catch (e) {
      debugPrint('Error initializing Apple Health provider: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<List<HealthSample>> fetchHealthData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isAuthorized || _health == null) {
      return [];
    }

    try {
      final samples = <HealthSample>[];
      
      // Fetch steps
      final steps = await _getSteps(startDate, endDate);
      if (steps != null) {
        samples.add(HealthSample(
          id: 'steps_${startDate.millisecondsSinceEpoch}',
          providerId: providerId,
          type: HealthSampleType.steps,
          value: steps.toDouble(),
          unit: 'steps',
          startDate: startDate,
          endDate: endDate,
          metadata: {'source': 'Apple HealthKit'},
        ));
      }

      // Fetch calories
      final calories = await _getCaloriesBurned(startDate, endDate);
      if (calories != null) {
        samples.add(HealthSample(
          id: 'calories_${startDate.millisecondsSinceEpoch}',
          providerId: providerId,
          type: HealthSampleType.calories,
          value: calories,
          unit: 'kcal',
          startDate: startDate,
          endDate: endDate,
          metadata: {'source': 'Apple HealthKit'},
        ));
      }

      // Fetch heart rate
      final heartRate = await _getHeartRate(startDate, endDate);
      if (heartRate.isNotEmpty) {
        for (final hr in heartRate) {
          samples.add(HealthSample(
            id: 'hr_${hr.dateFrom.millisecondsSinceEpoch}',
            providerId: providerId,
            type: HealthSampleType.heartRate,
            value: hr.value as double,
            unit: 'bpm',
            startDate: hr.dateFrom,
            endDate: hr.dateTo,
            metadata: {'source': 'Apple HealthKit'},
          ));
        }
      }

      // Fetch weight
      final weight = await _getLatestWeight();
      if (weight != null) {
        samples.add(HealthSample(
          id: 'weight_${DateTime.now().millisecondsSinceEpoch}',
          providerId: providerId,
          type: HealthSampleType.weight,
          value: weight,
          unit: 'kg',
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          metadata: {'source': 'Apple HealthKit'},
        ));
      }

      // Fetch sleep
      final sleep = await _getSleepHours(startDate, endDate);
      if (sleep != null) {
        samples.add(HealthSample(
          id: 'sleep_${startDate.millisecondsSinceEpoch}',
          providerId: providerId,
          type: HealthSampleType.sleep,
          value: sleep.toDouble(),
          unit: 'hours',
          startDate: startDate,
          endDate: endDate,
          metadata: {'source': 'Apple HealthKit'},
        ));
      }

      return samples;
    } catch (e) {
      debugPrint('Error fetching Apple Health data: $e');
      return [];
    }
  }

  Future<int?> _getSteps(DateTime start, DateTime end) async {
    try {
      return await _health!.getTotalStepsInInterval(start, end);
    } catch (e) {
      debugPrint('Error getting steps: $e');
      return null;
    }
  }

  Future<double?> _getCaloriesBurned(DateTime start, DateTime end) async {
    try {
      final calories = await _health!.getHealthDataFromTypes(
        start, 
        end, 
        [HealthDataType.ACTIVE_ENERGY_BURNED]
      );
      if (calories.isNotEmpty) {
        return calories.fold<double>(0.0, (sum, data) {
          final value = data.value as double?;
          return sum + (value ?? 0.0);
        });
      }
      return null;
    } catch (e) {
      debugPrint('Error getting calories burned: $e');
      return null;
    }
  }

  Future<List<HealthDataPoint>> _getHeartRate(DateTime start, DateTime end) async {
    try {
      return await _health!.getHealthDataFromTypes(
        start, 
        end, 
        [HealthDataType.HEART_RATE]
      );
    } catch (e) {
      debugPrint('Error getting heart rate: $e');
      return [];
    }
  }

  Future<double?> _getLatestWeight() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final weight = await _health!.getHealthDataFromTypes(
        start, 
        now, 
        [HealthDataType.WEIGHT]
      );
      if (weight.isNotEmpty) {
        weight.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        return weight.first.value as double;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting weight: $e');
      return null;
    }
  }

  Future<int?> _getSleepHours(DateTime start, DateTime end) async {
    try {
      final sleep = await _health!.getHealthDataFromTypes(
        start, 
        end, 
        [HealthDataType.SLEEP_ASLEEP]
      );
      if (sleep.isNotEmpty) {
        final totalMinutes = sleep.fold(0.0, (sum, data) {
          final duration = data.dateTo.difference(data.dateFrom);
          return sum + duration.inMinutes;
        });
        return (totalMinutes / 60).round();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting sleep: $e');
      return null;
    }
  }

  Future<void> disconnect() async {
    _isAuthorized = false;
    _health = null;
  }
} 