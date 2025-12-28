import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

class TodayWorkoutScreen extends ConsumerStatefulWidget {
  const TodayWorkoutScreen({super.key});

  @override
  ConsumerState<TodayWorkoutScreen> createState() => _TodayWorkoutScreenState();
}

class _TodayWorkoutScreenState extends ConsumerState<TodayWorkoutScreen> {
  // Track completion checkboxes locally (Phase 1.5 only)
  final Map<String, bool> _done = {};

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
                    // Confirm
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Complete workout?'),
                        content: Text(
                          'You checked $checkedCount/${exercises.length} exercises.\n\nMark this session as completed?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Complete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    bool sameDay(DateTime a, DateTime b) =>
                        a.year == b.year && a.month == b.month && a.day == b.day;

                    final now = DateTime.now();
                    final last = await repo.getLatestWorkoutSession();

                    // If there's already an open session today, complete it instead of creating another.
                    if (last != null && sameDay(last.date, now) && last.completed == false) {
                      await repo.completeSession(last.id);
                    } else {
                      final session = await repo.startTodaySession(dayIndex: dayIndex);
                      await repo.completeSession(session.id);
                    }

                    ref.invalidate(todayWorkoutDayProvider);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Workout completed ✅ ($checkedCount/${exercises.length})',
                          ),
                        ),
                      );
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Header
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${doc.planName} • Day $dayIndex of ${doc.daysPerWeek}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (warmupEnabled) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Warm-up sets (main/secondary lifts):',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
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

                        // Exercises list (with warm-up line + rest)
                        Expanded(
                          child: ListView.builder(
                            itemCount: exercises.length,
                            itemBuilder: (context, i) {
                              final ex = exercises[i];

                              final id = (ex['exerciseId'] ?? 'ex_$i')
                                  .toString();
                              final key = 'd$dayIndex:$id';

                              final name =
                                  ex['name']?.toString() ?? 'Exercise';
                              final sets = ex['workingSets'] ?? '?';

                              final repRaw = ex['repRange'];
                              int? repMin;
                              int? repMax;
                              if (repRaw is Map) {
                                final rep =
                                    Map<String, dynamic>.from(repRaw);
                                final minVal = rep['min'];
                                final maxVal = rep['max'];
                                if (minVal is num) repMin = minVal.toInt();
                                if (maxVal is num) repMax = maxVal.toInt();
                              }
                              final repText = (repMin != null && repMax != null)
                                  ? '$repMin–$repMax'
                                  : '?';

                              final liftClass =
                                  ex['liftClass']?.toString() ?? 'accessory';
                              final showWarmup =
                                  (liftClass == 'main' ||
                                          liftClass == 'secondary') &&
                                      warmupEnabled;

                              // Rest seconds (prefer per-exercise, fallback by class)
                              int restSec = (liftClass == 'main' ||
                                      liftClass == 'secondary')
                                  ? 150
                                  : 90;
                              final restRaw = ex['restSeconds'];
                              if (restRaw is num) {
                                restSec = restRaw.toInt();
                              }

                              final checked = _done[key] ?? false;

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: checked,
                                        onChanged: (v) => setState(
                                          () => _done[key] = v ?? false,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              const SizedBox(height: 2),
                                              Text('$sets sets × $repText reps'),
                                              if (showWarmup) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  warmupText,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () => _startRest(
                                          seconds: restSec,
                                          label: name,
                                        ),
                                        child: Text('Rest ${restSec}s'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 8),

                        FilledButton(
                          onPressed: completeWorkout,
                          child: const Text('Complete Workout'),
                        ),
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
