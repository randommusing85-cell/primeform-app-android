import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:isar/isar.dart';

import 'package:primeform_app/db/isar_db.dart';
import 'package:primeform_app/models/checkin.dart';
import 'package:primeform_app/models/prime_plan.dart';
import 'package:primeform_app/models/workout_template_doc.dart';
import 'package:primeform_app/models/workout_session_doc.dart';

class PrimeRepo {
  /* =========================
   * CHECK-INS
   * ========================= */

  Future<void> addCheckIn(CheckIn c) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.checkIns.put(c);
    });
  }

  Future<List<CheckIn>> latestCheckIns({int limit = 30}) async {
    final isar = await IsarDb.instance();
    return isar.checkIns.where().sortByTsDesc().limit(limit).findAll();
  }

  Stream<List<CheckIn>> watchLatestCheckIns({int limit = 30}) async* {
    final isar = await IsarDb.instance();
    yield* isar.checkIns
        .where()
        .sortByTsDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  /* =========================
   * NUTRITION / PRIME PLAN
   * ========================= */

  Future<void> upsertPlan(PrimePlan plan) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.primePlans.put(plan);
    });
  }

  Future<PrimePlan?> getActivePlan() async {
    final isar = await IsarDb.instance();
    return isar.primePlans.where().sortByCreatedAtDesc().findFirst();
  }

  /* =========================
   * WORKOUT TEMPLATES
   * ========================= */

  /// Low-level save (if you already have a doc)
  Future<void> saveWorkoutTemplate(WorkoutTemplateDoc doc) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.workoutTemplateDocs.put(doc);
    });
  }

  /// High-level save (from Firebase callable response)
  Future<void> saveWorkoutTemplateFromResponse({
    required Map<String, dynamic> response,
    required String sex,
  }) async {
    final ok = response['ok'] == true;
    if (!ok) {
      throw Exception('Workout template generation failed');
    }

    final template = Map<String, dynamic>.from(response['template'] as Map);

    final doc = WorkoutTemplateDoc()
      ..createdAt = DateTime.now()
      ..planName = (template['planName'] ?? 'Workout Plan').toString()
      ..sex = sex
      ..level = template['level'].toString()
      ..equipment = template['equipment'].toString()
      ..daysPerWeek = (template['daysPerWeek'] as num).toInt()
      ..json = jsonEncode(template);

    await saveWorkoutTemplate(doc);
  }

  Future<WorkoutTemplateDoc?> getLatestWorkoutTemplate() async {
    final isar = await IsarDb.instance();
    return isar.workoutTemplateDocs.where().sortByCreatedAtDesc().findFirst();
  }

  /* =========================
   * CLOUD FUNCTIONS
   * ========================= */

  Future<Map<String, dynamic>> generateWorkoutTemplate({
    required String sex,
    required String level,
    required String equipment,
    required int daysPerWeek,
    int sessionDurationMin = 60,
    String? constraints,
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('generateWorkoutTemplate');

    final res = await callable.call({
      'sex': sex,
      'level': level,
      'equipment': equipment,
      'daysPerWeek': daysPerWeek,
      'sessionDurationMin': sessionDurationMin,
      'constraints': constraints ?? 'none',
    });

    return Map<String, dynamic>.from(res.data as Map);
  }

  /* =========================
   * WORKOUT SESSIONS (PHASE 1.5)
   * ========================= */

  Future<WorkoutSessionDoc?> getLatestWorkoutSession() async {
    final isar = await IsarDb.instance();
    return isar.workoutSessionDocs.where().sortByDateDesc().findFirst();
  }

  Future<WorkoutSessionDoc> startTodaySession({required int dayIndex}) async {
    final isar = await IsarDb.instance();

    final session = WorkoutSessionDoc()
      ..date = DateTime.now()
      ..dayIndex = dayIndex
      ..completed = false;

    await isar.writeTxn(() async {
      await isar.workoutSessionDocs.put(session);
    });

    return session;
  }

  Future<void> completeSession(Id sessionId) async {
    final isar = await IsarDb.instance();
    final session = await isar.workoutSessionDocs.get(sessionId);
    if (session == null) return;

    session.completed = true;

    await isar.writeTxn(() async {
      await isar.workoutSessionDocs.put(session);
    });
  }
}
