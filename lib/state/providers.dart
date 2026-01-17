import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:primeform_app/repos/prime_repo.dart';
import 'package:primeform_app/repos/user_profile_repo.dart';
import 'package:primeform_app/models/checkin.dart';
import 'package:primeform_app/models/prime_plan.dart';
import 'package:primeform_app/models/workout_template_doc.dart';
import 'package:primeform_app/models/user_profile.dart';
import 'package:primeform_app/models/meal_log.dart';

final primeRepoProvider = Provider<PrimeRepo>((ref) => PrimeRepo());

final userProfileRepoProvider = Provider<UserProfileRepo>(
  (ref) => UserProfileRepo(),
);

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repo = ref.watch(userProfileRepoProvider);
  return repo.getProfile();
});

final latestCheckInsStreamProvider = StreamProvider.autoDispose<List<CheckIn>>((
  ref,
) {
  final repo = ref.watch(primeRepoProvider);
  return repo.watchLatestCheckIns(limit: 30);
});

// Today's meals stream provider
final todayMealsStreamProvider = StreamProvider.autoDispose<List<MealLog>>((
  ref,
) {
  final repo = ref.watch(primeRepoProvider);
  return repo.watchTodayMeals();
});

// Weekly macro totals provider (for adherence card)
final weeklyMacroTotalsProvider = FutureProvider.autoDispose<List<DailyMacroTotal>>((
  ref,
) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.getDailyMacroTotals(7);
});

final activePlanProvider = FutureProvider.autoDispose<PrimePlan?>((ref) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.getActivePlan();
});

final latestWorkoutTemplateProvider =
    FutureProvider<WorkoutTemplateDoc?>((ref) async {
  final repo = ref.read(primeRepoProvider);
  return repo.getLatestWorkoutTemplate();
});

final todayWorkoutDayProvider = FutureProvider<int?>((ref) async {
  final repo = ref.read(primeRepoProvider);

  final template = await repo.getLatestWorkoutTemplate();
  if (template == null) return null;

  final daysPerWeek = template.daysPerWeek;

  final last = await repo.getLatestWorkoutSession();
  if (last == null) return 1;

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  final now = DateTime.now();

  // If today's session already exists and isn't completed, keep the same dayIndex.
  if (isSameDay(last.date, now) && last.completed == false) {
    return last.dayIndex;
  }

  // If the last session is completed (today or earlier), advance to next day.
  if (last.completed == true) {
    final next = last.dayIndex + 1;
    return next > daysPerWeek ? 1 : next;
  }

  // If last session isn't completed and it's from a previous day, keep it (carry forward).
  return last.dayIndex;
});

// This week's completed sessions provider
final thisWeekSessionsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.getThisWeekSessions();
});