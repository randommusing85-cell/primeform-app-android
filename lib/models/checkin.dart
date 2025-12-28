import 'package:isar/isar.dart';

part 'checkin.g.dart';

@collection
class CheckIn {
  Id id = Isar.autoIncrement;

  late DateTime ts;
  late double weightKg;
  late double waistCm;
  late int stepsToday;

  String? note;
}
