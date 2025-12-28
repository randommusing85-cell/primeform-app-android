import 'package:isar/isar.dart';

part 'prime_plan.g.dart';

@collection
class PrimePlan {
  Id id = Isar.autoIncrement;

  late DateTime createdAt;

  late String planName;
  late int trainingDays;

  late int calories;
  late int proteinG;
  late int carbsG;
  late int fatG;

  late int stepTarget;
}
