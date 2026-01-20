import 'package:flutter/material.dart';

/// Widget for selecting specific days of the week for workouts
class WorkoutDayScheduler extends StatelessWidget {
  final List<int> selectedDays; // 1 = Monday, 7 = Sunday
  final ValueChanged<List<int>> onChanged;
  final int maxDays;

  const WorkoutDayScheduler({
    super.key,
    required this.selectedDays,
    required this.onChanged,
    required this.maxDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Training Days',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${selectedDays.length}/$maxDays selected',
              style: theme.textTheme.bodySmall?.copyWith(
                color: selectedDays.length == maxDays
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Text(
          'Select which days you want to train',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Day selector buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDayButton(context, 1, 'Mon'),
            _buildDayButton(context, 2, 'Tue'),
            _buildDayButton(context, 3, 'Wed'),
            _buildDayButton(context, 4, 'Thu'),
            _buildDayButton(context, 5, 'Fri'),
            _buildDayButton(context, 6, 'Sat'),
            _buildDayButton(context, 7, 'Sun'),
          ],
        ),

        if (selectedDays.length < maxDays) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select ${maxDays - selectedDays.length} more day${maxDays - selectedDays.length == 1 ? "" : "s"}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (selectedDays.length == maxDays) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Perfect! Your ${_getScheduleSummary()} training schedule is set.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade900,
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

  Widget _buildDayButton(BuildContext context, int day, String label) {
    final theme = Theme.of(context);
    final isSelected = selectedDays.contains(day);
    final canSelect = selectedDays.length < maxDays || isSelected;

    return SizedBox(
      width: 48,
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: canSelect
            ? (selected) {
                final updated = List<int>.from(selectedDays);
                if (selected) {
                  updated.add(day);
                  updated.sort();
                } else {
                  updated.remove(day);
                }
                onChanged(updated);
              }
            : null,
        selectedColor: theme.colorScheme.primaryContainer,
        checkmarkColor: theme.colorScheme.primary,
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }

  String _getScheduleSummary() {
    final days = selectedDays.map((d) => _getDayName(d, short: true)).toList();
    if (days.length <= 2) {
      return days.join(' & ');
    } else if (days.length == 3) {
      return '${days[0]}, ${days[1]} & ${days[2]}';
    } else {
      return '${days[0]}, ${days[1]}, ${days[2]}+';
    }
  }

  String _getDayName(int day, {bool short = false}) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const fullNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return short ? names[day - 1] : fullNames[day - 1];
  }
}

/// Display selected workout days in a compact format
class WorkoutDayDisplay extends StatelessWidget {
  final List<int> selectedDays;
  final VoidCallback? onEdit;

  const WorkoutDayDisplay({
    super.key,
    required this.selectedDays,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedDays.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('Training Schedule'),
        subtitle: const Text('Not configured'),
        trailing: onEdit != null
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: onEdit,
      );
    }

    final dayNames = selectedDays.map((d) => _getDayName(d, short: true)).join(', ');

    return ListTile(
      leading: Icon(
        Icons.calendar_today,
        color: theme.colorScheme.primary,
      ),
      title: const Text('Training Schedule'),
      subtitle: Text(dayNames),
      trailing: onEdit != null
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
      onTap: onEdit,
    );
  }

  String _getDayName(int day, {bool short = false}) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const fullNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return short ? names[day - 1] : fullNames[day - 1];
  }
}
