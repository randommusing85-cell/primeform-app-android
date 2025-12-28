import 'package:flutter/material.dart';

class AiCoachCard extends StatelessWidget {
  final bool loading;
  final String? errorText;
  final Map<String, dynamic>? adjustment;

  final int currentCalories;
  final int currentStepTarget;

  final VoidCallback onAsk;
  final VoidCallback onReask;
  final VoidCallback? onApply;

  final bool locked;
  final String? lockText;

  const AiCoachCard({
    super.key,
    required this.loading,
    required this.errorText,
    required this.adjustment,
    required this.currentCalories,
    required this.currentStepTarget,
    required this.onAsk,
    required this.onReask,
    required this.onApply,
    this.locked = false,
    this.lockText,
  });

  num _n(dynamic v, num fallback) =>
      v is num ? v : num.tryParse(v?.toString() ?? '') ?? fallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adj = adjustment;

    final action = adj == null ? '' : (adj["action"] ?? "").toString();
    final confidence = adj == null ? '' : (adj["confidence"] ?? "").toString();
    final calorieDelta = adj == null ? 0 : _n(adj["calorie_delta"], 0).round();
    final stepDelta = adj == null ? 0 : _n(adj["step_delta"], 0).round();

    final afterCalories = (currentCalories + calorieDelta).clamp(1200, 4500);
    final afterSteps = (currentStepTarget + stepDelta).clamp(0, 50000);

    final reasons = adj == null
        ? const <String>[]
        : List<String>.from(
            (adj["reasoning"] as List?)?.map((e) => e.toString()) ?? const [],
          );

    final isBusy = loading || locked;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('AI Coach', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),

          if (locked && lockText != null) ...[
            Text(lockText!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
          ],

          if (errorText != null) ...[
            Text(errorText!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
          ],

          if (adj == null) ...[
            FilledButton(
              onPressed: isBusy ? null : onAsk,
              child: Text(loading ? 'Thinking…' : 'Ask AI Coach'),
            ),
          ] else ...[
            Text(
              'Action: $action${confidence.isEmpty ? "" : " • confidence: $confidence"}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),

            Text(
              'Calories: $currentCalories → $afterCalories '
              '(${calorieDelta >= 0 ? "+" : ""}$calorieDelta)',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'Step target: $currentStepTarget → $afterSteps '
              '(${stepDelta >= 0 ? "+" : ""}$stepDelta)',
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: 8),

            if (reasons.isNotEmpty) ...[
              Text('Why:', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              ...reasons.take(4).map((r) => Text('• $r')),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: locked ? null : onApply,
                    child: const Text('Apply'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : onReask,
                    child: const Text('Re-ask'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
