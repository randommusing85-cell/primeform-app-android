import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

class WorkoutPlanScreen extends ConsumerStatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  ConsumerState<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends ConsumerState<WorkoutPlanScreen> {
  String sex = 'male';
  String level = 'intermediate';
  String equipment = 'gym';
  int daysPerWeek = 4;

  bool loading = false;
  Map<String, dynamic>? response;

  bool _initialized = false;

  void _initializeFromProfile() {
    if (_initialized) return;

    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      setState(() {
        sex = profile.sex;
        level = profile.level;
        equipment = profile.equipment;
        daysPerWeek = profile.trainingDaysPerWeek;
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(primeRepoProvider);

    // Initialize from profile on first build
    _initializeFromProfile();

    final ok = response?['ok'] == true;
    final template =
        ok ? Map<String, dynamic>.from(response!['template'] as Map) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Workout Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Generate your workout plan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Based on your experience and equipment',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            // Sex + Level
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: sex,
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (v) => setState(() => sex = v ?? 'male'),
                    decoration: const InputDecoration(labelText: 'Sex'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: level,
                    items: const [
                      DropdownMenuItem(
                        value: 'beginner',
                        child: Text('Beginner'),
                      ),
                      DropdownMenuItem(
                        value: 'intermediate',
                        child: Text('Intermediate'),
                      ),
                      DropdownMenuItem(
                        value: 'advanced',
                        child: Text('Advanced'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => level = v ?? 'intermediate'),
                    decoration: const InputDecoration(labelText: 'Level'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Equipment
            DropdownButtonFormField<String>(
              value: equipment,
              items: const [
                DropdownMenuItem(value: 'gym', child: Text('Full Gym')),
                DropdownMenuItem(
                  value: 'home_dumbbells',
                  child: Text('Home (Dumbbells)'),
                ),
                DropdownMenuItem(
                  value: 'calisthenics',
                  child: Text('Bodyweight Only'),
                ),
              ],
              onChanged: (v) => setState(() => equipment = v ?? 'gym'),
              decoration: const InputDecoration(labelText: 'Equipment'),
            ),

            const SizedBox(height: 12),

            // Days
            DropdownButtonFormField<int>(
              value: daysPerWeek,
              items: const [
                DropdownMenuItem(value: 3, child: Text('3 days/week')),
                DropdownMenuItem(value: 4, child: Text('4 days/week')),
                DropdownMenuItem(value: 5, child: Text('5 days/week')),
                DropdownMenuItem(value: 6, child: Text('6 days/week')),
              ],
              onChanged: (v) => setState(() => daysPerWeek = v ?? 4),
              decoration: const InputDecoration(labelText: 'Training Days'),
            ),

            const SizedBox(height: 24),

            // Generate / Save
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : () async {
                            setState(() {
                              loading = true;
                              response = null;
                            });

                            try {
                              final res = await repo.generateWorkoutTemplate(
                                sex: sex,
                                level: level,
                                equipment: equipment,
                                daysPerWeek: daysPerWeek,
                                sessionDurationMin: 60,
                                constraints: 'none',
                              );
                              setState(() => response = res);
                            } finally {
                              setState(() => loading = false);
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(loading ? 'Generating...' : 'Generate'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: (loading || !(response?['ok'] == true))
                        ? null
                        : () async {
                            await repo.saveWorkoutTemplateFromResponse(
                              response: response!,
                              sex: sex,
                            );

                            ref.invalidate(latestWorkoutTemplateProvider);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Workout plan saved ✅'),
                                ),
                              );
                            }
                          },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Save'),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Preview
            Expanded(
              child: Builder(
                builder: (_) {
                  if (response == null) {
                    return const Center(
                      child: Text('Generate a plan to preview it.'),
                    );
                  }

                  if (response!['ok'] != true) {
                    return SingleChildScrollView(
                      child: Text(
                        (response!['raw'] ?? '').toString(),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    );
                  }

                  final rawDays = template?['days'];
                  if (rawDays is! List) {
                    return const Center(
                      child: Text('Unexpected response: days is missing.'),
                    );
                  }

                  final days = rawDays
                      .map((d) => Map<String, dynamic>.from(d as Map))
                      .toList();

                  return ListView.builder(
                    itemCount: days.length,
                    itemBuilder: (context, i) {
                      final day = days[i];
                      final title = day['title']?.toString() ?? 'Day ${i + 1}';

                      final rawExercises = day['exercises'];
                      if (rawExercises is! List) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              '$title\n\nUnexpected response: exercises missing.',
                            ),
                          ),
                        );
                      }

                      final exercises = rawExercises
                          .map((e) => Map<String, dynamic>.from(e as Map))
                          .toList();

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              ...exercises.map((ex) {
                                final name =
                                    ex['name']?.toString() ?? 'Exercise';
                                final sets = ex['workingSets'] ?? '?';

                                final repMapRaw = ex['repRange'];
                                int? repMin;
                                int? repMax;

                                if (repMapRaw is Map) {
                                  final repMap =
                                      Map<String, dynamic>.from(repMapRaw);
                                  final minVal = repMap['min'];
                                  final maxVal = repMap['max'];

                                  if (minVal is num) repMin = minVal.toInt();
                                  if (maxVal is num) repMax = maxVal.toInt();
                                }

                                final repText =
                                    (repMin != null && repMax != null)
                                        ? '$repMin–$repMax'
                                        : '?';

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text('• $name — $sets x $repText'),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}