import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../models/prime_plan.dart';
import '../models/workout_template_doc.dart';

/// Unified Plans tab showing both Nutrition and Workout plans
class PlansTabScreen extends ConsumerWidget {
  const PlansTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Plans'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Philosophy reminder at top
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Plans are locked for 14 days to build consistency. Trust the process.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Nutrition Plan Section
          const _NutritionPlanSection(),

          const SizedBox(height: 32),

          const Divider(),

          const SizedBox(height: 32),

          // Workout Plan Section
          const _WorkoutPlanSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ===== NUTRITION PLAN SECTION =====
class _NutritionPlanSection extends ConsumerWidget {
  const _NutritionPlanSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final planAsync = ref.watch(activePlanProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.restaurant_menu,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Nutrition Plan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (plan) {
            if (plan == null) {
              return Column(
                children: [
                  Text(
                    'No nutrition plan yet',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first plan to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/plan'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Nutrition Plan'),
                  ),
                ],
              );
            }

            return _NutritionPlanContent(plan: plan);
          },
        ),
      ],
    );
  }
}

class _NutritionPlanContent extends ConsumerWidget {
  final PrimePlan plan;

  const _NutritionPlanContent({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final daysSinceCreation = DateTime.now().difference(plan.createdAt).inDays;
    final canRegenerate = daysSinceCreation >= 14;
    final daysRemaining = canRegenerate ? 0 : 14 - daysSinceCreation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Plan summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.planName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!canRegenerate)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_clock,
                              size: 14,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${daysRemaining}d',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Calories (prominent)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${plan.calories} kcal',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        ' / day',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Macros row
                Row(
                  children: [
                    Expanded(
                      child: _MacroChip(
                        label: 'Protein',
                        value: '${plan.proteinG}g',
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MacroChip(
                        label: 'Carbs',
                        value: '${plan.carbsG}g',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MacroChip(
                        label: 'Fat',
                        value: '${plan.fatG}g',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Steps
                Row(
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${plan.stepTarget} steps/day',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${plan.trainingDays} training days/week',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/myplan'),
                icon: const Icon(Icons.smart_toy, size: 18),
                label: const Text('AI Coach'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/nutrition'),
                icon: const Icon(Icons.restaurant, size: 18),
                label: const Text('Log Meals'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        FilledButton.tonal(
          onPressed: () => Navigator.pushNamed(context, '/plan'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!canRegenerate) const Icon(Icons.lock_outline, size: 18),
              if (!canRegenerate) const SizedBox(width: 8),
              Text(
                canRegenerate
                    ? 'Regenerate Plan'
                    : 'Regenerate (${daysRemaining}d lock)',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== WORKOUT PLAN SECTION =====
class _WorkoutPlanSection extends ConsumerWidget {
  const _WorkoutPlanSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final templateAsync = ref.watch(latestWorkoutTemplateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.fitness_center,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Workout Plan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        templateAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (template) {
            if (template == null) {
              return Column(
                children: [
                  Text(
                    'No workout plan yet',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first plan to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/workout'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Workout Plan'),
                  ),
                ],
              );
            }

            return _WorkoutPlanContent(template: template);
          },
        ),
      ],
    );
  }
}

class _WorkoutPlanContent extends StatelessWidget {
  final WorkoutTemplateDoc template;

  const _WorkoutPlanContent({required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final daysSinceCreation =
        DateTime.now().difference(template.createdAt).inDays;
    final canRegenerate = daysSinceCreation >= 14;
    final daysRemaining = canRegenerate ? 0 : 14 - daysSinceCreation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Plan summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        template.planName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!canRegenerate)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_clock,
                              size: 14,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${daysRemaining}d',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${template.daysPerWeek} days per week',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getLevelText(template.level),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.handyman,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getEquipmentText(template.equipment),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action buttons
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/my-workout'),
          icon: const Icon(Icons.list, size: 18),
          label: const Text('View Full Plan'),
        ),

        const SizedBox(height: 12),

        FilledButton.tonal(
          onPressed: () => Navigator.pushNamed(context, '/workout'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!canRegenerate) const Icon(Icons.lock_outline, size: 18),
              if (!canRegenerate) const SizedBox(width: 8),
              Text(
                canRegenerate
                    ? 'Regenerate Plan'
                    : 'Regenerate (${daysRemaining}d lock)',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getLevelText(String level) {
    switch (level) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return level;
    }
  }

  String _getEquipmentText(String equipment) {
    switch (equipment) {
      case 'gym':
        return 'Full Gym';
      case 'home_dumbbells':
        return 'Home (Dumbbells)';
      case 'calisthenics':
        return 'Bodyweight Only';
      default:
        return equipment;
    }
  }
}