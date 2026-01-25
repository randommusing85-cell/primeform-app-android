/// Exercise alternatives database.
/// Maps common exercises to 2 alternative options that target the same muscle groups.
///
/// This allows users to swap exercises they don't know or can't perform
/// with similar alternatives that achieve the same training effect.

class ExerciseAlternatives {
  static const Map<String, List<ExerciseOption>> alternatives = {
    // Chest
    'Barbell Bench Press': [
      ExerciseOption('Dumbbell Bench Press', 'Uses dumbbells for greater range of motion'),
      ExerciseOption('Machine Chest Press', 'Guided movement, great for beginners'),
    ],
    'Dumbbell Bench Press': [
      ExerciseOption('Barbell Bench Press', 'Classic compound movement'),
      ExerciseOption('Push-Ups', 'Bodyweight alternative, can be done anywhere'),
    ],
    'Incline Bench Press': [
      ExerciseOption('Incline Dumbbell Press', 'Better stretch at bottom'),
      ExerciseOption('Low-to-High Cable Fly', 'Constant tension throughout'),
    ],
    'Incline Dumbbell Press': [
      ExerciseOption('Incline Barbell Press', 'Allows heavier loading'),
      ExerciseOption('Incline Push-Ups', 'Bodyweight alternative'),
    ],
    'Cable Fly': [
      ExerciseOption('Dumbbell Fly', 'Classic isolation movement'),
      ExerciseOption('Pec Deck Machine', 'Guided movement'),
    ],
    'Dumbbell Fly': [
      ExerciseOption('Cable Fly', 'Constant tension throughout'),
      ExerciseOption('Machine Fly', 'Easier to control'),
    ],
    'Push-Ups': [
      ExerciseOption('Knee Push-Ups', 'Easier regression'),
      ExerciseOption('Dumbbell Bench Press', 'Weighted alternative'),
    ],

    // Back
    'Barbell Row': [
      ExerciseOption('Dumbbell Row', 'Unilateral, better stretch'),
      ExerciseOption('Cable Row', 'Constant tension'),
    ],
    'Dumbbell Row': [
      ExerciseOption('Barbell Row', 'Bilateral, heavier loading'),
      ExerciseOption('Machine Row', 'Guided movement'),
    ],
    'Lat Pulldown': [
      ExerciseOption('Pull-Ups', 'Bodyweight compound movement'),
      ExerciseOption('Assisted Pull-Ups', 'Bodyweight with support'),
    ],
    'Pull-Ups': [
      ExerciseOption('Lat Pulldown', 'Adjustable resistance'),
      ExerciseOption('Assisted Pull-Ups', 'Easier progression'),
    ],
    'Seated Cable Row': [
      ExerciseOption('Chest-Supported Row', 'Reduces lower back stress'),
      ExerciseOption('T-Bar Row', 'Classic rowing movement'),
    ],
    'Deadlift': [
      ExerciseOption('Romanian Deadlift', 'More hamstring focus'),
      ExerciseOption('Trap Bar Deadlift', 'More quad involvement, easier on lower back'),
    ],
    'Romanian Deadlift': [
      ExerciseOption('Stiff-Leg Deadlift', 'Similar movement pattern'),
      ExerciseOption('Good Mornings', 'Hip hinge alternative'),
    ],

    // Shoulders
    'Overhead Press': [
      ExerciseOption('Dumbbell Shoulder Press', 'Greater range of motion'),
      ExerciseOption('Machine Shoulder Press', 'Guided movement'),
    ],
    'Dumbbell Shoulder Press': [
      ExerciseOption('Barbell Overhead Press', 'Allows heavier loading'),
      ExerciseOption('Arnold Press', 'Rotational variation'),
    ],
    'Lateral Raise': [
      ExerciseOption('Cable Lateral Raise', 'Better tension curve'),
      ExerciseOption('Machine Lateral Raise', 'Guided movement'),
    ],
    'Face Pull': [
      ExerciseOption('Reverse Fly', 'Dumbbell alternative'),
      ExerciseOption('Band Pull-Apart', 'Can do anywhere'),
    ],
    'Rear Delt Fly': [
      ExerciseOption('Face Pull', 'Cable alternative'),
      ExerciseOption('Reverse Pec Deck', 'Machine alternative'),
    ],

    // Legs
    'Barbell Squat': [
      ExerciseOption('Goblet Squat', 'Dumbbell/kettlebell alternative'),
      ExerciseOption('Leg Press', 'Machine alternative'),
    ],
    'Goblet Squat': [
      ExerciseOption('Barbell Squat', 'Heavier loading option'),
      ExerciseOption('Bodyweight Squat', 'No equipment needed'),
    ],
    'Leg Press': [
      ExerciseOption('Hack Squat', 'Similar movement pattern'),
      ExerciseOption('Barbell Squat', 'Free weight alternative'),
    ],
    'Leg Extension': [
      ExerciseOption('Sissy Squat', 'Bodyweight alternative'),
      ExerciseOption('Bulgarian Split Squat', 'Unilateral alternative'),
    ],
    'Leg Curl': [
      ExerciseOption('Romanian Deadlift', 'Compound alternative'),
      ExerciseOption('Nordic Curl', 'Bodyweight alternative'),
    ],
    'Bulgarian Split Squat': [
      ExerciseOption('Lunges', 'Similar unilateral pattern'),
      ExerciseOption('Step-Ups', 'Another unilateral option'),
    ],
    'Lunges': [
      ExerciseOption('Bulgarian Split Squat', 'More quad focus'),
      ExerciseOption('Walking Lunges', 'Dynamic variation'),
    ],
    'Calf Raise': [
      ExerciseOption('Seated Calf Raise', 'More soleus focus'),
      ExerciseOption('Single-Leg Calf Raise', 'Unilateral variation'),
    ],
    'Hip Thrust': [
      ExerciseOption('Glute Bridge', 'Easier variation'),
      ExerciseOption('Cable Pull-Through', 'Alternative hip extension'),
    ],

    // Arms
    'Barbell Curl': [
      ExerciseOption('Dumbbell Curl', 'Unilateral control'),
      ExerciseOption('EZ Bar Curl', 'Easier on wrists'),
    ],
    'Dumbbell Curl': [
      ExerciseOption('Hammer Curl', 'Brachialis focus'),
      ExerciseOption('Cable Curl', 'Constant tension'),
    ],
    'Hammer Curl': [
      ExerciseOption('Dumbbell Curl', 'Supinated grip'),
      ExerciseOption('Cross-Body Hammer Curl', 'Variation'),
    ],
    'Tricep Pushdown': [
      ExerciseOption('Overhead Tricep Extension', 'Long head emphasis'),
      ExerciseOption('Dips', 'Compound movement'),
    ],
    'Skull Crusher': [
      ExerciseOption('Overhead Tricep Extension', 'Alternative angle'),
      ExerciseOption('Close-Grip Bench Press', 'Compound alternative'),
    ],
    'Dips': [
      ExerciseOption('Tricep Pushdown', 'Isolation alternative'),
      ExerciseOption('Bench Dips', 'Easier variation'),
    ],

    // Core
    'Plank': [
      ExerciseOption('Dead Bug', 'Anti-extension alternative'),
      ExerciseOption('Hollow Body Hold', 'Gymnastic variation'),
    ],
    'Ab Crunch': [
      ExerciseOption('Cable Crunch', 'Weighted alternative'),
      ExerciseOption('Dead Bug', 'Safer spinal option'),
    ],
    'Hanging Leg Raise': [
      ExerciseOption('Lying Leg Raise', 'Floor alternative'),
      ExerciseOption('Captain\'s Chair Leg Raise', 'Supported version'),
    ],
    'Russian Twist': [
      ExerciseOption('Pallof Press', 'Anti-rotation alternative'),
      ExerciseOption('Cable Woodchop', 'Weighted rotation'),
    ],
  };

