// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutEntryAdapter extends TypeAdapter<WorkoutEntry> {
  @override
  final int typeId = 2;

  @override
  WorkoutEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutEntry(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      date: fields[3] as DateTime,
      duration: fields[4] as int,
      caloriesBurned: fields[5] as double,
      exercises: (fields[6] as List).cast<ExerciseSet>(),
      notes: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.caloriesBurned)
      ..writeByte(6)
      ..write(obj.exercises)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseSetAdapter extends TypeAdapter<ExerciseSet> {
  @override
  final int typeId = 3;

  @override
  ExerciseSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseSet(
      exerciseName: fields[0] as String,
      sets: fields[1] as int,
      reps: fields[2] as int,
      weight: fields[3] as double,
      restTime: fields[4] as int,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseSet obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.exerciseName)
      ..writeByte(1)
      ..write(obj.sets)
      ..writeByte(2)
      ..write(obj.reps)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.restTime)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
