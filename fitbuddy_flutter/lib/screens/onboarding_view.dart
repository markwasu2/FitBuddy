import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart'; // Added import for StorageService

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // User data
  String _name = '';
  String _email = '';
  String _password = '';
  DateTime _dateOfBirth = DateTime.now().subtract(const Duration(days: 6570)); // 18 years ago
  double _height = 170.0;
  double _weight = 70.0;
  String _gender = 'male';
  String _activityLevel = 'moderately_active';
  List<String> _goals = [];

  final List<String> _availableGoals = [
    'Lose weight',
    'Build muscle',
    'Improve fitness',
    'Increase strength',
    'Better flexibility',
    'Run faster',
    'Stay healthy',
    'Train for event',
  ];

  final List<Map<String, dynamic>> _activityLevels = [
    {'value': 'sedentary', 'label': 'Sedentary', 'description': 'Little to no exercise'},
    {'value': 'lightly_active', 'label': 'Lightly Active', 'description': 'Light exercise 1-3 days/week'},
    {'value': 'moderately_active', 'label': 'Moderately Active', 'description': 'Moderate exercise 3-5 days/week'},
    {'value': 'very_active', 'label': 'Very Active', 'description': 'Hard exercise 6-7 days/week'},
    {'value': 'extremely_active', 'label': 'Extremely Active', 'description': 'Very hard exercise, physical job'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 6,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildBasicInfoPage(),
                  _buildPhysicalInfoPage(),
                  _buildActivityLevelPage(),
                  _buildGoalsPage(),
                  _buildCompletePage(),
                ],
              ),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fitness_center,
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to Peregrine!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your personal AI-powered fitness companion that helps you achieve your health and fitness goals.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            'Let\'s get started by setting up your profile.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _name = value,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => _email = value,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            onChanged: (value) => _password = value,
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Physical Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // Date of Birth
          const Text(
            'Date of Birth',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _dateOfBirth,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _dateOfBirth = date;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_dateOfBirth.day}/${_dateOfBirth.month}/${_dateOfBirth.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Gender Selection
          const Text(
            'Gender',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Male'),
                  value: 'male',
                  groupValue: _gender,
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Female'),
                  value: 'female',
                  groupValue: _gender,
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Height
          const Text(
            'Height',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _height,
                  min: 120.0,
                  max: 220.0,
                  divisions: 100,
                  label: '${_height.round()} cm',
                  onChanged: (value) {
                    setState(() {
                      _height = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_height.round()} cm', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(_cmToFeetInches(_height), style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weight
          const Text(
            'Weight',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _weight,
                  min: 30.0,
                  max: 200.0,
                  divisions: 170,
                  label: '${_weight.round()} kg',
                  onChanged: (value) {
                    setState(() {
                      _weight = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_weight.round()} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${(_weight * 2.20462).toStringAsFixed(1)} lbs', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLevelPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Level',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'How active are you on a typical week?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _activityLevels.length,
              itemBuilder: (context, index) {
                final level = _activityLevels[index];
                final isSelected = _activityLevel == level['value'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isSelected ? Colors.blue[50] : Colors.white,
                  child: RadioListTile<String>(
                    title: Text(
                      level['label'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(level['description']),
                    value: level['value'],
                    groupValue: _activityLevel,
                    onChanged: (value) {
                      setState(() {
                        _activityLevel = value!;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Goals',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select all that apply to you:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: _availableGoals.length,
              itemBuilder: (context, index) {
                final goal = _availableGoals[index];
                final isSelected = _goals.contains(goal);
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _goals.remove(goal);
                      } else {
                        _goals.add(goal);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        goal,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletePage() {
    final allFieldsFilled = _name.isNotEmpty && _email.isNotEmpty && _password.isNotEmpty && _goals.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 100,
            color: Colors.green,
          ),
          const SizedBox(height: 32),
          const Text(
            'You\'re all set!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your Peregrine profile has been created successfully. We\'ll use this information to personalize your experience and provide you with the best fitness recommendations.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: allFieldsFilled ? _completeOnboarding : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: allFieldsFilled ? Colors.blue : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 18),
              ),
            ),
          if (!allFieldsFilled)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Please fill in all required fields before continuing.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Back'),
            )
          else
            const SizedBox(width: 80),
          
          if (_currentPage < 5)
            ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Next'),
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    print('DEBUG: _name=$_name, _email=$_email, _password=$_password, _goals=$_goals');
    if (_name.isEmpty || _email.isEmpty || _password.isEmpty || _goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final success = await authService.signUp(
        name: _name,
        email: _email,
        password: _password,
        dateOfBirth: _dateOfBirth,
        height: _height,
        weight: _weight,
        gender: _gender,
        activityLevel: _activityLevel,
        goals: _goals,
      );

      if (success) {
        // Mark onboarding as complete
        final storageService = context.read<StorageService>();
        await storageService.setOnboardingCompleted(true);
        // Navigate to main app
        context.go('/');
        print('DEBUG: Called context.go(/) after successful sign up');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create account. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _cmToFeetInches(double cm) {
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    return '$feet ft $inches in';
  }
} 