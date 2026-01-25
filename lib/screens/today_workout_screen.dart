import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../services/analytics_service.dart';
import '../widgets/workout_calendar.dart';
import '../data/exercise_alternatives.dart';
import 'workout_completion_screen.dart';

class TodayWorkoutScreen extends ConsumerStatefulWidget {
  const TodayWorkoutScreen({super.key});

  @override
  ConsumerState<TodayWorkoutScreen> createState() => _TodayWorkoutScreenState();
}

class _TodayWorkoutScreenState extends ConsumerState<TodayWorkoutScreen> {
  // Track completion checkboxes locally (Phase 1.5 only)
  final Map<String, bool> _done = {};

  // Track exercise swaps (original exercise key -> new exercise name)
  final Map<String, String> _swappedExercises = {};

  Timer? _timer;
  int? _restLeftSec;
  String? _restLabel;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRest({required int seconds, required String label}) {
    _timer?.cancel();
    setState(() {
      _restLeftSec = seconds;
      _restLabel = label;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final left = _restLeftSec ?? 0;
      if (left <= 1) {
        t.cancel();
        setState(() => _restLeftSec = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rest done — $label')),
        );
        return;
      }
      setState(() => _restLeftSec = left - 1);
    });
  }

  void _stopRest() {
    _timer?.cancel();
    setState(() {
      _restLeftSec = null;
      _restLabel = null;
    });
  }

  String _formatMmSs(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// Show skip workout dialog
  Future<void> _showSkipWorkoutDialog({
    required BuildContext context,
    required int dayIndex,
    required String workoutTitle,
  }) async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SkipWorkoutSheet(workoutTitle: workoutTitle),
    );

