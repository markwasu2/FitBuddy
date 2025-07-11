import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shared/data/health/health_repository.dart';
import '../shared/data/health/health_sample.dart';

class UnifiedHealthView extends StatelessWidget {
  const UnifiedHealthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<HealthRepository>().refreshData();
            },
          ),
        ],
      ),
      body: Consumer<HealthRepository>(
        builder: (context, repository, child) {
          if (repository.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allSamples = repository.getAllSamples();
          
          if (allSamples.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildOverviewCard(context, allSamples),
              const SizedBox(height: 16),
              _buildMetricsGrid(context, allSamples),
              const SizedBox(height: 16),
              _buildProviderBreakdown(context, repository),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Health Data Available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect to health providers to see your data here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/health-providers');
            },
            icon: const Icon(Icons.link),
            label: const Text('Connect Providers'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, List<HealthSample> samples) {
    final steps = samples.where((s) => s.type == HealthSampleType.steps).toList();
    final calories = samples.where((s) => s.type == HealthSampleType.calories).toList();
    final heartRate = samples.where((s) => s.type == HealthSampleType.heartRate).toList();
    final sleep = samples.where((s) => s.type == HealthSampleType.sleep).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    'Steps',
                    steps.isNotEmpty ? steps.first.value.toStringAsFixed(0) : '0',
                    'steps',
                    Icons.directions_walk,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    'Calories',
                    calories.isNotEmpty ? calories.first.value.toStringAsFixed(0) : '0',
                    'kcal',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    'Heart Rate',
                    heartRate.isNotEmpty ? heartRate.first.value.toStringAsFixed(0) : '--',
                    'bpm',
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    'Sleep',
                    sleep.isNotEmpty ? sleep.first.value.toStringAsFixed(1) : '0',
                    'hours',
                    Icons.bedtime,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, List<HealthSample> samples) {
    final metricsByType = <HealthSampleType, List<HealthSample>>{};
    for (final sample in samples) {
      metricsByType.putIfAbsent(sample.type, () => []).add(sample);
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metricsByType.entries.map((entry) {
                final type = entry.key;
                final samples = entry.value;
                final latestSample = samples.first;
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getColorForType(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getColorForType(type).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getIconForType(type),
                        color: _getColorForType(type),
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latestSample.value.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getColorForType(type),
                        ),
                      ),
                      Text(
                        latestSample.unit,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        type.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderBreakdown(BuildContext context, HealthRepository repository) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data by Provider',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...repository.data.entries.map((entry) {
              final providerId = entry.key;
              final samples = entry.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getColorForProvider(providerId).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForProvider(providerId),
                        color: _getColorForProvider(providerId),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getProviderName(providerId),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${samples.length} data points',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${samples.length}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getColorForProvider(providerId),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getColorForType(HealthSampleType type) {
    switch (type) {
      case HealthSampleType.steps:
        return Colors.blue;
      case HealthSampleType.calories:
        return Colors.orange;
      case HealthSampleType.heartRate:
        return Colors.red;
      case HealthSampleType.sleep:
        return Colors.purple;
      case HealthSampleType.weight:
        return Colors.green;
      case HealthSampleType.height:
        return Colors.teal;
      case HealthSampleType.distance:
        return Colors.indigo;
      case HealthSampleType.hrv:
        return Colors.pink;
      case HealthSampleType.activeEnergy:
        return Colors.amber;
      case HealthSampleType.recovery:
        return Colors.cyan;
      case HealthSampleType.strain:
        return Colors.deepOrange;
      case HealthSampleType.bloodOxygen:
        return Colors.lightBlue;
      case HealthSampleType.bloodPressure:
        return Colors.deepPurple;
      case HealthSampleType.bodyFat:
        return Colors.brown;
      case HealthSampleType.bmi:
        return Colors.lime;
      case HealthSampleType.flightsClimbed:
        return Colors.blueGrey;
      case HealthSampleType.respiratoryRate:
        return Colors.lightGreen;
      case HealthSampleType.vo2Max:
        return Colors.deepOrange;
    }
  }

  IconData _getIconForType(HealthSampleType type) {
    switch (type) {
      case HealthSampleType.steps:
        return Icons.directions_walk;
      case HealthSampleType.calories:
        return Icons.local_fire_department;
      case HealthSampleType.heartRate:
        return Icons.favorite;
      case HealthSampleType.sleep:
        return Icons.bedtime;
      case HealthSampleType.weight:
        return Icons.monitor_weight;
      case HealthSampleType.height:
        return Icons.height;
      case HealthSampleType.distance:
        return Icons.route;
      case HealthSampleType.hrv:
        return Icons.timeline;
      case HealthSampleType.activeEnergy:
        return Icons.flash_on;
      case HealthSampleType.recovery:
        return Icons.refresh;
      case HealthSampleType.strain:
        return Icons.trending_up;
      case HealthSampleType.bloodOxygen:
        return Icons.air;
      case HealthSampleType.bloodPressure:
        return Icons.favorite_border;
      case HealthSampleType.bodyFat:
        return Icons.person;
      case HealthSampleType.bmi:
        return Icons.analytics;
      case HealthSampleType.flightsClimbed:
        return Icons.stairs;
      case HealthSampleType.respiratoryRate:
        return Icons.air;
      case HealthSampleType.vo2Max:
        return Icons.speed;
    }
  }

  Color _getColorForProvider(dynamic providerId) {
    switch (providerId.toString()) {
      case 'ProviderId.appleHealth':
        return Colors.green;
      case 'ProviderId.googleFit':
        return Colors.blue;
      case 'ProviderId.fitbit':
        return Colors.pink;
      case 'ProviderId.whoop':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForProvider(dynamic providerId) {
    switch (providerId.toString()) {
      case 'ProviderId.appleHealth':
        return Icons.health_and_safety;
      case 'ProviderId.googleFit':
        return Icons.fitness_center;
      case 'ProviderId.fitbit':
        return Icons.watch;
      case 'ProviderId.whoop':
        return Icons.trending_up;
      default:
        return Icons.link;
    }
  }

  String _getProviderName(dynamic providerId) {
    switch (providerId.toString()) {
      case 'ProviderId.appleHealth':
        return 'Apple Health';
      case 'ProviderId.googleFit':
        return 'Google Fit';
      case 'ProviderId.fitbit':
        return 'Fitbit';
      case 'ProviderId.whoop':
        return 'WHOOP';
      default:
        return 'Unknown';
    }
  }
} 