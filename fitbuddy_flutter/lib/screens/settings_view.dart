import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/health_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _notificationsEnabled = true;
  bool _healthKitSync = true;
  bool _darkMode = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Account',
            [
              _buildAccountTile(),
              _buildProfileTile(),
              _buildGoalsTile(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Health & Fitness',
            [
              _buildHealthKitTile(),
              _buildNutritionGoalsTile(),
              _buildWorkoutPreferencesTile(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'App Settings',
            [
              _buildNotificationsTile(),
              _buildDarkModeTile(),
              _buildLanguageTile(),
              _buildDataExportTile(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Support',
            [
              _buildHelpTile(),
              _buildAboutTile(),
              _buildPrivacyTile(),
              _buildTermsTile(),
            ],
          ),
          const SizedBox(height: 24),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTile() {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    
    return ListTile(
      leading: const Icon(Icons.person),
      title: const Text('Account'),
      subtitle: Text(user?.email ?? 'Not signed in'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to account details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account details coming soon!')),
        );
      },
    );
  }

  Widget _buildProfileTile() {
    return ListTile(
      leading: const Icon(Icons.edit),
      title: const Text('Edit Profile'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to profile editing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile editing coming soon!')),
        );
      },
    );
  }

  Widget _buildGoalsTile() {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    
    return ListTile(
      leading: const Icon(Icons.flag),
      title: const Text('Fitness Goals'),
      subtitle: Text(user?.goals.join(', ') ?? 'No goals set'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to goals editing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goals editing coming soon!')),
        );
      },
    );
  }

  Widget _buildHealthKitTile() {
    final healthService = context.watch<HealthService>();
    
    return ListTile(
      leading: const Icon(Icons.favorite),
      title: const Text('Health Kit Sync'),
      subtitle: Text(healthService.isAuthorized ? 'Connected' : 'Not connected'),
      trailing: Switch(
        value: healthService.isAuthorized,
        onChanged: (value) async {
          if (value) {
            await healthService.requestPermissions();
          } else {
            // Disconnect Health Kit
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Health Kit disconnected')),
            );
          }
        },
      ),
    );
  }

  Widget _buildNutritionGoalsTile() {
    return ListTile(
      leading: const Icon(Icons.restaurant),
      title: const Text('Nutrition Goals'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showNutritionGoalsDialog();
      },
    );
  }

  Widget _buildWorkoutPreferencesTile() {
    return ListTile(
      leading: const Icon(Icons.fitness_center),
      title: const Text('Workout Preferences'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showWorkoutPreferencesDialog();
      },
    );
  }

  Widget _buildNotificationsTile() {
    return ListTile(
      leading: const Icon(Icons.notifications),
      title: const Text('Notifications'),
      trailing: Switch(
        value: _notificationsEnabled,
        onChanged: (value) {
          setState(() {
            _notificationsEnabled = value;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notifications ${value ? 'enabled' : 'disabled'}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDarkModeTile() {
    return ListTile(
      leading: const Icon(Icons.dark_mode),
      title: const Text('Dark Mode'),
      trailing: Switch(
        value: _darkMode,
        onChanged: (value) {
          setState(() {
            _darkMode = value;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dark mode ${value ? 'enabled' : 'disabled'}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageTile() {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('Language'),
      subtitle: Text(_language),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showLanguageDialog();
      },
    );
  }

  Widget _buildDataExportTile() {
    return ListTile(
      leading: const Icon(Icons.download),
      title: const Text('Export Data'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final storageService = context.read<StorageService>();
        final data = await storageService.exportData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported: ${data.length} items'),
          ),
        );
      },
    );
  }

  Widget _buildHelpTile() {
    return ListTile(
      leading: const Icon(Icons.help),
      title: const Text('Help & Support'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help & Support coming soon!')),
        );
      },
    );
  }

  Widget _buildAboutTile() {
    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('About Peregrine'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showAboutDialog();
      },
    );
  }

  Widget _buildPrivacyTile() {
    return ListTile(
      leading: const Icon(Icons.privacy_tip),
      title: const Text('Privacy Policy'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy Policy coming soon!')),
        );
      },
    );
  }

  Widget _buildTermsTile() {
    return ListTile(
      leading: const Icon(Icons.description),
      title: const Text('Terms of Service'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terms of Service coming soon!')),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return Card(
      color: Colors.red[50],
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.red),
        ),
        onTap: () {
          _showLogoutDialog();
        },
      ),
    );
  }

  void _showNutritionGoalsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nutrition Goals'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set your daily nutrition targets:'),
            SizedBox(height: 16),
            Text('• Calories: 2000'),
            Text('• Protein: 150g'),
            Text('• Carbs: 250g'),
            Text('• Fat: 65g'),
            Text('• Fiber: 25g'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWorkoutPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout Preferences'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Customize your workout experience:'),
            SizedBox(height: 16),
            Text('• Workout duration'),
            Text('• Exercise difficulty'),
            Text('• Rest periods'),
            Text('• Equipment available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Spanish'),
              value: 'Spanish',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('French'),
              value: 'French',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Peregrine'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Your AI-powered fitness companion'),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• Food recognition'),
            Text('• Health tracking'),
            Text('• AI coaching'),
            Text('• Personalized workouts'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService = context.read<AuthService>();
              await authService.signOut();
              
              // Navigate to onboarding
              Navigator.of(context).pushReplacementNamed('/onboarding');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
} 