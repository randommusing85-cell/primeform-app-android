import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

class MyWorkoutPlanScreen extends ConsumerWidget {
  const MyWorkoutPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDoc = ref.watch(latestWorkoutTemplateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Workout Plan')),
      body: asyncDoc.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (doc) {
          if (doc == null) {
            return const Center(child: Text('No workout plan saved yet.'));
          }

          final decoded = jsonDecode(doc.json);
          if (decoded is! Map) {
            return const Center(child: Text('Saved plan is corrupted.'));
          }

          final template = Map<String, dynamic>.from(decoded);

          final rawDays = template['days'];
          if (rawDays is! List) {
            return const Center(child: Text('Saved plan is missing days.'));
          }

          final days = rawDays
              .map((d) => Map<String, dynamic>.from(d as Map))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                doc.planName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${doc.sex} • ${doc.level} • ${doc.equipment} • ${doc.daysPerWeek} days/week',
              ),
              const SizedBox(height: 16),
              ...days.map((day) {
                final title = day['title']?.toString() ?? 'Day';

                final rawExercises = day['exercises'];
                if (rawExercises is! List) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('$title\n\nSaved plan is missing exercises.'),
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
                          final name = ex['name']?.toString() ?? 'Exercise';
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

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text('• $name — $sets x $repText'),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
