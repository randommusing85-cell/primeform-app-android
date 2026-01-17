import 'package:flutter/material.dart';

/// Predefined injury/limitation options
class InjuryOption {
  final String id;
  final String label;
  final String description;
  final IconData icon;

  const InjuryOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const List<InjuryOption> injuryOptions = [
  InjuryOption(
    id: 'lower_back',
    label: 'Lower Back',
    description: 'Avoid heavy deadlifts, good mornings',
    icon: Icons.airline_seat_legroom_reduced,
  ),
  InjuryOption(
    id: 'upper_back',
    label: 'Upper Back',
    description: 'Modify rows and pull movements',
    icon: Icons.accessibility_new,
  ),
  InjuryOption(
    id: 'shoulder_left',
    label: 'Left Shoulder',
    description: 'Limit overhead pressing',
    icon: Icons.pan_tool,
  ),
  InjuryOption(
    id: 'shoulder_right',
    label: 'Right Shoulder',
    description: 'Limit overhead pressing',
    icon: Icons.pan_tool,
  ),
  InjuryOption(
    id: 'knee_left',
    label: 'Left Knee',
    description: 'Avoid deep squats, jumping',
    icon: Icons.directions_walk,
  ),
  InjuryOption(
    id: 'knee_right',
    label: 'Right Knee',
    description: 'Avoid deep squats, jumping',
    icon: Icons.directions_walk,
  ),
  InjuryOption(
    id: 'wrist',
    label: 'Wrist',
    description: 'Use straps, avoid heavy gripping',
    icon: Icons.front_hand,
  ),
  InjuryOption(
    id: 'elbow',
    label: 'Elbow',
    description: 'Modify pressing and curling movements',
    icon: Icons.sports_martial_arts,
  ),
  InjuryOption(
    id: 'hip',
    label: 'Hip',
    description: 'Limit hip hinge movements',
    icon: Icons.accessibility,
  ),
  InjuryOption(
    id: 'ankle',
    label: 'Ankle',
    description: 'Avoid impact, modify stance',
    icon: Icons.do_not_step,
  ),
  InjuryOption(
    id: 'neck',
    label: 'Neck',
    description: 'Avoid loaded positions',
    icon: Icons.person,
  ),
  InjuryOption(
    id: 'other',
    label: 'Other',
    description: 'Specify in notes',
    icon: Icons.more_horiz,
  ),
];

/// Widget for selecting injuries/limitations
class InjurySelector extends StatelessWidget {
  final List<String> selectedInjuries;
  final ValueChanged<List<String>> onChanged;
  final String? notes;
  final ValueChanged<String?>? onNotesChanged;

  const InjurySelector({
    super.key,
    required this.selectedInjuries,
    required this.onChanged,
    this.notes,
    this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Any injuries or limitations?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select all that apply. We\'ll generate safer workout alternatives.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Injury chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: injuryOptions.map((option) {
            final isSelected = selectedInjuries.contains(option.id);
            return FilterChip(
              label: Text(option.label),
              avatar: Icon(
                option.icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              selected: isSelected,
              onSelected: (selected) {
                final updated = List<String>.from(selectedInjuries);
                if (selected) {
                  updated.add(option.id);
                } else {
                  updated.remove(option.id);
                }
                onChanged(updated);
              },
            );
          }).toList(),
        ),

        // Notes field if "other" is selected or if any injury is selected
        if (selectedInjuries.isNotEmpty && onNotesChanged != null) ...[
          const SizedBox(height: 16),
          TextFormField(
            initialValue: notes,
            decoration: const InputDecoration(
              labelText: 'Additional notes (optional)',
              hintText: 'e.g., "Left knee is recovering from surgery 3 months ago"',
              helperText: 'This helps the AI generate safer exercises',
            ),
            maxLines: 2,
            onChanged: onNotesChanged,
          ),
        ],

        // Info box
        if (selectedInjuries.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your workout plan will avoid exercises that could aggravate these areas and suggest safer alternatives.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact injury display for settings/profile view
class InjuryDisplay extends StatelessWidget {
  final List<String> injuries;
  final String? notes;
  final VoidCallback? onEdit;

  const InjuryDisplay({
    super.key,
    required this.injuries,
    this.notes,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (injuries.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.health_and_safety),
        title: const Text('Injuries / Limitations'),
        subtitle: const Text('None specified'),
        trailing: onEdit != null
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: onEdit,
      );
    }

    final injuryLabels = injuries.map((id) {
      final option = injuryOptions.firstWhere(
        (o) => o.id == id,
        orElse: () => InjuryOption(
          id: id,
          label: id.replaceAll('_', ' '),
          description: '',
          icon: Icons.warning,
        ),
      );
      return option.label;
    }).toList();

    return ListTile(
      leading: Icon(
        Icons.health_and_safety,
        color: theme.colorScheme.error,
      ),
      title: const Text('Injuries / Limitations'),
      subtitle: Text(
        injuryLabels.join(', '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: onEdit != null
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
      onTap: onEdit,
    );
  }
}