    if (result != null && mounted) {
      final repo = ref.read(primeRepoProvider);
      await repo.skipSession(dayIndex: dayIndex, reason: result);

      // Track analytics
      final analytics = AnalyticsService();
      await analytics.logFeatureUsed(featureName: 'workout_skipped');

      ref.invalidate(todayWorkoutDayProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout skipped. Rest up and come back stronger!'),
          ),
        );
        Navigator.of(context).pop(); // Go back to home
      }
    }
  }

  /// Show alternatives dialog for an exercise
  /// If aiAlternatives is provided (from the workout template), use those first.
  /// Otherwise fall back to the static alternatives database.
  Future<void> _showAlternativesDialog({
    required String exerciseKey,
    required String originalName,
    List<Map<String, dynamic>>? aiAlternatives,
  }) async {
    // Prefer AI-generated alternatives if available
    List<ExerciseOption> alternatives;
    if (aiAlternatives != null && aiAlternatives.isNotEmpty) {
      alternatives = aiAlternatives.map((alt) => ExerciseOption(
        alt['name']?.toString() ?? 'Alternative',
        alt['reason']?.toString() ?? 'Similar movement pattern',
      )).toList();
    } else {
      alternatives = ExerciseAlternatives.findAlternatives(originalName) ??
          ExerciseAlternatives.getDefaultAlternatives(originalName);
    }

    final currentName = _swappedExercises[exerciseKey] ?? originalName;
    final isSwapped = _swappedExercises.containsKey(exerciseKey);

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ExerciseAlternativesSheet(
        originalName: originalName,
        currentName: currentName,
        alternatives: alternatives,
        isSwapped: isSwapped,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (result == '__RESET__') {
          _swappedExercises.remove(exerciseKey);
        } else {
          _swappedExercises[exerciseKey] = result;
        }
      });

      // Track analytics
      final analytics = AnalyticsService();
      if (result == '__RESET__') {
        // Could add an analytics event for resetting exercise
      } else {
        await analytics.logFeatureUsed(featureName: 'exercise_swap');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(primeRepoProvider);

    final asyncTemplate = ref.watch(latestWorkoutTemplateProvider);
    final asyncDayIndex = ref.watch(todayWorkoutDayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Workout")),
      body: Stack(
        children: [
          asyncTemplate.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (doc) {
              if (doc == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No workout plan saved yet.'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/workout'),
                          child: const Text('Create Workout Plan'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Decode template JSON safely
              final decoded = jsonDecode(doc.json);
              if (decoded is! Map) {
                return const Center(
                  child: Text('Saved workout plan is corrupted.'),
                );
              }
              final template = Map<String, dynamic>.from(decoded);

              final rawDays = template['days'];
              if (rawDays is! List) {
                return const Center(
                  child: Text('Saved workout plan is missing days.'),
                );
              }
              final days = rawDays
                  .map((d) => Map<String, dynamic>.from(d as Map))
                  .toList();

              // Warm-up protocol (optional display)
              final warmup = template['globalDefaults']?['warmup'];
              final warmupEnabled = warmup is Map && warmup['enabled'] == true;
              const warmupText = 'Warm-up: 50%×6, 70%×4, 85%×2 (opt)';

              return asyncDayIndex.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (dayIndex) {
                  if (dayIndex == null) {
                    return const Center(child: Text('No workout plan found.'));
                  }

                  // Find matching day by dayIndex, fallback to array position
                  Map<String, dynamic>? day;
                  for (final d in days) {
                    final di = d['dayIndex'];
                    if (di is num && di.toInt() == dayIndex) {
                      day = d;
                      break;
                    }
                  }
                  day ??= (dayIndex - 1 < days.length)
                      ? days[dayIndex - 1]
                      : days.first;

                  final title = day['title']?.toString() ?? 'Day $dayIndex';

                  final rawExercises = day['exercises'];
                  if (rawExercises is! List) {
                    return const Center(
                      child: Text('This workout day has no exercises.'),
                    );
                  }
                  final exercises = rawExercises
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();

                  // Count checked for summary
                  int checkedCount = 0;
                  for (final ex in exercises) {
                    final id = (ex['exerciseId'] ?? '').toString();
                    final k = 'd$dayIndex:$id';
                    if ((_done[k] ?? false) == true) checkedCount++;
                  }

                  Future<void> completeWorkout() async {
                    // Show completion dialog with optional notes
                    final result = await showModalBottomSheet<Map<String, dynamic>?>(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (ctx) => _CompleteWorkoutSheet(
                        workoutTitle: title,
                        checkedCount: checkedCount,
                        totalExercises: exercises.length,
                      ),
                    );

                    if (result == null) return;

                    final notes = result['notes'] as String?;

                    bool sameDay(DateTime a, DateTime b) =>
                        a.year == b.year && a.month == b.month && a.day == b.day;

                    final now = DateTime.now();
                    final last = await repo.getLatestWorkoutSession();

                    // If there's already an open session today, complete it instead of creating another.
                    if (last != null && sameDay(last.date, now) && last.completed == false) {
                      await repo.completeSession(last.id, notes: notes);
                    } else {
                      final session = await repo.startTodaySession(dayIndex: dayIndex);
                      await repo.completeSession(session.id, notes: notes);
                    }

                    // Track analytics
                    final analytics = AnalyticsService();
                    await analytics.logWorkoutCompleted(
                      dayIndex: dayIndex,
                      totalDays: doc.daysPerWeek,
                      exercisesCompleted: checkedCount,
                      totalExercises: exercises.length,
                    );

                    ref.invalidate(todayWorkoutDayProvider);

                    if (mounted) {
                      // Navigate to completion screen
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => WorkoutCompletionScreen(
                            dayIndex: dayIndex,
                            totalDays: doc.daysPerWeek,
                            completedExercises: checkedCount,
                            totalExercises: exercises.length,
                            workoutTitle: title,
                          ),
                        ),
                      );

                      // Refresh when coming back
                      ref.invalidate(todayWorkoutDayProvider);
                    }
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Workout Calendar
                        WorkoutCalendar(
                          trainingDaysPerWeek: doc.daysPerWeek,
                        ),
                        const SizedBox(height: 16),
                        
                        // Header
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${doc.planName} • Day $dayIndex of ${doc.daysPerWeek}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (warmupEnabled) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Warm-up sets (main/secondary lifts):',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '50%×6, 70%×4, 85%×2 (optional)',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Exercises list (now using List.generate instead of ListView.builder)
                        ...List.generate(exercises.length, (i) {
                          final ex = exercises[i];

                          final id = (ex['exerciseId'] ?? 'ex_$i').toString();
                          final key = 'd$dayIndex:$id';

                          final originalName = ex['name']?.toString() ?? 'Exercise';
                          final displayName = _swappedExercises[key] ?? originalName;
                          final isSwapped = _swappedExercises.containsKey(key);
                          final sets = ex['workingSets'] ?? '?';

                          final repRaw = ex['repRange'];
                          int? repMin;
                          int? repMax;
                          if (repRaw is Map) {
                            final rep = Map<String, dynamic>.from(repRaw);
                            final minVal = rep['min'];
                            final maxVal = rep['max'];
                            if (minVal is num) repMin = minVal.toInt();
                            if (maxVal is num) repMax = maxVal.toInt();
                          }
                          final repText = (repMin != null && repMax != null)
                              ? '$repMin–$repMax'
                              : '?';

                          final liftClass = ex['liftClass']?.toString() ?? 'accessory';
                          final showWarmup =
                              (liftClass == 'main' || liftClass == 'secondary') &&
                                  warmupEnabled;

                          // Rest seconds (prefer per-exercise, fallback by class)
                          int restSec = (liftClass == 'main' || liftClass == 'secondary')
                              ? 150
                              : 90;
                          final restRaw = ex['restSeconds'];
                          if (restRaw is num) {
                            restSec = restRaw.toInt();
                          }

                          final checked = _done[key] ?? false;

                          // Extract AI-generated alternatives if available
                          List<Map<String, dynamic>>? aiAlternatives;
                          final rawAlts = ex['alternatives'];
                          if (rawAlts is List && rawAlts.isNotEmpty) {
                            aiAlternatives = rawAlts
                                .whereType<Map>()
                                .map((a) => Map<String, dynamic>.from(a))
                                .toList();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showAlternativesDialog(
                                  exerciseKey: key,
                                  originalName: originalName,
                                  aiAlternatives: aiAlternatives,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: checked,
                                        onChanged: (v) =>
                                            setState(() => _done[key] = v ?? false),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      displayName,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium,
                                                    ),
                                                  ),
                                                  if (isSwapped)
                                                    Icon(
                                                      Icons.swap_horiz,
                                                      size: 16,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text('$sets sets × $repText reps'),
                                              if (isSwapped) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Originally: $originalName',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        fontStyle: FontStyle.italic,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                              if (showWarmup && !isSwapped) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  warmupText,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                              // Tap hint
                                              const SizedBox(height: 4),
                                              Text(
                                                'Tap for alternatives',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withOpacity(0.7),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () => _startRest(
                                          seconds: restSec,
                                          label: displayName,
                                        ),
                                        child: Text('Rest ${restSec}s'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 16),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: completeWorkout,
                                child: const Text('Complete Workout'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => _showSkipWorkoutDialog(
                                context: context,
                                dayIndex: dayIndex,
                                workoutTitle: title,
                              ),
                              child: const Text('Skip'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 80), // Extra space for bottom navigation
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // Rest banner (bottom)
          if (_restLeftSec != null && _restLabel != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rest • ${_restLabel!} • ${_formatMmSs(_restLeftSec!.clamp(0, 10 * 60))}',
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _stopRest,
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet for selecting exercise alternatives
class _ExerciseAlternativesSheet extends StatelessWidget {
  final String originalName;
  final String currentName;
  final List<ExerciseOption> alternatives;
  final bool isSwapped;

  const _ExerciseAlternativesSheet({
    required this.originalName,
    required this.currentName,
    required this.alternatives,
    required this.isSwapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercise Alternatives',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose an alternative for $originalName',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Current selection indicator
            if (isSwapped) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Currently using: $currentName',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Reset option (if swapped)
            if (isSwapped)
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.undo,
                    color: theme.colorScheme.onErrorContainer,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Reset to Original',
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  'Go back to $originalName',
                  style: theme.textTheme.bodySmall,
                ),
                onTap: () => Navigator.pop(context, '__RESET__'),
              ),

            if (isSwapped) const Divider(height: 24),

            // Alternatives list
            Text(
              'Available Alternatives',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            ...alternatives.map((alt) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 20,
                ),
              ),
              title: Text(
                alt.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: currentName == alt.name
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                alt.description,
                style: theme.textTheme.bodySmall,
              ),
              trailing: currentName == alt.name
                  ? Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                    )
                  : null,
              onTap: () => Navigator.pop(context, alt.name),
            )),

            const SizedBox(height: 16),

            // Info footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Swapping exercises helps you work around equipment availability or comfort level while maintaining similar training benefits.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for completing a workout with optional notes
class _CompleteWorkoutSheet extends StatefulWidget {
  final String workoutTitle;
  final int checkedCount;
  final int totalExercises;

  const _CompleteWorkoutSheet({
    required this.workoutTitle,
    required this.checkedCount,
    required this.totalExercises,
  });

  @override
  State<_CompleteWorkoutSheet> createState() => _CompleteWorkoutSheetState();
}

class _CompleteWorkoutSheetState extends State<_CompleteWorkoutSheet> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completionPercent =
        (widget.checkedCount / widget.totalExercises * 100).round();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.check,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Workout',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.workoutTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${widget.checkedCount}/${widget.totalExercises}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Exercises',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$completionPercent%',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: completionPercent >= 80
                                ? Colors.green
                                : completionPercent >= 50
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                        Text(
                          'Completed',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Notes field
            Text(
              'How did it go? (optional)',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                hintText:
                    'e.g. Felt strong today, increased weight on squats...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.edit_note),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context, {
                        'notes': _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
                      });
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Complete Workout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for skipping a workout with a reason
class _SkipWorkoutSheet extends StatefulWidget {
  final String workoutTitle;

  const _SkipWorkoutSheet({required this.workoutTitle});

  @override
  State<_SkipWorkoutSheet> createState() => _SkipWorkoutSheetState();
}

class _SkipWorkoutSheetState extends State<_SkipWorkoutSheet> {
  String? _selectedReason;
  final _customReasonCtrl = TextEditingController();

  static const _skipReasons = [
    ('sick', 'Feeling sick', Icons.sick),
    ('tired', 'Too tired / fatigued', Icons.bedtime),
    ('busy', 'No time today', Icons.schedule),
    ('injury', 'Injury / pain', Icons.healing),
    ('rest', 'Need extra rest', Icons.self_improvement),
    ('travel', 'Traveling', Icons.flight),
    ('other', 'Other reason', Icons.edit),
  ];

  @override
  void dispose() {
    _customReasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skip Workout?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.workoutTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'It\'s okay to skip sometimes. Consistency over time matters more than perfection.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Why are you skipping today?',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 12),

            // Reason chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skipReasons.map((reason) {
                final (id, label, icon) = reason;
                final isSelected = _selectedReason == id;

                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16),
                      const SizedBox(width: 6),
                      Text(label),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedReason = selected ? id : null;
                    });
                  },
                );
              }).toList(),
            ),

            // Custom reason field (if "other" is selected)
            if (_selectedReason == 'other') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customReasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tell us more (optional)',
                  hintText: 'What\'s going on?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedReason == null
                        ? null
                        : () {
                            String reason = _selectedReason!;
                            if (_selectedReason == 'other' &&
                                _customReasonCtrl.text.isNotEmpty) {
                              reason = _customReasonCtrl.text;
                            }
                            Navigator.pop(context, reason);
                          },
                    child: const Text('Skip Workout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}