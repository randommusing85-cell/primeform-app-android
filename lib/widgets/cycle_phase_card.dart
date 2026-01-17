import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/cycle_calculator.dart';
import '../state/providers.dart';

/// Displays current cycle phase with user-friendly language and education
class CyclePhaseCard extends ConsumerWidget {
  const CyclePhaseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        // Don't show if no profile or not tracking cycle
        if (profile == null || !profile.trackCycle) {
          return const SizedBox.shrink();
        }

        final phase = CycleCalculator.getCurrentPhase(profile);
        if (phase == null) {
          return const SizedBox.shrink();
        }

        final cycleDay = CycleCalculator.getCurrentCycleDay(profile);
        final guidance = CycleCalculator.getShortGuidance(phase);
        
        // Get user-friendly info
        final phaseInfo = _getPhaseInfo(phase);
        
        // Get phase color
        Color phaseColor;
        switch (phase) {
          case CyclePhase.menstrual:
            phaseColor = Colors.pink.shade300;
            break;
          case CyclePhase.follicular:
            phaseColor = Colors.green.shade400;
            break;
          case CyclePhase.ovulation:
            phaseColor = Colors.amber.shade400;
            break;
          case CyclePhase.luteal:
            phaseColor = Colors.orange.shade400;
            break;
        }

        return Card(
          color: phaseColor.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      phaseInfo.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            phaseInfo.friendlyName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (cycleDay != null)
                            Text(
                              'Day $cycleDay of ${profile.cycleLength}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      onPressed: () => _showPhaseEducation(context, phase, phaseInfo),
                      tooltip: 'Learn about this phase',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  guidance,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  _PhaseInfo _getPhaseInfo(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return _PhaseInfo(
          emoji: '🌙',
          friendlyName: 'Period Week',
          technicalName: 'Menstrual Phase',
          weekNumber: 'Week 1',
          dayRange: 'Days 1-5',
          whatHappens: 'Your uterus sheds its lining, which is your period. Hormone levels (estrogen and progesterone) are at their lowest.',
          howYouFeel: 'You might feel tired, crampy, or low energy. Some women feel relieved when their period starts. It\'s normal to want more rest.',
          trainingTips: [
            '• Focus on gentle movement like walking or yoga',
            '• Lighter weights are totally fine',
            '• Rest more between sets if needed',
            '• Skip the gym if you need to - rest is productive',
          ],
          whyItMatters: 'Low energy this week is NORMAL. Your body is literally working hard internally. Don\'t feel guilty about taking it easier.',
        );

      case CyclePhase.follicular:
        return _PhaseInfo(
          emoji: '🌱',
          friendlyName: 'Building Phase',
          technicalName: 'Follicular Phase',
          weekNumber: 'Week 2',
          dayRange: 'Days 6-14',
          whatHappens: 'Your body is preparing to release an egg. Estrogen rises steadily, which helps build muscle and improves mood.',
          howYouFeel: 'Energy increases! You might feel stronger, more motivated, and happier. This is often women\'s favorite week.',
          trainingTips: [
            '• Great time to increase weights',
            '• Try for personal records',
            '• Your body recovers faster',
            '• Push yourself - you can handle it',
          ],
          whyItMatters: 'This is your "power week" - take advantage! Your hormones are literally helping you build muscle.',
        );

      case CyclePhase.ovulation:
        return _PhaseInfo(
          emoji: '⭐',
          friendlyName: 'Peak Week',
          technicalName: 'Ovulation Phase',
          weekNumber: 'Week 2-3',
          dayRange: 'Days 14-16',
          whatHappens: 'Your body releases an egg. Estrogen peaks, and testosterone also rises slightly.',
          howYouFeel: 'This is typically your STRONGEST point. Maximum energy, confidence, and strength. You might feel invincible!',
          trainingTips: [
            '• Peak strength window - test your limits',
            '• Great time for challenging workouts',
            '• You can handle higher intensity',
            '• Enjoy feeling your best!',
          ],
          whyItMatters: 'Only a few days, but they\'re gold! This is when your body is optimized for performance.',
        );

      case CyclePhase.luteal:
        return _PhaseInfo(
          emoji: '🍂',
          friendlyName: 'Winding Down Phase',
          technicalName: 'Luteal Phase',
          weekNumber: 'Week 3-4',
          dayRange: 'Days 17-28',
          whatHappens: 'After ovulation, progesterone rises to prepare for potential pregnancy. If no pregnancy, both hormones drop before your period.',
          howYouFeel: 'Energy gradually decreases. You might feel more tired, hungrier, moodier, or bloated. This is PMS week(s).',
          trainingTips: [
            '• Maintain your routine but don\'t push for PRs',
            '• Focus on good form over heavy weights',
            '• Extra rest is smart, not weak',
            '• Be kind to yourself',
          ],
          whyItMatters: 'Lower energy is NOT laziness - it\'s biology. Maintaining your routine this week IS an accomplishment.',
        );
    }
  }

  void _showPhaseEducation(BuildContext context, CyclePhase phase, _PhaseInfo info) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(info.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.friendlyName),
                  Text(
                    '${info.technicalName} • ${info.dayRange}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(theme, 'What\'s Happening', info.whatHappens),
              const SizedBox(height: 16),
              _buildSection(theme, 'How You Might Feel', info.howYouFeel),
              const SizedBox(height: 16),
              _buildSection(theme, 'Training Tips', null),
              const SizedBox(height: 8),
              ...info.trainingTips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(tip, style: const TextStyle(height: 1.4)),
              )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, 
                             size: 20, 
                             color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Why This Matters',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      info.whyItMatters,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String? content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (content != null) ...[
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(height: 1.4)),
        ],
      ],
    );
  }
}

class _PhaseInfo {
  final String emoji;
  final String friendlyName;
  final String technicalName;
  final String weekNumber;
  final String dayRange;
  final String whatHappens;
  final String howYouFeel;
  final List<String> trainingTips;
  final String whyItMatters;

  _PhaseInfo({
    required this.emoji,
    required this.friendlyName,
    required this.technicalName,
    required this.weekNumber,
    required this.dayRange,
    required this.whatHappens,
    required this.howYouFeel,
    required this.trainingTips,
    required this.whyItMatters,
  });
}