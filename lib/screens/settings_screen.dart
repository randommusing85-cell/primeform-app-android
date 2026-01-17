import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found'));
          }

          return ListView(
            children: [
              // Medical Disclaimer Section (Prominent at top)
              _buildMedicalDisclaimer(context, theme, profile),

              const SizedBox(height: 16),

              // Profile Section
              _buildSectionHeader(theme, 'Profile'),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Age'),
                trailing: Text('${profile.age} years'),
              ),
              ListTile(
                leading: const Icon(Icons.wc),
                title: const Text('Sex'),
                trailing: Text(profile.sex == 'male' ? 'Male' : 'Female'),
              ),
              ListTile(
                leading: const Icon(Icons.height),
                title: const Text('Height'),
                trailing: Text('${profile.heightCm} cm'),
              ),
              ListTile(
                leading: const Icon(Icons.monitor_weight),
                title: const Text('Weight'),
                trailing: Text('${profile.weightKg.toStringAsFixed(1)} kg'),
              ),

              const Divider(),

              // Women's Health Section (if applicable)
              if (profile.sex == 'female') ...[
                _buildSectionHeader(theme, 'Women\'s Health'),

                if (profile.trackCycle) ...[
                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: const Text('Cycle Tracking'),
                    subtitle: const Text('Enabled'),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_calendar),
                    title: const Text('Cycle Length'),
                    trailing: Text('${profile.cycleLength} days'),
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: const Text('Cycle Tracking'),
                    subtitle: const Text('Disabled'),
                    trailing: const Icon(Icons.cancel, color: Colors.grey),
                  ),
                ],

                if (profile.postPartumStatus != 'no') ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.child_care),
                    title: const Text('Post-Partum Status'),
                    subtitle: Text(_getPostPartumStatusText(profile.postPartumStatus)),
                    trailing: profile.medicalClearance
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.warning, color: Colors.orange),
                  ),
                  if (profile.deliveryDate != null)
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Delivery Date'),
                      trailing: Text(
                        '${profile.deliveryDate!.day}/${profile.deliveryDate!.month}/${profile.deliveryDate!.year}',
                      ),
                    ),
                  if (profile.checkDiastasis)
                    ListTile(
                      leading: const Icon(Icons.healing),
                      title: const Text('Diastasis Recti Guidance'),
                      subtitle: const Text('Enabled'),
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                    ),
                ],

                const Divider(),
              ],

              // Training Preferences
              _buildSectionHeader(theme, 'Training'),
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Goal'),
                trailing: Text(_getGoalText(profile.goal)),
              ),
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text('Experience Level'),
                trailing: Text(_getLevelText(profile.level)),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Training Days'),
                trailing: Text('${profile.trainingDaysPerWeek} days/week'),
              ),

              const Divider(),

              // Support Section
              _buildSectionHeader(theme, 'Support'),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & FAQ'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showHelpDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.feedback_outlined),
                title: const Text('Send Feedback'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showFeedbackDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About PrimeForm'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showAboutDialog(context),
              ),

              const Divider(),

              // Legal Section
              _buildSectionHeader(theme, 'Legal'),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showTermsDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showPrivacyDialog(context),
              ),

              const SizedBox(height: 32),

              // Version Info
              Center(
                child: Text(
                  'PrimeForm v1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMedicalDisclaimer(
    BuildContext context,
    ThemeData theme,
    profile,
  ) {
    // Show disclaimer for all users, but especially important for women
    final isWoman = profile.sex == 'female';
    final isPostPartum = profile.postPartumStatus != 'no';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.health_and_safety,
                color: Colors.orange.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Medical Disclaimer',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'PrimeForm provides fitness guidance, NOT medical advice.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Always consult your healthcare provider:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 8),
          ...[
            if (isPostPartum) '• Before starting post-partum exercise',
            '• Before starting any new exercise program',
            if (isWoman) '• If you experience leaking or pelvic pressure',
            if (isWoman) '• If you have any pelvic floor concerns',
            '• If you experience pain (not just soreness)',
            '• If you have any pre-existing medical conditions',
            if (isPostPartum) '• If symptoms persist or worsen',
          ].map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade900,
                  ),
                ),
              )),
          const SizedBox(height: 12),
          if (isWoman) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'For specialized women\'s health concerns, consult a pelvic floor physical therapist.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'PrimeForm is not a substitute for professional medical advice, diagnosis, or treatment.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showFullDisclaimerDialog(context),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Read Full Disclaimer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade900,
              side: BorderSide(color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getPostPartumStatusText(String status) {
    switch (status) {
      case 'early':
        return 'Early Recovery (0-12 weeks)';
      case 'mid':
        return 'Rebuilding (3-6 months)';
      case 'late':
        return 'Strengthening (6-18 months)';
      default:
        return 'Not Post-Partum';
    }
  }

  String _getGoalText(String goal) {
    switch (goal) {
      case 'cut':
        return 'Fat Loss';
      case 'recomp':
        return 'Recomposition';
      case 'bulk':
        return 'Muscle Gain';
      default:
        return goal;
    }
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

  void _showFullDisclaimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Full Medical Disclaimer'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IMPORTANT: READ CAREFULLY',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'PrimeForm ("the App") provides fitness and wellness information for educational and informational purposes only. The content provided through the App, including but not limited to workout programs, nutrition guidance, and health recommendations, is NOT intended to be a substitute for professional medical advice, diagnosis, or treatment.',
              ),
              SizedBox(height: 12),
              Text(
                'ALWAYS SEEK MEDICAL ADVICE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You should always consult with your physician or other qualified healthcare provider before starting any exercise program, especially if you:',
              ),
              SizedBox(height: 8),
              Text('• Are pregnant or post-partum'),
              Text('• Have any pre-existing medical conditions'),
              Text('• Are taking any medications'),
              Text('• Have any injuries or physical limitations'),
              Text('• Experience any pain or discomfort'),
              SizedBox(height: 12),
              Text(
                'POST-PARTUM SPECIFIC',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Post-partum exercise guidance provided by the App is general information only. Medical clearance from your healthcare provider is required before beginning any post-partum exercise program. If you experience any unusual symptoms including but not limited to leaking, pelvic pressure, pain, or bleeding, stop exercising immediately and consult your healthcare provider.',
              ),
              SizedBox(height: 12),
              Text(
                'WOMEN\'S HEALTH',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Menstrual cycle tracking and related guidance is provided for informational purposes. This information should not be used for contraceptive purposes or as a substitute for medical care. Consult a pelvic floor physical therapist for specialized concerns.',
              ),
              SizedBox(height: 12),
              Text(
                'NO MEDICAL RELATIONSHIP',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Use of the App does not create a doctor-patient or healthcare provider-patient relationship. The App is not intended to diagnose, treat, cure, or prevent any disease or medical condition.',
              ),
              SizedBox(height: 12),
              Text(
                'ASSUMPTION OF RISK',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Exercise involves inherent risks. By using the App, you acknowledge and assume all risks associated with exercise and physical activity.',
              ),
              SizedBox(height: 12),
              Text(
                'EMERGENCY',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'If you experience a medical emergency, call emergency services immediately. Do not rely on the App for emergency medical assistance.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Common Questions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Q: Why is my plan locked for 14 days?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'A: Consistency is key to progress. The 14-day lock helps you stick with your plan long enough to see real results, rather than constantly switching programs.',
              ),
              SizedBox(height: 12),
              Text(
                'Q: When can I adjust my plan?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'A: Use the AI Coach feature (available after 7 days) to make data-driven adjustments based on your progress.',
              ),
              SizedBox(height: 12),
              Text(
                'Q: Is this safe for post-partum?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'A: Yes, but ONLY after medical clearance (6+ weeks for vaginal birth, 8+ for C-section). The app provides guidelines, but always follow your doctor\'s advice.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('We\'d love to hear from you!'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts, suggestions, or report issues...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement feedback submission
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feedback!'),
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About PrimeForm'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PrimeForm v1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'The smart fitness app that understands women\'s bodies.',
              ),
              SizedBox(height: 12),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• Cycle-aware training adjustments'),
              Text('• Post-partum safe progression'),
              Text('• AI coaching with context'),
              Text('• 14-day plan lock for consistency'),
              Text('• Singapore local food context'),
              SizedBox(height: 12),
              Text(
                'Built with science, designed for real bodies.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service content would go here...\n\n'
            'This is a placeholder. You should add your actual Terms of Service.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy content would go here...\n\n'
            'This is a placeholder. You should add your actual Privacy Policy.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
