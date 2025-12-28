import 'package:isar/isar.dart';

part 'workout_session_doc.g.dart';

@collection
class WorkoutSessionDoc {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date; // local date/time when started/completed
  
  late int dayIndex; // 1..daysPerWeek
  late bool completed;

  // optional, but handy
  String? planId; // you can ignore for now
}
