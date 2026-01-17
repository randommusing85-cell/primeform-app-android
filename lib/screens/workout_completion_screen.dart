import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutCompletionScreen extends ConsumerWidget {
  final int dayIndex;
  final int totalDays;
  final int completedExercises;
  final int totalExercises;
  final String workoutTitle;

  const WorkoutCompletionScreen({
    super.key,
    required this.dayIndex,
    required this.totalDays,
    required this.completedExercises,
    required this.totalExercises,
    required this.workoutTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLastDay = dayIndex >= totalDays;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Success Icon
              Icon(
                Icons.check_circle,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Main Message
              Text(
                isLastDay ? 'Week Complete! 🎉' : 'Day $dayIndex Complete! 💪',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                workoutTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Stats Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Exercises completed',
                      value: '$completedExercises / $totalExercises',
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'Progress this week',
                      value: '$dayIndex / $totalDays days',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Consistency Message (Habit Reinforcement)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isLastDay
                            ? 'Consistency builds strength. Same plan, next week.'
                            : 'Small actions compound. See you next session.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              if (isLastDay) ...[
                FilledButton.icon(
                  onPressed: () {
                    // Go back home - new week starts fresh
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                ),
              ] else ...[
                FilledButton(
                  onPressed: () {
                    // Navigate back to Today's Workout (will show next day)
                    Navigator.of(context).pop();
                  },
                  child: Text('Continue to Day ${dayIndex + 1}'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Back to Home'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
