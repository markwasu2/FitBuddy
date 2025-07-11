import 'package:hive/hive.dart';

part 'workout_entry.g.dart';

@HiveType(typeId: 2)
class WorkoutEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type; // cardio, strength, flexibility, etc.

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  int duration; // in minutes

  @HiveField(5)
  double caloriesBurned;

  @HiveField(6)
  List<ExerciseSet> exercises;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  WorkoutEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.duration,
    required this.caloriesBurned,
    required this.exercises,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'date': date.toIso8601String(),
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WorkoutEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutEntry(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      date: DateTime.parse(json['date']),
      duration: json['duration'],
      caloriesBurned: json['caloriesBurned'].toDouble(),
      exercises: (json['exercises'] as List)
          .map((e) => ExerciseSet.fromJson(e))
          .toList(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

@HiveType(typeId: 3)
class ExerciseSet extends HiveObject {
  @HiveField(0)
  String exerciseName;

  @HiveField(1)
  int sets;

  @HiveField(2)
  int reps;

  @HiveField(3)
  double weight; // in kg

  @HiveField(4)
  int restTime; // in seconds

  @HiveField(5)
  String? notes;

  ExerciseSet({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restTime,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'restTime': restTime,
      'notes': notes,
    };
  }

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      exerciseName: json['exerciseName'],
      sets: json['sets'],
      reps: json['reps'],
      weight: json['weight'].toDouble(),
      restTime: json['restTime'],
      notes: json['notes'],
    );
  }
} 