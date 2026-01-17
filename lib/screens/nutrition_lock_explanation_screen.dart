import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows when user tries to regenerate nutrition plan before 14-day lock expires
class NutritionLockExplanationScreen extends ConsumerWidget {
  final DateTime createdAt;
  final int lockDays;

  const NutritionLockExplanationScreen({
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
        title: const Text('Nutrition Plan'),
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
                'Why your plan is locked',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _PhilosophyPoint(
                icon: Icons.science,
                title: 'Your body needs time to adapt',
                description:
                    'Real metabolic changes take 2-4 weeks to show. Changing your plan too soon means you\'re chasing noise, not progress.',
              ),
              const SizedBox(height: 16),

              _PhilosophyPoint(
                icon: Icons.trending_up,
                title: 'Consistency beats optimization',
                description:
                    'A "good enough" plan followed consistently beats a "perfect" plan that keeps changing.',
              ),
              const SizedBox(height: 16),

              _PhilosophyPoint(
                icon: Icons.psychology,
                title: 'Trust the process',
                description:
                    'We protect you from the urge to constantly tweak and adjust. Let your current plan do its work.',
              ),
              const SizedBox(height: 32),

              // AI Coach Reminder
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.smart_toy,
                      color: theme.colorScheme.secondary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need adjustments?',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Use the AI Coach in My Plan screen to make data-driven adjustments based on your progress.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quote
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
                      'The best nutrition plan is the one you actually follow for weeks, not days.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Unlocked State
              Text(
                'You\'ve stuck with your plan for $lockDays days. Well done.',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You can now regenerate your nutrition plan if needed. But remember: if your current plan is working, keep it.',
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
