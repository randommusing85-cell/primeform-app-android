import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../state/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ageCtrl = TextEditingController(text: '30');
  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '70');

  String _sex = 'male';
  String _goal = 'cut';
  String _level = 'beginner';
  String _equipment = 'gym';
  int _trainingDays = 4;

  bool _saving = false;

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final profile = UserProfile()
        ..age = int.parse(_ageCtrl.text.trim())
        ..sex = _sex
        ..heightCm = int.parse(_heightCtrl.text.trim())
        ..weightKg = double.parse(_weightCtrl.text.trim())
        ..goal = _goal
        ..level = _level
        ..equipment = _equipment
        ..trainingDaysPerWeek = _trainingDays
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final repo = ref.read(userProfileRepoProvider);
      await repo.saveProfile(profile);

      // Refresh the profile provider
      ref.invalidate(userProfileProvider);

      if (!mounted) return;

      // Navigate to home and remove onboarding from stack
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to PrimeForm'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Let\'s set up your profile',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'This helps us create a personalized plan for you.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Basic Info Section
              Text('Basic Information', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: 'e.g. 30',
                ),
                validator: (v) {
                  final age = int.tryParse(v ?? '');
                  if (age == null) return 'Enter a valid age';
                  if (age < 15 || age > 100) return 'Age must be 15-100';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _sex,
                decoration: const InputDecoration(labelText: 'Sex'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _sex = v ?? 'male'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _heightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  hintText: 'e.g. 170',
                ),
                validator: (v) {
                  final height = int.tryParse(v ?? '');
                  if (height == null) return 'Enter a valid height';
                  if (height < 120 || height > 250) {
                    return 'Height must be 120-250 cm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'e.g. 70',
                ),
                validator: (v) {
                  final weight = double.tryParse(v ?? '');
                  if (weight == null) return 'Enter a valid weight';
                  if (weight < 30 || weight > 300) {
                    return 'Weight must be 30-300 kg';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Fitness Goals Section
              Text('Fitness Goals', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _goal,
                decoration: const InputDecoration(
                  labelText: 'Primary Goal',
                  helperText: 'What do you want to achieve?',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'cut',
                    child: Text('Fat Loss (Cut)'),
                  ),
                  DropdownMenuItem(
                    value: 'recomp',
                    child: Text('Body Recomposition'),
                  ),
                  DropdownMenuItem(
                    value: 'bulk',
                    child: Text('Muscle Gain (Bulk)'),
                  ),
                ],
                onChanged: (v) => setState(() => _goal = v ?? 'cut'),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _level,
                decoration: const InputDecoration(
                  labelText: 'Training Experience',
                  helperText: 'How familiar are you with working out?',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'beginner',
                    child: Text('Beginner (0-1 years)'),
                  ),
                  DropdownMenuItem(
                    value: 'intermediate',
                    child: Text('Intermediate (1-3 years)'),
                  ),
                  DropdownMenuItem(
                    value: 'advanced',
                    child: Text('Advanced (3+ years)'),
                  ),
                ],
                onChanged: (v) => setState(() => _level = v ?? 'beginner'),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _equipment,
                decoration: const InputDecoration(
                  labelText: 'Equipment Access',
                  helperText: 'What equipment do you have?',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'gym',
                    child: Text('Full Gym'),
                  ),
                  DropdownMenuItem(
                    value: 'home_dumbbells',
                    child: Text('Home (Dumbbells)'),
                  ),
                  DropdownMenuItem(
                    value: 'calisthenics',
                    child: Text('Bodyweight Only'),
                  ),
                ],
                onChanged: (v) => setState(() => _equipment = v ?? 'gym'),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _trainingDays,
                decoration: const InputDecoration(
                  labelText: 'Training Days per Week',
                  helperText: 'How many days can you train?',
                ),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 days')),
                  DropdownMenuItem(value: 4, child: Text('4 days')),
                  DropdownMenuItem(value: 5, child: Text('5 days')),
                  DropdownMenuItem(value: 6, child: Text('6 days')),
                ],
                onChanged: (v) => setState(() => _trainingDays = v ?? 4),
              ),

              const SizedBox(height: 32),

              FilledButton(
                onPressed: _saving ? null : _saveProfile,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _saving ? 'Setting up...' : 'Get Started',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}