  /// Find alternatives for an exercise.
  /// Returns null if no alternatives are found.
  /// Performs case-insensitive matching and partial matching.
  static List<ExerciseOption>? findAlternatives(String exerciseName) {
    // Direct match (case-insensitive)
    final normalizedName = exerciseName.toLowerCase().trim();

    for (final entry in alternatives.entries) {
      if (entry.key.toLowerCase() == normalizedName) {
        return entry.value;
      }
    }

    // Partial match - find exercises that contain the search term
    for (final entry in alternatives.entries) {
      final entryLower = entry.key.toLowerCase();
      if (entryLower.contains(normalizedName) ||
          normalizedName.contains(entryLower)) {
        return entry.value;
      }
    }

    // Try matching by key words
    final words = normalizedName.split(' ').where((w) => w.length > 3).toList();
    for (final word in words) {
      for (final entry in alternatives.entries) {
        if (entry.key.toLowerCase().contains(word)) {
          return entry.value;
        }
      }
    }

    return null;
  }

  /// Get default alternatives when no specific alternatives are found.
  /// Returns generic options based on the exercise name.
  static List<ExerciseOption> getDefaultAlternatives(String exerciseName) {
    final lower = exerciseName.toLowerCase();

    if (lower.contains('press') || lower.contains('push')) {
      return [
        ExerciseOption('Push-Ups', 'Bodyweight pushing movement'),
        ExerciseOption('Machine Press', 'Guided pressing movement'),
      ];
    }

    if (lower.contains('row') || lower.contains('pull')) {
      return [
        ExerciseOption('Dumbbell Row', 'Unilateral pulling'),
        ExerciseOption('Lat Pulldown', 'Vertical pulling'),
      ];
    }

    if (lower.contains('squat') || lower.contains('leg')) {
      return [
        ExerciseOption('Goblet Squat', 'Dumbbell squat variation'),
        ExerciseOption('Leg Press', 'Machine alternative'),
      ];
    }

    if (lower.contains('curl')) {
      return [
        ExerciseOption('Dumbbell Curl', 'Standard bicep curl'),
        ExerciseOption('Hammer Curl', 'Neutral grip variation'),
      ];
    }

    if (lower.contains('extension') || lower.contains('tricep')) {
      return [
        ExerciseOption('Tricep Pushdown', 'Cable tricep exercise'),
        ExerciseOption('Dips', 'Compound tricep movement'),
      ];
    }

    // Generic fallback
    return [
      ExerciseOption('Similar Movement', 'Ask your trainer for alternatives'),
      ExerciseOption('Machine Version', 'Check available machines'),
    ];
  }
}

/// Represents an alternative exercise option.
class ExerciseOption {
  final String name;
  final String description;

  const ExerciseOption(this.name, this.description);
}
