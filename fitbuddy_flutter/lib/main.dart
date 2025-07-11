import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'screens/main_tab_view.dart';
import 'screens/onboarding_view.dart';
import 'services/health_service.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';
import 'services/camera_service.dart';
import 'services/auth_service.dart';
import 'services/workout_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await StorageService.initialize();
  
  runApp(const FitBuddyApp());
}

class FitBuddyApp extends StatelessWidget {
  const FitBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => HealthService()),
        ChangeNotifierProvider(create: (_) => AIService()),
        ChangeNotifierProvider(create: (_) => StorageService()),
        ChangeNotifierProvider(create: (_) => WorkoutService()),
        Provider(create: (_) => CameraService()),
      ],
      child: MaterialApp.router(
        title: 'FitBuddy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF),
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF),
            brightness: Brightness.dark,
          ),
        ),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainTabView(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingView(),
    ),
  ],
); 