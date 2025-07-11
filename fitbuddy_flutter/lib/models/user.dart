import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  DateTime dateOfBirth;

  @HiveField(4)
  double height; // in cm

  @HiveField(5)
  double weight; // in kg

  @HiveField(6)
  String gender;

  @HiveField(7)
  String activityLevel;

  @HiveField(8)
  List<String> goals;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.dateOfBirth,
    required this.height,
    required this.weight,
    required this.gender,
    required this.activityLevel,
    required this.goals,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate BMI
  double get bmi => weight / ((height / 100) * (height / 100));

  // Calculate BMR using Mifflin-St Jeor Equation
  double get bmr {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * _calculateAge()) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * _calculateAge()) - 161;
    }
  }

  // Calculate TDEE (Total Daily Energy Expenditure)
  double get tdee {
    double activityMultiplier = _getActivityMultiplier();
    return bmr * activityMultiplier;
  }

  int _calculateAge() {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  double _getActivityMultiplier() {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.2;
      case 'lightly_active':
        return 1.375;
      case 'moderately_active':
        return 1.55;
      case 'very_active':
        return 1.725;
      case 'extremely_active':
        return 1.9;
      default:
        return 1.2;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'height': height,
      'weight': weight,
      'gender': gender,
      'activityLevel': activityLevel,
      'goals': goals,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      height: json['height'].toDouble(),
      weight: json['weight'].toDouble(),
      gender: json['gender'],
      activityLevel: json['activityLevel'],
      goals: List<String>.from(json['goals']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
} 