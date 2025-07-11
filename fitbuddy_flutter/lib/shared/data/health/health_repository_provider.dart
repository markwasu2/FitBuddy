import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_repository.dart';
import 'provider_id.dart';

final healthRepositoryProvider = Provider.family<HealthRepository, ProviderId>((ref, id) {
  // TODO: Return the correct repository implementation for each provider
  throw UnimplementedError('Repository for provider: $id not implemented');
}); 