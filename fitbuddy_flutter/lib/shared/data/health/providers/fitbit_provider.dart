import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../health_sample.dart';
import '../provider_id.dart';

class FitbitProvider {
  static const String _baseUrl = 'https://api.fitbit.com/1/user/-';
  static const String _authUrl = 'https://www.fitbit.com/oauth2/authorize';
  static const String _tokenUrl = 'https://api.fitbit.com/oauth2/token';
  
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  bool _isAuthorized = false;
  bool _isLoading = false;

  // TODO: Add your Fitbit OAuth credentials here
  static const String _clientId = 'YOUR_FITBIT_CLIENT_ID';
  static const String _clientSecret = 'YOUR_FITBIT_CLIENT_SECRET';
  static const String _redirectUri = 'peregrine://fitbit-callback';

  bool get isAuthorized => _isAuthorized && _accessToken != null;
  bool get isLoading => _isLoading;
  ProviderId get providerId => ProviderId.fitbit;

  Future<void> initialize() async {
    _isLoading = true;
    
    try {
      // Check if we have a valid token
      if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
        _isAuthorized = true;
        debugPrint('Fitbit already authorized');
      } else if (_refreshToken != null) {
        await _refreshAccessToken();
      } else {
        debugPrint('Fitbit needs authorization');
      }
    } catch (e) {
      debugPrint('Error initializing Fitbit provider: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> authorize() async {
    // TODO: Implement OAuth flow
    // This would typically involve:
    // 1. Opening a web view with the authorization URL
    // 2. Handling the callback with authorization code
    // 3. Exchanging code for access token
    debugPrint('Fitbit authorization flow not implemented yet');
  }

  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) return;

    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
        _isAuthorized = true;
        debugPrint('Fitbit token refreshed successfully');
      } else {
        debugPrint('Failed to refresh Fitbit token: ${response.statusCode}');
        _isAuthorized = false;
      }
    } catch (e) {
      debugPrint('Error refreshing Fitbit token: $e');
      _isAuthorized = false;
    }
  }

  Future<List<HealthSample>> fetchHealthData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!isAuthorized) {
      return [];
    }

    try {
      final samples = <HealthSample>[];
      
      // Fetch steps
      final steps = await _fetchSteps(startDate);
      if (steps != null) {
        samples.add(HealthSample(
          id: 'fitbit_steps_${startDate.millisecondsSinceEpoch}',
          providerId: providerId,
          type: HealthSampleType.steps,
          value: steps.toDouble(),
          unit: 'steps',
          startDate: startDate,
          endDate: endDate,
          metadata: {'source': 'Fitbit'},
        ));
      }

      // Fetch calories
      final calories = await _fetchCalories(startDate);
      if (calories != null) {
        samples.add(HealthSample(
          id: 'fitbit_calories_${startDate.millisecondsSinceEpoch}',
          providerId: providerId,
          type: HealthSampleType.calories,
          value: calories,
          unit: 'kcal',
          startDate: startDate,
          endDate: endDate,
          metadata: {'source': 'Fitbit'},
        ));
      }

      // Fetch heart rate
      final heartRate = await _fetchHeartRate(startDate);
      if (heartRate.isNotEmpty) {
        for (final hr in heartRate) {
          samples.add(HealthSample(
            id: 'fitbit_hr_${hr['time'].millisecondsSinceEpoch}',
            providerId: providerId,
            type: HealthSampleType.heartRate,
            value: hr['value'].toDouble(),
            unit: 'bpm',
            startDate: DateTime.parse(hr['time']),
            endDate: DateTime.parse(hr['time']),
            metadata: {'source': 'Fitbit'},
          ));
        }
      }

      // Fetch sleep
      final sleep = await _fetchSleep(startDate);
      if (sleep != null) {
        samples.add(HealthSample(
          id: 'fitbit_sleep_${startDate.millisecondsSinceEpoch}',
          providerId: providerId,
          type: HealthSampleType.sleep,
          value: sleep,
          unit: 'hours',
          startDate: startDate,
          endDate: endDate,
          metadata: {'source': 'Fitbit'},
        ));
      }

      return samples;
    } catch (e) {
      debugPrint('Error fetching Fitbit data: $e');
      return [];
    }
  }

  Future<int?> _fetchSteps(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
        Uri.parse('$_baseUrl/activities/steps/date/$dateStr/1d.json'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final activities = data['activities-steps'] as List;
        if (activities.isNotEmpty) {
          return int.tryParse(activities.first['value'] ?? '0') ?? 0;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching Fitbit steps: $e');
      return null;
    }
  }

  Future<double?> _fetchCalories(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
        Uri.parse('$_baseUrl/activities/calories/date/$dateStr/1d.json'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final activities = data['activities-calories'] as List;
        if (activities.isNotEmpty) {
          return double.tryParse(activities.first['value'] ?? '0') ?? 0.0;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching Fitbit calories: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHeartRate(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
        Uri.parse('$_baseUrl/activities/heart/date/$dateStr/1d/1min.json'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final activities = data['activities-heart'] as List;
        if (activities.isNotEmpty) {
          final heartRateData = activities.first['activities-heart-intraday']['dataset'] as List;
          return heartRateData.map((hr) => {
            'value': hr['value'],
            'time': '${dateStr}T${hr['time']}',
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching Fitbit heart rate: $e');
      return [];
    }
  }

  Future<double?> _fetchSleep(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
        Uri.parse('$_baseUrl/sleep/date/$dateStr.json'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sleep = data['sleep'] as List;
        if (sleep.isNotEmpty) {
          final totalMinutes = sleep.fold(0, (sum, session) {
            final duration = session['duration'] as int;
            return sum + duration;
          });
          return totalMinutes / 60000; // Convert milliseconds to hours
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching Fitbit sleep: $e');
      return null;
    }
  }

  Future<void> disconnect() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _isAuthorized = false;
  }
} 