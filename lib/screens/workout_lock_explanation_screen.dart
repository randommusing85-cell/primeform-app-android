import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows when user tries to regenerate a workout before the lock period ends
class WorkoutLockExplanationScreen extends ConsumerWidget {
  final DateTime createdAt;
  final int lockDays;

  const WorkoutLockExplanationScreen({
    super.key,
    required this.createdAt,
    this.lockDays = 14,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final daysSince = now.difference(createdAt).inDays;
    final remaining = lockDays - daysSince;
    return remaining < 0 ? 0 : remaining;
  }

  bool get canRegenerate => daysRemaining <= 0;

  DateTime get unlockDate => createdAt.add(Duration(days: lockDays));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Icon(
              Icons.lock_clock,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              canRegenerate
                  ? 'Ready to Update Your Plan'
                  : 'Your Plan is Locked',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            if (!canRegenerate) ...[
              // Locked State
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Unlocks in $daysRemaining ${daysRemaining == 1 ? "day" : "days"}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Available on ${_formatDate(unlockDate)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Philosophy Explanation
              Text(
                'Why consistency matters',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _PhilosophyPoint(
                icon: Icons.trending_up,
                title: 'Progress takes time',
                description:
                    'Real strength gains show up in weeks 2-4. Switching programs early resets your progress.',
              ),
              const SizedBox(height: 16),

              _PhilosophyPoint(
                icon: Icons.repeat,
                title: 'Habits compound',
                description:
                    'Doing the same workout consistently builds muscle memory and confidence faster than trying new programs.',
              ),
              const SizedBox(height: 16),

              _PhilosophyPoint(
                icon: Icons.psychology,
                title: 'Decision fatigue is real',
                description:
                    'Removing the option to change plans frees mental energy for what matters: showing up and training hard.',
              ),
              const SizedBox(height: 32),

              // Quote/Reminder
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 32,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The best program is the one you actually follow.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trust the process. Give it time.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Unlocked State
              Text(
                'You have stuck with your plan for $lockDays days. Well done.',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You can now update your workout parameters if needed. But remember: switching too often prevents progress.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),

            // Actions
            if (canRegenerate) ...[
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Allow regeneration
                },
                child: const Text('Update My Plan'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Keep Current Plan'),
              ),
            ] else ...[
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Got It'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _PhilosophyPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PhilosophyPoint({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
