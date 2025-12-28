import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/prime_plan.dart';
import '../state/providers.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ageCtrl = TextEditingController(text: '40');
  final _heightCtrl = TextEditingController(text: '175');
  final _weightCtrl = TextEditingController(text: '75.2');

  String _sex = 'male'; // ✅ NEW
  String _goal = 'cut';
  int _daysPerWeek = 4;
  String _equipment = 'gym access';

  bool _loading = false;
  Map<String, dynamic>? _planJson; // holds returned JSON plan
  String? _raw; // if model returns non-JSON

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _planJson = null;
      _raw = null;
    });

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('generatePlan');

      final res = await callable.call({
        "age": int.parse(_ageCtrl.text.trim()),
        "sex": _sex, // ✅ use selected value
        "heightCm": int.parse(_heightCtrl.text.trim()),
        "weightKg": double.parse(_weightCtrl.text.trim()),
        "goal": _goal,
        "daysPerWeek": _daysPerWeek,
        "equipment": _equipment,
      });

      final data = Map<String, dynamic>.from(res.data as Map);

      if (data["ok"] == true) {
        setState(() {
          _planJson = Map<String, dynamic>.from(data["plan"] as Map);
        });
      } else {
        setState(() {
          _raw = (data["raw"] ?? "").toString();
        });
      }
    } catch (e) {
      setState(() {
        _raw = "Error: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _savePlan() async {
    final pj = _planJson;
    if (pj == null) return;

    num n(dynamic v, num fallback) =>
        v is num ? v : num.tryParse(v?.toString() ?? '') ?? fallback;

    final macros = Map<String, dynamic>.from(pj["macros"] as Map? ?? {});

    final plan = PrimePlan()
      ..createdAt = DateTime.now()
      ..planName = (pj["plan_name"] ?? "Prime Plan").toString()
      ..trainingDays = (pj["training_days"] as num?)?.round() ?? _daysPerWeek
      ..calories = n(pj["calories"], 2000).round()
      ..proteinG = n(macros["protein_g"], 160).round()
      ..carbsG = n(macros["carbs_g"], 200).round()
      ..fatG = n(macros["fat_g"], 60).round()
      ..stepTarget = n(pj["step_target"], 8000).round();

    final repo = ref.read(primeRepoProvider);
    await repo.upsertPlan(plan);
    ref.invalidate(activePlanProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Plan saved ✅')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Generate a plan with AI',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // ✅ NEW: Sex selection
                  DropdownButtonFormField<String>(
                    initialValue: _sex,
                    decoration: const InputDecoration(labelText: 'Sex'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (v) => setState(() => _sex = v ?? 'male'),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Height (cm)'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _goal,
                    decoration: const InputDecoration(labelText: 'Goal'),
                    items: const [
                      DropdownMenuItem(value: 'cut', child: Text('Cut')),
                      DropdownMenuItem(value: 'recomp', child: Text('Recomp')),
                      DropdownMenuItem(value: 'bulk', child: Text('Bulk')),
                    ],
                    onChanged: (v) => setState(() => _goal = v ?? 'cut'),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    initialValue: _daysPerWeek,
                    decoration: const InputDecoration(
                      labelText: 'Training days / week',
                    ),
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('3')),
                      DropdownMenuItem(value: 4, child: Text('4')),
                      DropdownMenuItem(value: 5, child: Text('5')),
                      DropdownMenuItem(value: 6, child: Text('6')),
                    ],
                    onChanged: (v) => setState(() => _daysPerWeek = v ?? 4),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: _equipment,
                    decoration: const InputDecoration(labelText: 'Equipment'),
                    onChanged: (v) => _equipment = v,
                  ),

                  const SizedBox(height: 16),

                  FilledButton(
                    onPressed: _loading ? null : _generatePlan,
                    child: Text(_loading ? 'Generating…' : 'Generate with AI'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_planJson != null) ...[
              Text('Preview', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(_planJson),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _savePlan,
                child: const Text('Save Plan'),
              ),
            ],

            if (_raw != null) ...[
              Text('Response', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_raw!),
            ],
          ],
        ),
      ),
    );
  }
}
