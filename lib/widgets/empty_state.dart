import 'package:flutter/material.dart';

/// A reusable empty state widget for when there's no data to display.
/// Provides consistent styling across the app with an icon, title,
/// description, and optional action button.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  /// Empty state for no workout plan
  factory EmptyState.noWorkoutPlan({
    required VoidCallback onCreate,
  }) {
    return EmptyState(
      icon: Icons.fitness_center,
      title: 'No Workout Plan Yet',
      description: 'Create a personalized workout plan to start training.',
      actionLabel: 'Create Workout Plan',
      onAction: onCreate,
    );
  }

  /// Empty state for no nutrition plan
  factory EmptyState.noNutritionPlan({
    required VoidCallback onCreate,
  }) {
    return EmptyState(
      icon: Icons.restaurant_menu,
      title: 'No Nutrition Plan Yet',
      description: 'Generate a personalized nutrition plan based on your goals.',
      actionLabel: 'Create Nutrition Plan',
      onAction: onCreate,
    );
  }

  /// Empty state for no meals logged today
  factory EmptyState.noMeals({
    VoidCallback? onAdd,
  }) {
    return EmptyState(
      icon: Icons.restaurant,
      title: 'No Meals Logged Today',
      description: 'Track your nutrition by logging your meals.',
      actionLabel: onAdd != null ? 'Log Meal' : null,
      onAction: onAdd,
    );
  }

  /// Empty state for no check-ins
  factory EmptyState.noCheckIns({
    VoidCallback? onCheckIn,
  }) {
    return EmptyState(
      icon: Icons.analytics_outlined,
      title: 'No Check-ins Yet',
      description: 'Start tracking your progress with daily check-ins.',
      actionLabel: onCheckIn != null ? 'Check In' : null,
      onAction: onCheckIn,
    );
  }

  /// Empty state for no workout history
  factory EmptyState.noWorkoutHistory() {
    return const EmptyState(
      icon: Icons.history,
      title: 'No Workout History',
      description: 'Complete workouts to see your history here.',
    );
  }

  /// Empty state for no trends data
  factory EmptyState.noTrendsData() {
    return const EmptyState(
      icon: Icons.trending_up,
      title: 'Not Enough Data',
      description: 'Log more check-ins and meals to see your trends.',
    );
  }

  /// Empty state for search with no results
  factory EmptyState.noSearchResults({String? query}) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      description: query != null
          ? 'No results for "$query". Try a different search.'
          : 'Try adjusting your search terms.',
    );
  }

  /// Empty state for error
  factory EmptyState.error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something Went Wrong',
      description: message ?? 'An error occurred. Please try again.',
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }

  /// Empty state for offline
  factory EmptyState.offline({
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.cloud_off,
      title: 'You\'re Offline',
      description: 'Check your internet connection and try again.',
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor =
        iconColor ?? theme.colorScheme.primary.withOpacity(0.5);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                icon,
                size: 40,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact version of the empty state for use in cards or smaller areas
class EmptyStateCompact extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const EmptyStateCompact({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              size: 24,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: content,
        ),
      );
    }

    return Card(child: content);
  }
}
