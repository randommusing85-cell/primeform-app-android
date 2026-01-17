import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../widgets/weekly_progress_card.dart';
import '../widgets/cycle_phase_card.dart';
import '../widgets/postpartum_status_card.dart';
import '../widgets/macro_adherence_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final workoutTemplateAsync = ref.watch(latestWorkoutTemplateProvider);
    final checkInsAsync = ref.watch(latestCheckInsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PrimeForm'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting Section
            profileAsync.when(
              data: (profile) {
                if (profile == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Let\'s stay consistent today',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // Weekly Progress Indicator
            const WeeklyProgressCard(),
            const SizedBox(height: 16),

            // Post-Partum Status (only shows if post-partum)
            const PostPartumStatusCard(),

            // Cycle Phase (only shows if tracking cycles)
            const CyclePhaseCard(),

            const SizedBox(height: 16),

            // 1. TODAY'S WORKOUT CARD
            _TodayWorkoutCard(workoutTemplateAsync: workoutTemplateAsync),

            const SizedBox(height: 16),

            // 2. DAILY CHECK-IN CARD
            _DailyCheckInCard(checkInsAsync: checkInsAsync),

            const SizedBox(height: 16),

            // 3. MACRO ADHERENCE CARD
            const MacroAdherenceCard(),

            const SizedBox(height: 16),

            // 4. QUICK STATS CARD
            _QuickStatsCard(checkInsAsync: checkInsAsync),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// 1. TODAY'S WORKOUT CARD
class _TodayWorkoutCard extends StatelessWidget {
  final AsyncValue<dynamic> workoutTemplateAsync;

  const _TodayWorkoutCard({required this.workoutTemplateAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      child: InkWell(
        onTap: () {
          final hasTemplate = workoutTemplateAsync.value != null;
          if (hasTemplate) {
            Navigator.pushNamed(context, '/today-workout');
          } else {
            Navigator.pushNamed(context, '/workout');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Today\'s Workout',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              workoutTemplateAsync.when(
                data: (template) {
                  if (template == null) {
                    return Text(
                      'Create your first workout plan',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    );
                  }
                  return Text(
                    'Ready to train | Tap to start',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => Text(
                  'Unable to load workout',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. DAILY CHECK-IN CARD
class _DailyCheckInCard extends StatelessWidget {
  final AsyncValue<List<dynamic>> checkInsAsync;

  const _DailyCheckInCard({required this.checkInsAsync});

  bool _hasCheckedInToday(List<dynamic> checkIns) {
    if (checkIns.isEmpty) return false;

    final latest = checkIns.first;
    final now = DateTime.now();
    final latestDate = latest.ts as DateTime;

    return latestDate.year == now.year &&
        latestDate.month == now.month &&
        latestDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return checkInsAsync.when(
      data: (checkIns) {
        final hasCheckedIn = _hasCheckedInToday(checkIns);

        return Card(
          elevation: 0,
          color: hasCheckedIn
              ? theme.colorScheme.tertiaryContainer
              : theme.colorScheme.secondaryContainer,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/checkin'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    hasCheckedIn ? Icons.check_circle : Icons.edit_note,
                    color: hasCheckedIn
                        ? theme.colorScheme.onTertiaryContainer
                        : theme.colorScheme.onSecondaryContainer,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasCheckedIn ? 'Check-in Complete' : 'Daily Check-in',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: hasCheckedIn
                                ? theme.colorScheme.onTertiaryContainer
                                : theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasCheckedIn
                              ? 'Logged today'
                              : 'Log weight, waist, steps',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasCheckedIn
                                ? theme.colorScheme.onTertiaryContainer
                                : theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: hasCheckedIn
                        ? theme.colorScheme.onTertiaryContainer
                        : theme.colorScheme.onSecondaryContainer,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// 3. QUICK STATS CARD
class _QuickStatsCard extends StatelessWidget {
  final AsyncValue<List<dynamic>> checkInsAsync;

  const _QuickStatsCard({required this.checkInsAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return checkInsAsync.when(
      data: (checkIns) {
        if (checkIns.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete your first check-in to see trends',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final latest = checkIns.first;
        final weight = (latest.weightKg as double).toStringAsFixed(1);
        final waist = (latest.waistCm as double).toStringAsFixed(1);

        // Calculate trend if we have multiple check-ins
        String? trendText;
        if (checkIns.length >= 2) {
          final previous = checkIns[1];
          final weightDelta = latest.weightKg - previous.weightKg;
          if (weightDelta.abs() > 0.1) {
            final sign = weightDelta > 0 ? '+' : '';
            trendText = '$sign${weightDelta.toStringAsFixed(1)} kg from last';
          }
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest Stats',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Weight',
                        value: '$weight kg',
                        icon: Icons.monitor_weight_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatItem(
                        label: 'Waist',
                        value: '$waist cm',
                        icon: Icons.straighten,
                      ),
                    ),
                  ],
                ),
                if (trendText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    trendText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}