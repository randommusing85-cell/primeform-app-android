import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../models/checkin.dart';
import '../services/analytics_service.dart';

class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInsAsync = ref.watch(latestCheckInsStreamProvider);
    final theme = Theme.of(context);
    
    // Track analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = AnalyticsService();
      analytics.logTrendsViewed();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Trends')),
      body: checkInsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No check-ins yet.'));
          }

          final last7 = items.take(7).toList();
          final prev7 = items.skip(7).take(7).toList();

          final avgWeight7 = _avg(last7.map((c) => c.weightKg));
          final avgWaist7 = _avg(last7.map((c) => c.waistCm));
          final avgSteps7 = _avg(last7.map((c) => c.stepsToday.toDouble()));

          final avgWeightPrev = _avg(prev7.map((c) => c.weightKg));
          final avgWaistPrev = _avg(prev7.map((c) => c.waistCm));
          final avgStepsPrev = _avg(prev7.map((c) => c.stepsToday.toDouble()));

          final dWeight = avgWeight7 - avgWeightPrev;
          final dWaist = avgWaist7 - avgWaistPrev;
          final dSteps = avgSteps7 - avgStepsPrev;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Last 7 days', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _TrendCard(
                      title: 'Weight',
                      value: '${avgWeight7.toStringAsFixed(1)} kg',
                      trend: _trend(now: avgWeight7, prev: avgWeightPrev),
                      subtitle: _deltaText(
                        delta: dWeight,
                        unit: 'kg',
                        decimals: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TrendCard(
                      title: 'Waist',
                      value: '${avgWaist7.toStringAsFixed(1)} cm',
                      trend: _trend(
                        now: avgWaist7,
                        prev: avgWaistPrev,
                        lowerIsBetter: true,
                      ),
                      subtitle: _deltaText(
                        delta: dWaist,
                        unit: 'cm',
                        decimals: 1,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _TrendCard(
                title: 'Steps',
                value: avgSteps7.toStringAsFixed(0),
                trend: _trend(
                  now: avgSteps7,
                  prev: avgStepsPrev,
                  higherIsBetter: true,
                ),
                subtitle: _deltaText(delta: dSteps, unit: '', decimals: 0),
              ),

              const SizedBox(height: 24),
              Text('Recent check-ins', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),

              ...items.map(
                (c) => Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${c.weightKg.toStringAsFixed(1)} kg • ${c.waistCm.toStringAsFixed(1)} cm',
                      ),
                      subtitle: Text(
                        '${_fmtDate(c.ts)} • steps: ${c.stepsToday}'
                        '${c.note == null ? "" : " • ${c.note}"}',
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static double _avg(Iterable<double> xs) {
    if (xs.isEmpty) return 0;
    return xs.reduce((a, b) => a + b) / xs.length;
  }

  static String _deltaText({
    required double delta,
    required String unit,
    int decimals = 1,
  }) {
    if (delta.abs() < 0.05) return 'No change vs last week';

    final sign = delta > 0 ? '+' : '−';
    final v = delta.abs().toStringAsFixed(decimals);
    return '$sign$v $unit vs last week';
  }

  static String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.year}';
  }

  static Trend _trend({
    required double now,
    required double prev,
    bool lowerIsBetter = false,
    bool higherIsBetter = false,
  }) {
    if (prev == 0) return Trend.neutral;

    final diff = now - prev;
    if (diff.abs() < 0.05) return Trend.neutral;

    if (lowerIsBetter) return diff < 0 ? Trend.good : Trend.bad;
    if (higherIsBetter) return diff > 0 ? Trend.good : Trend.bad;

    return diff < 0 ? Trend.good : Trend.bad;
  }
}

enum Trend { good, neutral, bad }

class _TrendCard extends StatelessWidget {
  final String title;
  final String value;
  final Trend trend;
  final String subtitle;

  const _TrendCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    String label;

    switch (trend) {
      case Trend.good:
        icon = Icons.arrow_downward;
        color = Colors.green;
        label = 'Improving';
        break;
      case Trend.bad:
        icon = Icons.arrow_upward;
        color = Colors.red;
        label = 'Drifting';
        break;
      default:
        icon = Icons.remove;
        color = theme.colorScheme.outline;
        label = 'Stable';
    }

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
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}