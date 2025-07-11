import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check for existing session
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId != null) {
        // Load user data from storage
        await _loadUserFromStorage(userId);
      }
    } catch (e) {
      print('Error initializing auth service: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required DateTime dateOfBirth,
    required double height,
    required double weight,
    required String gender,
    required String activityLevel,
    required List<String> goals,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement actual signup with backend
      // For now, create a mock user
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        dateOfBirth: dateOfBirth,
        height: height,
        weight: weight,
        gender: gender,
        activityLevel: activityLevel,
        goals: goals,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save user to storage
      await _saveUserToStorage(user);
      
      _currentUser = user;
      _isAuthenticated = true;
      
      return true;
    } catch (e) {
      print('Error during signup: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement actual signin with backend
      // For now, create a mock user
      final user = User(
        id: '1',
        name: 'John Doe',
        email: email,
        dateOfBirth: DateTime(1995, 6, 15),
        height: 175.0,
        weight: 75.0,
        gender: 'male',
        activityLevel: 'moderately_active',
        goals: ['Build muscle', 'Lose weight'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save user to storage
      await _saveUserToStorage(user);
      
      _currentUser = user;
      _isAuthenticated = true;
      
      return true;
    } catch (e) {
      print('Error during signin: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      print('Error during signout: $e');
    }
  }

  Future<void> updateProfile({
    String? name,
    double? height,
    double? weight,
    String? activityLevel,
    List<String>? goals,
  }) async {
    if (_currentUser == null) return;

    try {
      final updatedUser = User(
        id: _currentUser!.id,
        name: name ?? _currentUser!.name,
        email: _currentUser!.email,
        dateOfBirth: _currentUser!.dateOfBirth,
        height: height ?? _currentUser!.height,
        weight: weight ?? _currentUser!.weight,
        gender: _currentUser!.gender,
        activityLevel: activityLevel ?? _currentUser!.activityLevel,
        goals: goals ?? _currentUser!.goals,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
      );

      await _saveUserToStorage(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      // TODO: Save full user data to secure storage
    } catch (e) {
      print('Error saving user to storage: $e');
    }
  }

  Future<void> _loadUserFromStorage(String userId) async {
    try {
      // TODO: Load user data from secure storage
      // For now, create a mock user
      final user = User(
        id: userId,
        name: 'John Doe',
        email: 'john.doe@example.com',
        dateOfBirth: DateTime(1995, 6, 15),
        height: 175.0,
        weight: 75.0,
        gender: 'male',
        activityLevel: 'moderately_active',
        goals: ['Build muscle', 'Lose weight'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _currentUser = user;
      _isAuthenticated = true;
    } catch (e) {
      print('Error loading user from storage: $e');
    }
  }

  // Password reset functionality
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement password reset with backend
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      return true;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if user has completed onboarding
  bool get hasCompletedOnboarding {
    return _currentUser != null && _currentUser!.goals.isNotEmpty;
  }
} 