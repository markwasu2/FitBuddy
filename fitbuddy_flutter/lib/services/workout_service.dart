import 'package:flutter/foundation.dart';
import '../models/workout_entry.dart';

class WorkoutService extends ChangeNotifier {
  List<WorkoutEntry> _workouts = [];
  List<Map<String, dynamic>> _exerciseLibrary = [];
  bool _isLoading = false;

  List<WorkoutEntry> get workouts => _workouts;
  List<Map<String, dynamic>> get exerciseLibrary => _exerciseLibrary;
  bool get isLoading => _isLoading;

  // Initialize with mock data
  void initialize() {
    _loadExerciseLibrary();
    _loadMockWorkouts();
  }

  void _loadExerciseLibrary() {
    _exerciseLibrary = [
      {
        'name': 'Push-ups',
        'category': 'strength',
        'muscleGroups': ['chest', 'triceps', 'shoulders'],
        'equipment': 'bodyweight',
        'difficulty': 'beginner',
        'instructions': 'Start in plank position, lower body, push back up',
      },
      {
        'name': 'Squats',
        'category': 'strength',
        'muscleGroups': ['legs', 'glutes'],
        'equipment': 'bodyweight',
        'difficulty': 'beginner',
        'instructions': 'Stand with feet shoulder-width, lower hips, stand back up',
      },
      {
        'name': 'Pull-ups',
        'category': 'strength',
        'muscleGroups': ['back', 'biceps'],
        'equipment': 'pull-up bar',
        'difficulty': 'intermediate',
        'instructions': 'Hang from bar, pull body up until chin over bar',
      },
      {
        'name': 'Running',
        'category': 'cardio',
        'muscleGroups': ['legs', 'cardiovascular'],
        'equipment': 'none',
        'difficulty': 'beginner',
        'instructions': 'Jog or run at moderate pace',
      },
      {
        'name': 'Plank',
        'category': 'core',
        'muscleGroups': ['core', 'shoulders'],
        'equipment': 'bodyweight',
        'difficulty': 'beginner',
        'instructions': 'Hold body in straight line from head to heels',
      },
      {
        'name': 'Deadlift',
        'category': 'strength',
        'muscleGroups': ['back', 'legs', 'glutes'],
        'equipment': 'barbell',
        'difficulty': 'advanced',
        'instructions': 'Stand with feet hip-width, bend at hips and knees, lift bar',
      },
    ];
  }

