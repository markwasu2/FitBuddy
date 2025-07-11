import 'package:hive/hive.dart';

part 'food_entry.g.dart';

@HiveType(typeId: 1)
class FoodEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double calories;

  @HiveField(3)
  double protein;

  @HiveField(4)
  double carbs;

  @HiveField(5)
  double fat;

  @HiveField(6)
  double fiber;

  @HiveField(7)
  double sugar;

  @HiveField(8)
  double sodium;

  @HiveField(9)
  double servingSize;

  @HiveField(10)
  String servingUnit;

  @HiveField(11)
  DateTime date;

  @HiveField(12)
  String mealType; // breakfast, lunch, dinner, snack

  @HiveField(13)
  String? imageUrl;

  @HiveField(14)
  DateTime createdAt;

  FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.servingSize,
    required this.servingUnit,
    required this.date,
    required this.mealType,
    this.imageUrl,
    required this.createdAt,
  });

  // Calculate total macros for the entry
  double get totalMacros => protein + carbs + fat;

  // Calculate percentage of each macro
  double get proteinPercentage => protein * 4 / calories * 100;
  double get carbsPercentage => carbs * 4 / calories * 100;
  double get fatPercentage => fat * 9 / calories * 100;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'date': date.toIso8601String(),
      'mealType': mealType,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: json['id'],
      name: json['name'],
      calories: json['calories'].toDouble(),
      protein: json['protein'].toDouble(),
      carbs: json['carbs'].toDouble(),
      fat: json['fat'].toDouble(),
      fiber: json['fiber'].toDouble(),
      sugar: json['sugar'].toDouble(),
      sodium: json['sodium'].toDouble(),
      servingSize: json['servingSize'].toDouble(),
      servingUnit: json['servingUnit'],
      date: DateTime.parse(json['date']),
      mealType: json['mealType'],
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 