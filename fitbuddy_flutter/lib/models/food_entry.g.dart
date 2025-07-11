// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodEntryAdapter extends TypeAdapter<FoodEntry> {
  @override
  final int typeId = 1;

  @override
  FoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodEntry(
      id: fields[0] as String,
      name: fields[1] as String,
      calories: fields[2] as double,
      protein: fields[3] as double,
      carbs: fields[4] as double,
      fat: fields[5] as double,
      fiber: fields[6] as double,
      sugar: fields[7] as double,
      sodium: fields[8] as double,
      servingSize: fields[9] as double,
      servingUnit: fields[10] as String,
      date: fields[11] as DateTime,
      mealType: fields[12] as String,
      imageUrl: fields[13] as String?,
      createdAt: fields[14] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FoodEntry obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.calories)
      ..writeByte(3)
      ..write(obj.protein)
      ..writeByte(4)
      ..write(obj.carbs)
      ..writeByte(5)
      ..write(obj.fat)
      ..writeByte(6)
      ..write(obj.fiber)
      ..writeByte(7)
      ..write(obj.sugar)
      ..writeByte(8)
      ..write(obj.sodium)
      ..writeByte(9)
      ..write(obj.servingSize)
      ..writeByte(10)
      ..write(obj.servingUnit)
      ..writeByte(11)
      ..write(obj.date)
      ..writeByte(12)
      ..write(obj.mealType)
      ..writeByte(13)
      ..write(obj.imageUrl)
      ..writeByte(14)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
