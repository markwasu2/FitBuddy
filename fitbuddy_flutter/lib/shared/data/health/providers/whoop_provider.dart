import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../health_sample.dart';
import '../provider_id.dart';

class WhoopProvider {
  static const String _baseUrl = 'https://api.whoop.com/developer/v1';
  static const String _authUrl = 'https://www.whoop.com/oauth/authorize';
  static const String _tokenUrl = 'https://www.whoop.com/oauth/token';
  
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  bool _isAuthorized = false;
  bool _isLoading = false;

  // TODO: Add your WHOOP OAuth credentials here
  static const String _clientId = 'YOUR_WHOOP_CLIENT_ID';
  static const String _clientSecret = 'YOUR_WHOOP_CLIENT_SECRET';
  static const String _redirectUri = 'peregrine://whoop-callback';

  bool get isAuthorized => _isAuthorized && _accessToken != null;
  bool get isLoading => _isLoading;
  ProviderId get providerId => ProviderId.whoop;

  Future<void> initialize() async {
    _isLoading = true;
    
    try {
      // Check if we have a valid token
      if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
        _isAuthorized = true;
        debugPrint('WHOOP already authorized');
      } else if (_refreshToken != null) {
        await _refreshAccessToken();
      } else {
        debugPrint('WHOOP needs authorization');
      }
    } catch (e) {
      debugPrint('Error initializing WHOOP provider: $e');
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
    debugPrint('WHOOP authorization flow not implemented yet');
  }

  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) return;

    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
        _isAuthorized = true;
        debugPrint('WHOOP token refreshed successfully');
      } else {
        debugPrint('Failed to refresh WHOOP token: ${response.statusCode}');
        _isAuthorized = false;
      }
    } catch (e) {
      debugPrint('Error refreshing WHOOP token: $e');
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
      
      // Fetch strain
      final strain = await _fetchStrain(startDate);
      if (strain != null) {
        samples.add(HealthSample(
          id: 'whoop_strain_${startDate.millisecondsSinceEpoch}',
          providerId: providerId,
          type: HealthSampleType.strain,
          value: strain,
          unit: 'strain',
          startDate: startDate,
          endDate: endDate,
          metadata: {'source': 'WHOOP'},
        ));
      }

      // Fetch recovery
      final recovery = await _fetchRecovery(startDate);
      if (recovery != null) {
        samples.add(HealthSample(
          id: 'whoop_recovery_${startDate.millisecondsSinceEpoch}',
          providerId: providerId,
          type: HealthSampleType.recovery,
          value: recovery,
          unit: 'percent',
          startDate: startDate,
          endDate: endDate,
          metadata: {'source': 'WHOOP'},
        ));
      }

      // Fetch heart rate
      final heartRate = await _fetchHeartRate(startDate);
      if (heartRate.isNotEmpty) {
        for (final hr in heartRate) {
          samples.add(HealthSample(
            id: 'whoop_hr_${hr['timestamp'].millisecondsSinceEpoch}',
            providerId: providerId,
            type: HealthSampleType.heartRate,
            value: hr['value'].toDouble(),
            unit: 'bpm',
            startDate: DateTime.parse(hr['timestamp']),
            endDate: DateTime.parse(hr['timestamp']),
            metadata: {'source': 'WHOOP'},
          ));
        }
      }

      // Fetch sleep
      final sleep = await _fetchSleep(startDate);
      if (sleep != null) {
        samples.add(HealthSample(
          id: 'whoop_sleep_${startDate.millisecondsSinceEpoch}',
          providerId: providerId,
          type: HealthSampleType.sleep,
          value: sleep,
          unit: 'hours',
          startDate: startDate,
          endDate: endDate,
          metadata: {'source': 'WHOOP'},
        ));
      }

      return samples;
    } catch (e) {
      debugPrint('Error fetching WHOOP data: $e');
      return [];
    }
  }

  Future<double?> _fetchStrain(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
        Uri.parse('$_baseUrl/cycles/score?start=$dateStr&end=$dateStr'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cycles = data['cycles'] as List;
        if (cycles.isNotEmpty) {
          return double.tryParse(cycles.first['strain']['score']['value'] ?? '0') ?? 0.0;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching WHOOP strain: $e');
      return null;
    }
  }

  Future<double?> _fetchRecovery(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
        Uri.parse('$_baseUrl/cycles/score?start=$dateStr&end=$dateStr'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cycles = data['cycles'] as List;
        if (cycles.isNotEmpty) {
          return double.tryParse(cycles.first['recovery']['score']['value'] ?? '0') ?? 0.0;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching WHOOP recovery: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHeartRate(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
        Uri.parse('$_baseUrl/cycles/score?start=$dateStr&end=$dateStr'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cycles = data['cycles'] as List;
        if (cycles.isNotEmpty) {
          final heartRateData = cycles.first['strain']['heart_rate'] as List;
          return heartRateData.map((hr) => {
            'value': hr['value'],
            'timestamp': hr['timestamp'],
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching WHOOP heart rate: $e');
      return [];
    }
  }

  Future<double?> _fetchSleep(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
        Uri.parse('$_baseUrl/cycles/score?start=$dateStr&end=$dateStr'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cycles = data['cycles'] as List;
        if (cycles.isNotEmpty) {
          final sleep = cycles.first['sleep'];
          if (sleep != null) {
            final duration = sleep['duration'] as int;
            return duration / 3600; // Convert seconds to hours
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching WHOOP sleep: $e');
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