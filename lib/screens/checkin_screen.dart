import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/checkin.dart';
import '../state/providers.dart';
import '../services/analytics_service.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();

  final _weightCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _stepsCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    _stepsCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  num? _tryNum(String s) => num.tryParse(s.trim());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final c = CheckIn()
        ..ts = DateTime.now()
        ..weightKg = (_tryNum(_weightCtrl.text) ?? 0).toDouble()
        ..waistCm = (_tryNum(_waistCtrl.text) ?? 0).toDouble()
        ..stepsToday = int.parse(_stepsCtrl.text.trim())
        ..note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

      final repo = ref.read(primeRepoProvider);
      await repo.addCheckIn(c);

      // Track analytics
      final analytics = ref.read(analyticsProvider);
      await analytics.logCheckInCompleted(
        weightKg: c.weightKg,
        waistCm: c.waistCm,
        stepsToday: c.stepsToday,
        hasNote: c.note != null,
      );

      // refresh stream consumers
      ref.invalidate(latestCheckInsStreamProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Check-in saved ✅')));

      _weightCtrl.clear();
      _waistCtrl.clear();
      _stepsCtrl.clear();
      _noteCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Check-in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Log today', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),

              TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'e.g. 75.2',
                ),
                validator: (v) {
                  final n = _tryNum(v ?? '');
                  if (n == null) return 'Enter a number';
                  if (n < 30 || n > 250) return 'Enter a realistic weight';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _waistCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Waist (cm)',
                  hintText: 'e.g. 80',
                ),
                validator: (v) {
                  final n = _tryNum(v ?? '');
                  if (n == null) return 'Enter a number';
                  if (n < 40 || n > 200) return 'Enter a realistic waist';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _stepsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Steps today',
                  hintText: 'e.g. 8000',
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null) return 'Enter a whole number';
                  if (n < 0 || n > 100000)
                    return 'Enter a realistic step count';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Energy, hunger, mood, training…',
                ),
              ),

              const SizedBox(height: 20),

              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save Check-in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}