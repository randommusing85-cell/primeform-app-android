import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/postpartum_calculator.dart';
import '../state/providers.dart';

/// Displays post-partum status and safe training guidance
/// Shows only for women who indicated they are post-partum
class PostPartumStatusCard extends ConsumerWidget {
  const PostPartumStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        // Don't show if no profile or not post-partum
        if (profile == null || profile.postPartumStatus == 'no') {
          return const SizedBox.shrink();
        }

        final phase = PostPartumCalculator.getPhase(profile);
        if (phase == PostPartumPhase.none) {
          return const SizedBox.shrink();
        }

        final weeks = PostPartumCalculator.getWeeksPostPartum(profile);
        final phaseName = PostPartumCalculator.getPhaseName(phase);
        final phaseEmoji = PostPartumCalculator.getPhaseEmoji(phase);
        final guidance = PostPartumCalculator.getShortGuidance(phase);
        final isReady = PostPartumCalculator.isReadyToStart(profile);

        // Get phase color
        Color phaseColor;
        switch (phase) {
          case PostPartumPhase.earlyRecovery:
            phaseColor = Colors.purple.shade200;
            break;
          case PostPartumPhase.rebuilding:
            phaseColor = Colors.green.shade200;
            break;
          case PostPartumPhase.strengthening:
            phaseColor = Colors.blue.shade200;
            break;
          default:
            phaseColor = Colors.grey.shade200;
        }

        return Column(
          children: [
            Card(
              color: phaseColor.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          phaseEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Post-Partum: $phaseName',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (weeks != null)
                                Text(
                                  '$weeks weeks post-delivery',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, size: 20),
                          onPressed: () => _showDetailedInfo(context, phase),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      guidance,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    
                    // Medical clearance warning if not cleared
                    if (!isReady) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              size: 20,
                              color: Colors.orange.shade900,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                !profile.medicalClearance
                                    ? 'Get medical clearance before exercising'
                                    : 'Too early to start (min ${profile.deliveryType == "cesarean" ? "8" : "6"} weeks)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Red flag warnings
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 18,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Stop if: leaking, pressure, doming, or pain',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showRedFlags(context),
                            child: const Text(
                              'Details',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showDetailedInfo(BuildContext context, PostPartumPhase phase) {
    final theme = Theme.of(context);
    final phaseName = PostPartumCalculator.getPhaseName(phase);
    final guidance = PostPartumCalculator.getDetailedGuidance(phase);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$phaseName Phase'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(guidance),
              const SizedBox(height: 16),
              Text(
                'Important:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Every body is different. Listen to yours. When in doubt, consult your healthcare provider or a pelvic floor physical therapist.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showRedFlags(BuildContext context) {
    final theme = Theme.of(context);
    final redFlags = PostPartumCalculator.getRedFlags();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Stop Exercise If:'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...redFlags.map((flag) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(flag),
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
                    Text(
                      'When to See a Specialist:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If you experience any of these symptoms, consult a pelvic floor physical therapist. They specialize in post-partum recovery.',
                      style: TextStyle(fontSize: 13),
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
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
