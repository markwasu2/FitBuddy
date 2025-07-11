import 'package:freezed_annotation/freezed_annotation.dart';
import 'provider_id.dart';

part 'health_sample.freezed.dart';
part 'health_sample.g.dart';

enum HealthSampleType {
  steps,
  calories,
  heartRate,
  weight,
  height,
  sleep,
  distance,
  hrv,
  activeEnergy,
  recovery,
  strain,
  bloodOxygen,
  bloodPressure,
  bodyFat,
  bmi,
  flightsClimbed,
  respiratoryRate,
  vo2Max,
}

@freezed
class HealthSample with _$HealthSample {
  const factory HealthSample({
    required String id,
    required ProviderId providerId,
    required HealthSampleType type,
    required double value,
    required String unit,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> metadata,
  }) = _HealthSample;

  factory HealthSample.fromJson(Map<String, dynamic> json) => _$HealthSampleFromJson(json);
} 