  void _loadMockWorkouts() {
    final now = DateTime.now();
    
    _workouts = [
      WorkoutEntry(
        id: '1',
        name: 'Morning Cardio',
        type: 'cardio',
        date: now.subtract(const Duration(days: 1)),
        duration: 30,
        caloriesBurned: 250,
        exercises: [
          ExerciseSet(
            exerciseName: 'Running',
            sets: 1,
            reps: 0,
            weight: 0,
            restTime: 0,
            notes: '30 minutes at moderate pace',
          ),
        ],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      WorkoutEntry(
        id: '2',
        name: 'Upper Body Strength',
        type: 'strength',
        date: now.subtract(const Duration(days: 2)),
        duration: 45,
        caloriesBurned: 180,
        exercises: [
          ExerciseSet(
            exerciseName: 'Push-ups',
            sets: 3,
            reps: 12,
            weight: 0,
            restTime: 60,
          ),
          ExerciseSet(
            exerciseName: 'Pull-ups',
            sets: 3,
            reps: 8,
            weight: 0,
            restTime: 90,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      WorkoutEntry(
        id: '3',
        name: 'Lower Body Focus',
        type: 'strength',
        date: now.subtract(const Duration(days: 3)),
        duration: 40,
        caloriesBurned: 200,
        exercises: [
          ExerciseSet(
            exerciseName: 'Squats',
            sets: 4,
            reps: 15,
            weight: 0,
            restTime: 60,
          ),
          ExerciseSet(
            exerciseName: 'Plank',
            sets: 3,
            reps: 0,
            weight: 0,
            restTime: 60,
            notes: 'Hold for 60 seconds each',
          ),
        ],
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
    ];
    
    notifyListeners();
  }

  // Workout Management
  Future<void> addWorkout(WorkoutEntry workout) async {
    _workouts.add(workout);
    notifyListeners();
  }

  Future<void> updateWorkout(WorkoutEntry workout) async {
    final index = _workouts.indexWhere((w) => w.id == workout.id);
    if (index != -1) {
      _workouts[index] = workout;
      notifyListeners();
    }
  }

  Future<void> deleteWorkout(String id) async {
    _workouts.removeWhere((workout) => workout.id == id);
    notifyListeners();
  }

  WorkoutEntry? getWorkout(String id) {
    try {
      return _workouts.firstWhere((workout) => workout.id == id);
    } catch (e) {
      return null;
    }
  }

  List<WorkoutEntry> getWorkoutsForDate(DateTime date) {
    return _workouts.where((workout) {
      return workout.date.year == date.year &&
             workout.date.month == date.month &&
             workout.date.day == date.day;
    }).toList();
  }

  List<WorkoutEntry> getWorkoutsForDateRange(DateTime start, DateTime end) {
    return _workouts.where((workout) {
      return workout.date.isAfter(start.subtract(const Duration(days: 1))) &&
             workout.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Statistics
  Map<String, dynamic> getWorkoutStats(DateTime start, DateTime end) {
    final workouts = getWorkoutsForDateRange(start, end);
    
    int totalWorkouts = workouts.length;
    int totalDuration = workouts.fold(0, (sum, workout) => sum + workout.duration);
    double totalCalories = workouts.fold(0.0, (sum, workout) => sum + workout.caloriesBurned);
    
    // Calculate average duration and calories per workout
    double avgDuration = totalWorkouts > 0 ? totalDuration / totalWorkouts : 0;
    double avgCalories = totalWorkouts > 0 ? totalCalories / totalWorkouts : 0;
    
    // Count workouts by type
    Map<String, int> workoutsByType = {};
    for (final workout in workouts) {
      workoutsByType[workout.type] = (workoutsByType[workout.type] ?? 0) + 1;
    }
    
    return {
      'totalWorkouts': totalWorkouts,
      'totalDuration': totalDuration,
      'totalCalories': totalCalories,
      'avgDuration': avgDuration,
      'avgCalories': avgCalories,
      'workoutsByType': workoutsByType,
    };
  }

  Map<String, dynamic> getWeeklyStats() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return getWorkoutStats(startOfWeek, endOfWeek);
  }

  Map<String, dynamic> getMonthlyStats() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return getWorkoutStats(startOfMonth, endOfMonth);
  }

  // Exercise Library Management
  List<Map<String, dynamic>> getExercisesByCategory(String category) {
    return _exerciseLibrary.where((exercise) => exercise['category'] == category).toList();
  }

  List<Map<String, dynamic>> getExercisesByDifficulty(String difficulty) {
    return _exerciseLibrary.where((exercise) => exercise['difficulty'] == difficulty).toList();
  }

  List<Map<String, dynamic>> searchExercises(String query) {
    return _exerciseLibrary.where((exercise) {
      final name = exercise['name'].toString().toLowerCase();
      final category = exercise['category'].toString().toLowerCase();
      final muscleGroups = exercise['muscleGroups'].join(' ').toLowerCase();
      
      return name.contains(query.toLowerCase()) ||
             category.contains(query.toLowerCase()) ||
             muscleGroups.contains(query.toLowerCase());
    }).toList();
  }

  // Workout Plan Generation
  List<Map<String, dynamic>> generateWorkoutPlan({
    required String goal,
    required String difficulty,
    required int daysPerWeek,
  }) {
    List<Map<String, dynamic>> plan = [];
    
    switch (goal.toLowerCase()) {
      case 'strength':
        plan = _generateStrengthPlan(difficulty, daysPerWeek);
        break;
      case 'cardio':
        plan = _generateCardioPlan(difficulty, daysPerWeek);
        break;
      case 'weight loss':
        plan = _generateWeightLossPlan(difficulty, daysPerWeek);
        break;
      case 'flexibility':
        plan = _generateFlexibilityPlan(difficulty, daysPerWeek);
        break;
      default:
        plan = _generateGeneralPlan(difficulty, daysPerWeek);
    }
    
    return plan;
  }

  List<Map<String, dynamic>> _generateStrengthPlan(String difficulty, int daysPerWeek) {
    return [
      {
        'day': 'Monday',
        'name': 'Upper Body Push',
        'exercises': ['Push-ups', 'Dips', 'Overhead Press'],
        'duration': 45,
      },
      {
        'day': 'Wednesday',
        'name': 'Upper Body Pull',
        'exercises': ['Pull-ups', 'Rows', 'Bicep Curls'],
        'duration': 45,
      },
      {
        'day': 'Friday',
        'name': 'Lower Body',
        'exercises': ['Squats', 'Deadlifts', 'Lunges'],
        'duration': 50,
      },
    ];
  }

  List<Map<String, dynamic>> _generateCardioPlan(String difficulty, int daysPerWeek) {
    return [
      {
        'day': 'Monday',
        'name': 'HIIT Cardio',
        'exercises': ['Running', 'Burpees', 'Jump Squats'],
        'duration': 30,
      },
      {
        'day': 'Wednesday',
        'name': 'Steady State Cardio',
        'exercises': ['Running', 'Cycling', 'Rowing'],
        'duration': 45,
      },
      {
        'day': 'Friday',
        'name': 'Interval Training',
        'exercises': ['Sprint Intervals', 'Mountain Climbers', 'High Knees'],
        'duration': 25,
      },
    ];
  }

  List<Map<String, dynamic>> _generateWeightLossPlan(String difficulty, int daysPerWeek) {
    return [
      {
        'day': 'Monday',
        'name': 'Full Body Circuit',
        'exercises': ['Squats', 'Push-ups', 'Plank', 'Burpees'],
        'duration': 40,
      },
      {
        'day': 'Wednesday',
        'name': 'Cardio + Strength',
        'exercises': ['Running', 'Lunges', 'Mountain Climbers'],
        'duration': 35,
      },
      {
        'day': 'Friday',
        'name': 'HIIT Workout',
        'exercises': ['Jump Squats', 'Push-ups', 'Burpees', 'Plank'],
        'duration': 30,
      },
    ];
  }

  List<Map<String, dynamic>> _generateFlexibilityPlan(String difficulty, int daysPerWeek) {
    return [
      {
        'day': 'Monday',
        'name': 'Upper Body Stretching',
        'exercises': ['Shoulder Stretches', 'Chest Stretches', 'Arm Stretches'],
        'duration': 20,
      },
      {
        'day': 'Wednesday',
        'name': 'Lower Body Stretching',
        'exercises': ['Hamstring Stretches', 'Quad Stretches', 'Hip Stretches'],
        'duration': 20,
      },
      {
        'day': 'Friday',
        'name': 'Full Body Yoga',
        'exercises': ['Sun Salutation', 'Warrior Poses', 'Balance Poses'],
        'duration': 30,
      },
    ];
  }

  List<Map<String, dynamic>> _generateGeneralPlan(String difficulty, int daysPerWeek) {
    return [
      {
        'day': 'Monday',
        'name': 'Full Body Workout',
        'exercises': ['Squats', 'Push-ups', 'Plank', 'Running'],
        'duration': 40,
      },
      {
        'day': 'Wednesday',
        'name': 'Cardio Focus',
        'exercises': ['Running', 'Jump Rope', 'Burpees'],
        'duration': 30,
      },
      {
        'day': 'Friday',
        'name': 'Strength Focus',
        'exercises': ['Pull-ups', 'Lunges', 'Dips', 'Plank'],
        'duration': 35,
      },
    ];
  }
} 