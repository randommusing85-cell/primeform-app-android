import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final workoutDocAsync = ref.watch(latestWorkoutTemplateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PrimeForm')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome back', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Plan your week, log your check-ins, and track trends — offline-first.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // PLAN
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/plan'),
              child: const Text('Create Plan'),
            ),
            const SizedBox(height: 12),

            FilledButton.tonal(
              onPressed: () => Navigator.pushNamed(context, '/myplan'),
              child: const Text('My Plan'),
            ),
            const SizedBox(height: 12),

            // WORKOUT
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/workout'),
              child: const Text('Create Workout Plan'),
            ),
            const SizedBox(height: 12),

            FilledButton(
              onPressed: () {
                // Smart route:
                // - If workout plan exists -> Today's Workout
                // - Else -> Create Workout Plan
                final doc = workoutDocAsync.value;
                if (doc == null) {
                  Navigator.pushNamed(context, '/workout');
                } else {
                  Navigator.pushNamed(context, '/today-workout');
                }
              },
              child: const Text("Today's Workout"),
            ),
            const SizedBox(height: 12),

            FilledButton.tonal(
              onPressed: () => Navigator.pushNamed(context, '/my-workout'),
              child: const Text('My Workout Plan'),
            ),
            const SizedBox(height: 12),

            // TRACK
            FilledButton.tonal(
              onPressed: () => Navigator.pushNamed(context, '/checkin'),
              child: const Text('Daily Check-in'),
            ),
            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/trends'),
              child: const Text('Trends'),
            ),

            const Spacer(),

            // Optional: small status hint (non-blocking)
            workoutDocAsync.when(
              data: (doc) => Text(
                doc == null
                    ? 'No workout plan saved yet.'
                    : 'Workout plan ready: ${doc.planName}',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              loading: () => Text(
                'Loading...',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              error: (e, _) => Text(
                'Could not load workout plan.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
