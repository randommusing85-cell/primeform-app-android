import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/checkin.dart';
import '../models/prime_plan.dart';
import '../state/providers.dart';
import '../widgets/ai_coach_card.dart';

class MyPlanScreen extends ConsumerStatefulWidget {
  const MyPlanScreen({super.key});

  @override
  ConsumerState<MyPlanScreen> createState() => _MyPlanScreenState();
}

class _MyPlanScreenState extends ConsumerState<MyPlanScreen> {
  bool coachLoading = false;
  Map<String, dynamic>? adjustment;
  String? coachError;

  num _n(dynamic v, num fallback) =>
      v is num ? v : num.tryParse(v?.toString() ?? '') ?? fallback;

  bool _canAskCoach(PrimePlan plan) {
    final now = DateTime.now();
    final daysSince = now.difference(plan.createdAt).inDays;
    return daysSince >= 7;
  }

  int _daysUntilCoach(PrimePlan plan) {
    final now = DateTime.now();
    final daysSince = now.difference(plan.createdAt).inDays;
    final remaining = 7 - daysSince;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> _askCoach({
    required PrimePlan plan,
    required List<CheckIn> checkIns,
  }) async {
    setState(() {
      coachLoading = true;
      adjustment = null;
      coachError = null;
    });

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'generateAdjustment',
      );

      final res = await callable.call({
        "plan": {
          "plan_name": plan.planName,
          "calories": plan.calories,
          "stepTarget": plan.stepTarget,
          "macros": {
            "protein_g": plan.proteinG,
            "carbs_g": plan.carbsG,
            "fat_g": plan.fatG,
          },
          "training_days": plan.trainingDays,
          "goal": "cut",
        },
        "trends": buildTrendPayload(checkIns),
      });

      final data = Map<String, dynamic>.from(res.data as Map);

      if (data["ok"] == true) {
        setState(() {
          adjustment = Map<String, dynamic>.from(
            data["adjustment"] as Map? ?? {},
          );
        });
      } else {
        setState(() {
          coachError = (data["raw"] ?? "Unknown error").toString();
        });
      }
    } catch (e) {
      setState(() => coachError = "Error: $e");
    } finally {
      if (mounted) setState(() => coachLoading = false);
    }
  }

  Future<void> _applyAdjustment({
    required PrimePlan current,
    required Map<String, dynamic> adj,
  }) async {
    final action = (adj["action"] ?? "hold").toString();
    if (action != "adjust") {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI says: hold steady (nothing to apply).'),
        ),
      );
      return;
    }

    final calorieDelta = _n(adj["calorie_delta"], 0).round();
    final stepDelta = _n(adj["step_delta"], 0).round();

    final newCalories = (current.calories + calorieDelta).clamp(1200, 4500);
    final newStepTarget = (current.stepTarget + stepDelta).clamp(0, 50000);

    // Keep protein/fat stable, push calorie delta mostly into carbs (simple + safe)
    final deltaCarbs = (calorieDelta / 4).round();
    final newCarbs = (current.carbsG + deltaCarbs).clamp(0, 9999);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apply adjustment?'),
        content: Text(
          'This will save a NEW plan version.\n\n'
          'Calories: ${current.calories} → $newCalories '
          '(${calorieDelta >= 0 ? "+" : ""}$calorieDelta)\n'
          'Carbs: ${current.carbsG} g → $newCarbs g\n'
          'Step target: ${current.stepTarget} → $newStepTarget '
          '(${stepDelta >= 0 ? "+" : ""}$stepDelta)\n',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final updated = PrimePlan()
      ..createdAt = DateTime.now()
      ..planName = '${current.planName} (Adjusted)'
      ..trainingDays = current.trainingDays
      ..calories = newCalories
      ..proteinG = current.proteinG
      ..carbsG = newCarbs
      ..fatG = current.fatG
      ..stepTarget = newStepTarget;

    final repo = ref.read(primeRepoProvider);
    await repo.upsertPlan(updated);
    ref.invalidate(activePlanProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Plan updated ✅')));

    setState(() {
      adjustment = null;
      coachError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(activePlanProvider);
    final checkInsAsync = ref.watch(latestCheckInsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (plan) {
            if (plan == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'No plan saved yet',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Create a plan first, then it will show up here.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pushNamed(context, '/plan'),
                    child: const Text('Create Plan'),
                  ),
                ],
              );
            }

            final checkIns = checkInsAsync.value ?? <CheckIn>[];

            final canCoach = _canAskCoach(plan);
            final daysLeft = _daysUntilCoach(plan);
            final lockText = canCoach
                ? null
                : 'Coach check-in locked. Try again in $daysLeft day${daysLeft == 1 ? "" : "s"}.';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Active Plan', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Saved on: ${plan.createdAt}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),

                Text(plan.planName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Training days: ${plan.trainingDays}/week'),
                const SizedBox(height: 8),
                Text('Step target: ${plan.stepTarget}/day'),
                const SizedBox(height: 16),

                _StatCard(title: 'Calories', value: '${plan.calories} kcal'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Protein',
                        value: '${plan.proteinG} g',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Carbs',
                        value: '${plan.carbsG} g',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(title: 'Fat', value: '${plan.fatG} g'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                AiCoachCard(
                  loading: coachLoading,
                  errorText: coachError,
                  adjustment: adjustment,
                  currentCalories: plan.calories,
                  currentStepTarget: plan.stepTarget,
                  locked: !canCoach,
                  lockText: lockText,
                  onAsk: () => _askCoach(plan: plan, checkIns: checkIns),
                  onReask: () => _askCoach(plan: plan, checkIns: checkIns),
                  onApply: adjustment == null
                      ? null
                      : () => _applyAdjustment(current: plan, adj: adjustment!),
                ),

                const Spacer(),

                FilledButton.tonal(
                  onPressed: () => Navigator.pushNamed(context, '/plan'),
                  child: const Text('Regenerate / Update Plan'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Compact payload: last 14 check-ins → last7 vs prev7 averages.
/// Keeps AI stable + cheap, avoids sending raw logs.
Map<String, dynamic> buildTrendPayload(List<CheckIn> items) {
  final last14 = items.take(14).toList();
  final last7 = last14.take(7).toList();
  final prev7 = last14.skip(7).take(7).toList();

  double avg(Iterable<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

  return {
    "counts": {
      "last14": last14.length,
      "last7": last7.length,
      "prev7": prev7.length,
    },
    "weight": {
      "last7_avg": avg(last7.map((c) => c.weightKg)),
      "prev7_avg": avg(prev7.map((c) => c.weightKg)),
    },
    "waist": {
      "last7_avg": avg(last7.map((c) => c.waistCm)),
      "prev7_avg": avg(prev7.map((c) => c.waistCm)),
    },
    "steps": {
      "last7_avg": avg(last7.map((c) => c.stepsToday.toDouble())),
      "prev7_avg": avg(prev7.map((c) => c.stepsToday.toDouble())),
    },
  };
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}
