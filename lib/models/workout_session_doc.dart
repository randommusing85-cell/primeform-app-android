import 'package:isar/isar.dart';

part 'workout_session_doc.g.dart';

@collection
class WorkoutSessionDoc {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date; // local date/time when started/completed

  late int dayIndex; // 1..daysPerWeek
  late bool completed;

  // Skip tracking
  bool skipped = false;
  String? skipReason;

  // Notes/feedback from the workout
  String? notes;

  // optional, but handy
  String? planId; // you can ignore for now
}
