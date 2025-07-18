import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import 'onboarding_view.dart';
import 'dashboard_view.dart';
import 'nutrition_view.dart';
import 'workout_view.dart';
import 'ai_coach_view.dart';
import 'profile_view.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _currentIndex = 0;
  bool _showOnboarding = false;
  late final StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _storageService = Provider.of<StorageService>(context, listen: false);
    _storageService.addListener(_onStorageChanged);
    _checkOnboardingStatus();
  }

  @override
  void dispose() {
    _storageService.removeListener(_onStorageChanged);
    super.dispose();
  }

  void _onStorageChanged() {
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final hasCompletedOnboarding = _storageService.getOnboardingCompleted();
    if (!hasCompletedOnboarding) {
      setState(() {
        _showOnboarding = true;
      });
    } else {
      setState(() {
        _showOnboarding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: MainTabView build called, _showOnboarding=$_showOnboarding');
    if (_showOnboarding) {
      return OnboardingView();
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardView(),
          NutritionView(),
          WorkoutView(),
          AICoachView(),
          ProfileView(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25), // 0.1 * 255 = 25
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_outlined),
              activeIcon: Icon(Icons.restaurant),
              label: 'Nutrition',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Workouts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology),
              label: 'AI Coach',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
} 