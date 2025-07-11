import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';

class WorkoutView extends StatefulWidget {
  const WorkoutView({super.key});

  @override
  State<WorkoutView> createState() => _WorkoutViewState();
}

class _WorkoutViewState extends State<WorkoutView> {
  int selectedTabIndex = 0;
  List<WorkoutPlan> workoutPlans = [];
  List<WorkoutSession> recentSessions = [];

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  void _loadWorkoutData() {
    // Mock data for now
    workoutPlans = [
      WorkoutPlan(
        id: '1',
        name: 'Upper Body Strength',
        description: 'Focus on chest, back, and arms',
        duration: '45 min',
        difficulty: 'Intermediate',
        exercises: [
          Exercise(name: 'Push-ups', sets: 3, reps: 12, rest: '60s'),
          Exercise(name: 'Pull-ups', sets: 3, reps: 8, rest: '90s'),
          Exercise(name: 'Dumbbell Rows', sets: 3, reps: 10, rest: '60s'),
        ],
      ),
      WorkoutPlan(
        id: '2',
        name: 'Lower Body Power',
        description: 'Build strength in legs and glutes',
        duration: '50 min',
        difficulty: 'Advanced',
        exercises: [
          Exercise(name: 'Squats', sets: 4, reps: 15, rest: '90s'),
          Exercise(name: 'Lunges', sets: 3, reps: 12, rest: '60s'),
          Exercise(name: 'Deadlifts', sets: 3, reps: 8, rest: '120s'),
        ],
      ),
    ];

    recentSessions = [
      WorkoutSession(
        id: '1',
        name: 'Upper Body Strength',
        date: DateTime.now().subtract(const Duration(days: 1)),
        duration: '42 min',
        caloriesBurned: 320,
      ),
      WorkoutSession(
        id: '2',
        name: 'Cardio HIIT',
        date: DateTime.now().subtract(const Duration(days: 3)),
        duration: '35 min',
        caloriesBurned: 450,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.blue,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Workouts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue, Colors.purple],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick Stats
                  _buildQuickStatsSection(),
                  const SizedBox(height: 24),
                  
                  // Tab Selector
                  _buildTabSelector(),
                  const SizedBox(height: 24),
                  
                  // Content based on selected tab
                  if (selectedTabIndex == 0) ...[
                    _buildWorkoutPlansSection(),
                  ] else ...[
                    _buildRecentSessionsSection(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateWorkoutDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'This Week',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.fitness_center,
                    title: 'Workouts',
                    value: '3',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.timer,
                    title: 'Time',
                    value: '2h 15m',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.local_fire_department,
                    title: 'Calories',
                    value: '1,240',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                title: 'Workout Plans',
                isSelected: selectedTabIndex == 0,
                onTap: () {
                  setState(() {
                    selectedTabIndex = 0;
                  });
                },
              ),
            ),
            Expanded(
              child: _buildTabButton(
                title: 'Recent',
                isSelected: selectedTabIndex == 1,
                onTap: () {
                  setState(() {
                    selectedTabIndex = 1;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Workout Plans',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _showCreateWorkoutDialog(),
              child: const Text('Create New'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...workoutPlans.map((plan) => _buildWorkoutPlanCard(plan)),
      ],
    );
  }

  Widget _buildWorkoutPlanCard(WorkoutPlan plan) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _startWorkout(plan),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(plan.difficulty),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plan.difficulty,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildPlanStat(
                    icon: Icons.timer,
                    value: plan.duration,
                    label: 'Duration',
                  ),
                  const SizedBox(width: 24),
                  _buildPlanStat(
                    icon: Icons.fitness_center,
                    value: '${plan.exercises.length}',
                    label: 'Exercises',
                  ),
                  const SizedBox(width: 24),
                  _buildPlanStat(
                    icon: Icons.repeat,
                    value: '${plan.exercises.fold(0, (sum, ex) => sum + ex.sets)}',
                    label: 'Sets',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: plan.exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = plan.exercises[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${exercise.sets}×${exercise.reps}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Sessions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (recentSessions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No workouts yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Start your first workout!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentSessions.map((session) => _buildSessionCard(session)),
      ],
    );
  }

  Widget _buildSessionCard(WorkoutSession session) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatDate(session.date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  session.duration,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${session.caloriesBurned} cal',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '${difference} days ago';
    }
  }

  void _startWorkout(WorkoutPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start ${plan.name}'),
        content: Text('Begin your ${plan.duration} workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showWorkoutInProgress(plan);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showWorkoutInProgress(WorkoutPlan plan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('${plan.name} - In Progress'),
        content: const Text('Workout tracking feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('End Workout'),
          ),
        ],
      ),
    );
  }

  void _showCreateWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Workout'),
        content: const Text('Workout creation feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Data Models
class WorkoutPlan {
  final String id;
  final String name;
  final String description;
  final String duration;
  final String difficulty;
  final List<Exercise> exercises;

  WorkoutPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.exercises,
  });
}

class Exercise {
  final String name;
  final int sets;
  final int reps;
  final String rest;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
  });
}

class WorkoutSession {
  final String id;
  final String name;
  final DateTime date;
  final String duration;
  final int caloriesBurned;

  WorkoutSession({
    required this.id,
    required this.name,
    required this.date,
    required this.duration,
    required this.caloriesBurned,
  });
} 