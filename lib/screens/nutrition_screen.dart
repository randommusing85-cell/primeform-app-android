import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal_log.dart';
import '../state/providers.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planAsync = ref.watch(activePlanProvider);
    final mealsAsync = ref.watch(todayMealsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
      ),
      body: Column(
        children: [
          // Daily Summary Card (always visible at top)
          planAsync.when(
            data: (plan) => mealsAsync.when(
              data: (meals) => _DailySummaryCard(
                plan: plan,
                meals: meals,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Divider(),

          // Meal Log List
          Expanded(
            child: mealsAsync.when(
              data: (meals) => _MealLogList(meals: meals),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMealDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Meal'),
      ),
    );
  }

  Future<void> _showAddMealDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => const _AddMealDialog(),
    );
  }
}

// Daily Summary Card showing progress toward targets
class _DailySummaryCard extends StatelessWidget {
  final dynamic plan;
  final List<MealLog> meals;

  const _DailySummaryCard({
    required this.plan,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate today's totals
    final totalProtein = meals.fold<int>(0, (sum, m) => sum + m.proteinG);
    final totalCarbs = meals.fold<int>(0, (sum, m) => sum + m.carbsG);
    final totalFat = meals.fold<int>(0, (sum, m) => sum + m.fatG);
    final totalCals = (totalProtein * 4) + (totalCarbs * 4) + (totalFat * 9);

    if (plan == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Column(
          children: [
            Text(
              'No nutrition plan yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/plan'),
              child: const Text('Create Plan'),
            ),
          ],
        ),
      );
    }

    final targetCals = plan.calories;
    final targetProtein = plan.proteinG;
    final targetCarbs = plan.carbsG;
    final targetFat = plan.fatG;

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Progress',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$totalCals / $targetCals kcal',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MacroProgressBar(
            label: 'Protein',
            current: totalProtein,
            target: targetProtein,
            color: Colors.red,
          ),
          const SizedBox(height: 8),
          _MacroProgressBar(
            label: 'Carbs',
            current: totalCarbs,
            target: targetCarbs,
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          _MacroProgressBar(
            label: 'Fat',
            current: totalFat,
            target: targetFat,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

class _MacroProgressBar extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;

  const _MacroProgressBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            '$current / ${target}g',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// Meal Log List
class _MealLogList extends StatelessWidget {
  final List<MealLog> meals;

  const _MealLogList({required this.meals});

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No meals logged today',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to log your first meal',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    // Group by meal type
    final breakfast = meals.where((m) => m.mealType == 'breakfast').toList();
    final lunch = meals.where((m) => m.mealType == 'lunch').toList();
    final dinner = meals.where((m) => m.mealType == 'dinner').toList();
    final snacks = meals.where((m) => m.mealType == 'snack').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (breakfast.isNotEmpty) _MealSection('Breakfast', breakfast),
        if (lunch.isNotEmpty) _MealSection('Lunch', lunch),
        if (dinner.isNotEmpty) _MealSection('Dinner', dinner),
        if (snacks.isNotEmpty) _MealSection('Snacks', snacks),
      ],
    );
  }
}

class _MealSection extends StatelessWidget {
  final String title;
  final List<MealLog> meals;

  const _MealSection(this.title, this.meals);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalProtein = meals.fold<int>(0, (sum, m) => sum + m.proteinG);
    final totalCarbs = meals.fold<int>(0, (sum, m) => sum + m.carbsG);
    final totalFat = meals.fold<int>(0, (sum, m) => sum + m.fatG);
    final totalCals = (totalProtein * 4) + (totalCarbs * 4) + (totalFat * 9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _getMealIcon(title),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${totalCals} kcal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...meals.map((meal) => _MealCard(meal: meal)),
        const SizedBox(height: 16),
      ],
    );
  }

  Icon _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return const Icon(Icons.free_breakfast, size: 20);
      case 'lunch':
        return const Icon(Icons.lunch_dining, size: 20);
      case 'dinner':
        return const Icon(Icons.dinner_dining, size: 20);
      default:
        return const Icon(Icons.fastfood, size: 20);
    }
  }
}

class _MealCard extends ConsumerWidget {
  final MealLog meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          meal.description ?? 'Meal',
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: Text(
          'P: ${meal.proteinG}g  C: ${meal.carbsG}g  F: ${meal.fatG}g',
          style: theme.textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete meal?'),
                content: const Text('This cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              final repo = ref.read(primeRepoProvider);
              await repo.deleteMealLog(meal.id);
              ref.invalidate(todayMealsStreamProvider);
            }
          },
        ),
      ),
    );
  }
}

// Add Meal Dialog
class _AddMealDialog extends ConsumerStatefulWidget {
  const _AddMealDialog();

  @override
  ConsumerState<_AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends ConsumerState<_AddMealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  String _mealType = 'breakfast';

  @override
  void dispose() {
    _descCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  int? _tryInt(String s) => int.tryParse(s.trim());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final meal = MealLog()
      ..ts = DateTime.now()
      ..mealType = _mealType
      ..proteinG = int.parse(_proteinCtrl.text.trim())
      ..carbsG = int.parse(_carbsCtrl.text.trim())
      ..fatG = int.parse(_fatCtrl.text.trim())
      ..description = _descCtrl.text.trim().isEmpty 
          ? null 
          : _descCtrl.text.trim();

    final repo = ref.read(primeRepoProvider);
    await repo.addMealLog(meal);
    ref.invalidate(todayMealsStreamProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal logged ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Log Meal'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _mealType,
                decoration: const InputDecoration(labelText: 'Meal Type'),
                items: const [
                  DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                  DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                  DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                  DropdownMenuItem(value: 'snack', child: Text('Snack')),
                ],
                onChanged: (v) => setState(() => _mealType = v ?? 'breakfast'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'e.g. Chicken rice',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Protein (g)',
                      ),
                      validator: (v) {
                        final n = _tryInt(v ?? '');
                        if (n == null) return 'Required';
                        if (n < 0 || n > 300) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Carbs (g)',
                      ),
                      validator: (v) {
                        final n = _tryInt(v ?? '');
                        if (n == null) return 'Required';
                        if (n < 0 || n > 500) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fatCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Fat (g)',
                      ),
                      validator: (v) {
                        final n = _tryInt(v ?? '');
                        if (n == null) return 'Required';
                        if (n < 0 || n > 200) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
