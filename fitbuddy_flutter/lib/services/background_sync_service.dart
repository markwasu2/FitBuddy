import 'dart:async';
import 'package:flutter/foundation.dart';
import '../shared/data/health/health_repository.dart';

class BackgroundSyncService {
  static const Duration _syncInterval = Duration(hours: 1);
  
  final HealthRepository _healthRepository;
  Timer? _syncTimer;

  BackgroundSyncService(this._healthRepository);

  Future<void> initialize() async {
    try {
      debugPrint('Background sync service initialized');
    } catch (e) {
      debugPrint('Error initializing background sync service: $e');
    }
  }

  Future<void> startPeriodicSync() async {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _performSync();
    });
  }

  Future<void> stopPeriodicSync() async {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _performSync() async {
    try {
      debugPrint('Starting background health data sync...');
      await _healthRepository.refreshData();
      debugPrint('Background health data sync completed');
    } catch (e) {
      debugPrint('Error during background sync: $e');
    }
  }

  Future<void> performManualSync() async {
    await _performSync();
  }

  Future<void> dispose() async {
    await stopPeriodicSync();
  }
} 