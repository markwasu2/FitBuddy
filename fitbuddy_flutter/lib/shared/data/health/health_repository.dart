import 'package:flutter/foundation.dart';
import 'health_sample.dart';
import 'provider_id.dart';
import 'providers/apple_health_provider.dart';
import 'providers/google_fit_provider.dart';
import 'providers/fitbit_provider.dart';
import 'providers/whoop_provider.dart';

class HealthRepository extends ChangeNotifier {
  final Map<ProviderId, dynamic> _providers = {};
  final Map<ProviderId, List<HealthSample>> _data = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  Map<ProviderId, List<HealthSample>> get data => Map.unmodifiable(_data);

  // Provider getters
  AppleHealthProvider? get appleHealthProvider => _providers[ProviderId.appleHealth] as AppleHealthProvider?;
  GoogleFitProvider? get googleFitProvider => _providers[ProviderId.googleFit] as GoogleFitProvider?;
  FitbitProvider? get fitbitProvider => _providers[ProviderId.fitbit] as FitbitProvider?;
  WhoopProvider? get whoopProvider => _providers[ProviderId.whoop] as WhoopProvider?;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize all providers
      await _initializeProviders();
      
      // Fetch initial data from all authorized providers
      await _fetchAllData();
    } catch (e) {
      debugPrint('Error initializing health repository: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeProviders() async {
    // Initialize Apple Health provider
    final appleHealth = AppleHealthProvider();
    await appleHealth.initialize();
    _providers[ProviderId.appleHealth] = appleHealth;

    // Initialize Google Fit provider
    final googleFit = GoogleFitProvider();
    await googleFit.initialize();
    _providers[ProviderId.googleFit] = googleFit;

    // Initialize Fitbit provider
    final fitbit = FitbitProvider();
    await fitbit.initialize();
    _providers[ProviderId.fitbit] = fitbit;

    // Initialize WHOOP provider
    final whoop = WhoopProvider();
    await whoop.initialize();
    _providers[ProviderId.whoop] = whoop;
  }

  Future<void> _fetchAllData() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final endDate = now;

    for (final provider in _providers.values) {
      if (provider is AppleHealthProvider && provider.isAuthorized) {
        final samples = await provider.fetchHealthData(startDate: startDate, endDate: endDate);
        _data[ProviderId.appleHealth] = samples;
      } else if (provider is GoogleFitProvider && provider.isAuthorized) {
        final samples = await provider.fetchHealthData(startDate: startDate, endDate: endDate);
        _data[ProviderId.googleFit] = samples;
      } else if (provider is FitbitProvider && provider.isAuthorized) {
        final samples = await provider.fetchHealthData(startDate: startDate, endDate: endDate);
        _data[ProviderId.fitbit] = samples;
      } else if (provider is WhoopProvider && provider.isAuthorized) {
        final samples = await provider.fetchHealthData(startDate: startDate, endDate: endDate);
        _data[ProviderId.whoop] = samples;
      }
    }

    notifyListeners();
  }

  Future<void> refreshData() async {
    await _fetchAllData();
  }

  Future<void> authorizeProvider(ProviderId providerId) async {
    final provider = _providers[providerId];
    if (provider != null) {
      if (provider is FitbitProvider) {
        await provider.authorize();
      } else if (provider is WhoopProvider) {
        await provider.authorize();
      }
      // Apple Health and Google Fit are handled by the health package
    }
  }

  Future<void> disconnectProvider(ProviderId providerId) async {
    final provider = _providers[providerId];
    if (provider != null) {
      await provider.disconnect();
      _data.remove(providerId);
      notifyListeners();
    }
  }

  List<HealthSample> getAllSamples() {
    final allSamples = <HealthSample>[];
    for (final samples in _data.values) {
      allSamples.addAll(samples);
    }
    return allSamples;
  }

  List<HealthSample> getSamplesByType(HealthSampleType type) {
    final samples = <HealthSample>[];
    for (final providerSamples in _data.values) {
      samples.addAll(providerSamples.where((sample) => sample.type == type));
    }
    return samples;
  }

  List<HealthSample> getSamplesByProvider(ProviderId providerId) {
    return _data[providerId] ?? [];
  }
} 