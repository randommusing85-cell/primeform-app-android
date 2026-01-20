import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:isar/isar.dart';

import 'package:primeform_app/db/isar_db.dart';
import 'package:primeform_app/models/checkin.dart';
import 'package:primeform_app/models/prime_plan.dart';
import 'package:primeform_app/models/workout_template_doc.dart';
import 'package:primeform_app/models/workout_session_doc.dart';
import 'package:primeform_app/models/meal_log.dart';

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
   * MEAL LOGS
   * ========================= */

  Future<void> addMealLog(MealLog meal) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.mealLogs.put(meal);
    });
  }

  Future<void> deleteMealLog(Id mealId) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.mealLogs.delete(mealId);
    });
  }

  /// Get all meals for today
  Future<List<MealLog>> getTodayMeals() async {
    final isar = await IsarDb.instance();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return isar.mealLogs
        .filter()
        .tsBetween(startOfDay, endOfDay)
        .sortByTs()
        .findAll();
  }

  /// Watch today's meals (reactive)
  Stream<List<MealLog>> watchTodayMeals() async* {
    final isar = await IsarDb.instance();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    yield* isar.mealLogs
        .filter()
        .tsBetween(startOfDay, endOfDay)
        .sortByTs()
        .watch(fireImmediately: true);
  }

  /// Get meals for a specific date
  Future<List<MealLog>> getMealsForDate(DateTime date) async {
    final isar = await IsarDb.instance();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return isar.mealLogs
        .filter()
        .tsBetween(startOfDay, endOfDay)
        .sortByTs()
        .findAll();
  }

  /// Get meals for the last N days (for adherence calculation)
  Future<List<MealLog>> getMealsForLastDays(int days) async {
    final isar = await IsarDb.instance();
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final endDate = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));

    return isar.mealLogs
        .filter()
        .tsBetween(startDate, endDate)
        .sortByTsDesc()
        .findAll();
  }

  /// Get daily macro totals for the last N days
  Future<List<DailyMacroTotal>> getDailyMacroTotals(int days) async {
    final meals = await getMealsForLastDays(days);
    
    // Group by date
    final Map<String, List<MealLog>> byDate = {};
    for (final meal in meals) {
      final dateKey = '${meal.ts.year}-${meal.ts.month}-${meal.ts.day}';
      byDate.putIfAbsent(dateKey, () => []).add(meal);
    }
    
    // Calculate totals per day
    final List<DailyMacroTotal> totals = [];
    byDate.forEach((dateKey, dayMeals) {
      final parts = dateKey.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      
      int protein = 0;
      int carbs = 0;
      int fat = 0;
      
      for (final meal in dayMeals) {
        protein += meal.proteinG;
        carbs += meal.carbsG;
        fat += meal.fatG;
      }
      
      totals.add(DailyMacroTotal(
        date: date,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
        mealCount: dayMeals.length,
      ));
    });
    
    // Sort by date descending
    totals.sort((a, b) => b.date.compareTo(a.date));
    
    return totals;
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
    List<String>? injuries,
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('generateWorkoutTemplate');

    // Build constraints string including injuries
    String finalConstraints = constraints ?? 'none';
    if (injuries != null && injuries.isNotEmpty) {
      final injuryText = injuries.map((i) => i.replaceAll('_', ' ')).join(', ');
      if (finalConstraints == 'none') {
        finalConstraints = 'User has injuries/limitations: $injuryText. Avoid exercises that aggravate these areas and provide safe alternatives.';
      } else {
        finalConstraints += ' Additionally, user has injuries/limitations: $injuryText. Avoid exercises that aggravate these areas.';
      }
    }

    final res = await callable.call({
      'sex': sex,
      'level': level,
      'equipment': equipment,
      'daysPerWeek': daysPerWeek,
      'sessionDurationMin': sessionDurationMin,
      'constraints': finalConstraints,
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

  /// NEW: Get all sessions (completed or not) in a date range
  Future<List<WorkoutSessionDoc>> getSessionsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final isar = await IsarDb.instance();
  
    return isar.workoutSessionDocs
        .filter()
        .dateBetween(startDate, endDate)
        .sortByDate()
        .findAll();
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

  /// Get completed sessions for this week
  Future<List<WorkoutSessionDoc>> getThisWeekSessions() async {
    final isar = await IsarDb.instance();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartMidnight = DateTime(weekStart.year, weekStart.month, weekStart.day);

    return isar.workoutSessionDocs
        .filter()
        .dateGreaterThan(weekStartMidnight)
        .and()
        .completedEqualTo(true)
        .findAll();
  }
}

/// Helper class for daily macro totals
class DailyMacroTotal {
  final DateTime date;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int mealCount;

  DailyMacroTotal({
    required this.date,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.mealCount,
  });

  int get calories => (proteinG * 4) + (carbsG * 4) + (fatG * 9);
}