import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shared/data/health/health_repository.dart';
import '../shared/data/health/provider_id.dart';

class HealthProvidersView extends StatelessWidget {
  const HealthProvidersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Providers'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<HealthRepository>(
        builder: (context, repository, child) {
          if (repository.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProviderCard(
                context,
                repository,
                ProviderId.appleHealth,
                'Apple Health',
                'Connect to Apple HealthKit for health data',
                Icons.health_and_safety,
                Colors.green,
              ),
              const SizedBox(height: 16),
              _buildProviderCard(
                context,
                repository,
                ProviderId.googleFit,
                'Google Fit',
                'Connect to Google Fit for health data',
                Icons.fitness_center,
                Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildProviderCard(
                context,
                repository,
                ProviderId.fitbit,
                'Fitbit',
                'Connect to Fitbit for activity and sleep data',
                Icons.watch,
                Colors.pink,
              ),
              const SizedBox(height: 16),
              _buildProviderCard(
                context,
                repository,
                ProviderId.whoop,
                'WHOOP',
                'Connect to WHOOP for strain and recovery data',
                Icons.trending_up,
                Colors.orange,
              ),
              const SizedBox(height: 32),
              _buildDataSummary(context, repository),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProviderCard(
    BuildContext context,
    HealthRepository repository,
    ProviderId providerId,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isConnected = _isProviderConnected(repository, providerId);
    final samples = repository.getSamplesByProvider(providerId);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isConnected,
                  onChanged: (value) {
                    if (value) {
                      repository.authorizeProvider(providerId);
                    } else {
                      repository.disconnectProvider(providerId);
                    }
                  },
                  activeColor: color,
                ),
              ],
            ),
            if (isConnected && samples.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recent Data',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: samples.take(3).map((sample) {
                  return Chip(
                    label: Text('${sample.type.name}: ${sample.value.toStringAsFixed(1)} ${sample.unit}'),
                    backgroundColor: color.withOpacity(0.1),
                    labelStyle: TextStyle(color: color),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isProviderConnected(HealthRepository repository, ProviderId providerId) {
    switch (providerId) {
      case ProviderId.appleHealth:
        return repository.appleHealthProvider?.isAuthorized ?? false;
      case ProviderId.googleFit:
        return repository.googleFitProvider?.isAuthorized ?? false;
      case ProviderId.fitbit:
        return repository.fitbitProvider?.isAuthorized ?? false;
      case ProviderId.whoop:
        return repository.whoopProvider?.isAuthorized ?? false;
    }
  }

  Widget _buildDataSummary(BuildContext context, HealthRepository repository) {
    final allSamples = repository.getAllSamples();
    
    if (allSamples.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.health_and_safety_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Health Data Available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect to one or more health providers to see your data here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Total Samples',
                    allSamples.length.toString(),
                    Icons.data_usage,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Providers',
                    repository.data.keys.length.toString(),
                    Icons.link,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Recent Data by Type',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _getSampleTypeCounts(allSamples).entries.map((entry) {
                return Chip(
                  label: Text('${entry.key.name}: ${entry.value}'),
                  backgroundColor: Colors.grey[100],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Map<dynamic, int> _getSampleTypeCounts(List<dynamic> samples) {
    final counts = <dynamic, int>{};
    for (final sample in samples) {
      counts[sample.type] = (counts[sample.type] ?? 0) + 1;
    }
    return counts;
  }
} 