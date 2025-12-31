import 'package:isar/isar.dart';

part 'user_profile.g.dart';

@collection
class UserProfile {
  Id id = Isar.autoIncrement;

  late int age;
  late String sex; // 'male' or 'female'
  late int heightCm;
  late double weightKg;

  late String goal; // 'cut', 'recomp', 'bulk'
  late String level; // 'beginner', 'intermediate', 'advanced'
  late String equipment; // 'gym', 'home_dumbbells', 'calisthenics'
  late int trainingDaysPerWeek;

  late DateTime createdAt;
  late DateTime updatedAt;
}