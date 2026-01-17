import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../widgets/injury_selector.dart';

class InjurySettingsScreen extends ConsumerStatefulWidget {
  const InjurySettingsScreen({super.key});

  @override
  ConsumerState<InjurySettingsScreen> createState() => _InjurySettingsScreenState();
}

class _InjurySettingsScreenState extends ConsumerState<InjurySettingsScreen> {
  List<String> _selectedInjuries = [];
  String? _injuryNotes;
  bool _saving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final profile = ref.read(userProfileProvider).value;
      if (profile != null) {
        setState(() {
          _selectedInjuries = profile.injuryList;
          _injuryNotes = profile.injuryNotes;
          _initialized = true;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final repo = ref.read(userProfileRepoProvider);
      final profile = await repo.getProfile();
      
      if (profile != null) {
        profile.injuryList = _selectedInjuries;
        profile.injuryNotes = _injuryNotes;
        profile.updatedAt = DateTime.now();
        
        await repo.saveProfile(profile);
        ref.invalidate(userProfileProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Injuries updated ✅')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Injuries & Limitations'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Train Smart',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'When you regenerate your workout plan, our AI will avoid exercises that could aggravate your injuries and suggest safer alternatives.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            InjurySelector(
              selectedInjuries: _selectedInjuries,
              onChanged: (injuries) {
                setState(() => _selectedInjuries = injuries);
              },
              notes: _injuryNotes,
              onNotesChanged: (notes) {
                setState(() => _injuryNotes = notes);
              },
            ),

            const SizedBox(height: 32),

            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is not medical advice. Always consult a healthcare professional for injuries.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_saving ? 'Saving...' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}