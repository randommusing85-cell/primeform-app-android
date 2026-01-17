import '../models/user_profile.dart';

/// Post-partum phases based on weeks since delivery
enum PostPartumPhase {
  none,           // Not post-partum
  earlyRecovery,  // 0-12 weeks
  rebuilding,     // 12-24 weeks (3-6 months)
  strengthening,  // 24-78 weeks (6-18 months)
}

/// Calculate post-partum timeline and provide safe guidance
class PostPartumCalculator {
  /// Calculate weeks since delivery
  static int? getWeeksPostPartum(UserProfile profile) {
    if (profile.postPartumStatus == 'no' || profile.deliveryDate == null) {
      return null;
    }

    final now = DateTime.now();
    final delivery = profile.deliveryDate!;
    return now.difference(delivery).inDays ~/ 7;
  }

  /// Get current post-partum phase
  static PostPartumPhase getPhase(UserProfile profile) {
    final weeks = getWeeksPostPartum(profile);
    if (weeks == null) return PostPartumPhase.none;

    if (weeks < 12) {
      return PostPartumPhase.earlyRecovery;
    } else if (weeks < 24) {
      return PostPartumPhase.rebuilding;
    } else {
      return PostPartumPhase.strengthening;
    }
  }

  /// Get phase name for display
  static String getPhaseName(PostPartumPhase phase) {
    switch (phase) {
      case PostPartumPhase.earlyRecovery:
        return 'Early Recovery';
      case PostPartumPhase.rebuilding:
        return 'Rebuilding';
      case PostPartumPhase.strengthening:
        return 'Strengthening';
      default:
        return '';
    }
  }

  /// Get phase emoji
  static String getPhaseEmoji(PostPartumPhase phase) {
    switch (phase) {
      case PostPartumPhase.earlyRecovery:
        return '💜'; // Heart for gentle care
      case PostPartumPhase.rebuilding:
        return '🌱'; // Growth
      case PostPartumPhase.strengthening:
        return '💪'; // Strength
      default:
        return '';
    }
  }

  /// Get short guidance for home screen
  static String getShortGuidance(PostPartumPhase phase) {
    switch (phase) {
      case PostPartumPhase.earlyRecovery:
        return 'Focus on healing - walk, breathe, rest';
      case PostPartumPhase.rebuilding:
        return 'Gradual strength building - listen to your body';
      case PostPartumPhase.strengthening:
        return 'Building back strength - progress mindfully';
      default:
        return '';
    }
  }

  /// Get detailed guidance
  static String getDetailedGuidance(PostPartumPhase phase) {
    switch (phase) {
      case PostPartumPhase.earlyRecovery:
        return '''
Your body is healing. This is NOT the time to "bounce back."

Focus on:
• Walking (start 10-15 mins)
• Pelvic floor reconnection
• Gentle breathing exercises
• Sleep when you can

Avoid:
• Running, jumping, high-impact
• Intense ab work
• Heavy lifting (>10kg)
• Pushing through pain

Remember: Healing IS progress.
        ''';

      case PostPartumPhase.rebuilding:
        return '''
Gradual rebuilding phase. Listen to your body.

Focus on:
• Progressive strength training
• Core stability (NOT crunches yet)
• Pelvic floor strengthening
• Gradual cardio increase

Watch for:
• Pelvic pressure/heaviness
• Leaking (stop if this happens)
• Diastasis recti widening
• Lower back pain

Progress slowly. No rush.
        ''';

      case PostPartumPhase.strengthening:
        return '''
Building back strength. Still be mindful.

Focus on:
• Progressive overload
• Full strength training
• Impact training (if cleared)
• Core integration

Check in:
• How's your pelvic floor?
• Any leaking with exercise?
• Core engaging properly?
• Sleep affecting recovery?

You're strong. Train smart.
        ''';

      default:
        return '';
    }
  }

  /// Check if exercise is safe based on timeline
  static bool isExerciseSafe(UserProfile profile, String exerciseType) {
    final weeks = getWeeksPostPartum(profile);
    if (weeks == null) return true; // Not post-partum

    // No exercise before medical clearance
    if (!profile.medicalClearance) return false;

    // Add extra weeks for C-section recovery
    final adjustedWeeks = profile.deliveryType == 'cesarean' 
        ? weeks - 2  // C-section: add 2 weeks to timeline
        : weeks;

    switch (exerciseType) {
      case 'walking':
      case 'pelvic_floor':
      case 'breathing':
        return adjustedWeeks >= 6;

      case 'bodyweight_strength':
      case 'light_weights':
      case 'yoga':
        return adjustedWeeks >= 8;

      case 'moderate_weights':
      case 'low_impact_cardio':
      case 'swimming':
        return adjustedWeeks >= 12;

      case 'planks':
      case 'modified_core':
        return adjustedWeeks >= 12; // And check diastasis

      case 'running':
      case 'jumping':
      case 'hiit':
        return adjustedWeeks >= 16; // And pelvic floor check

      case 'heavy_lifting':
      case 'advanced_core':
      case 'intense_cardio':
        return adjustedWeeks >= 16;

      default:
        return true; // Unknown exercise, allow but with caution
    }
  }

  /// Get intensity multiplier for post-partum
  static double getIntensityMultiplier(PostPartumPhase phase) {
    switch (phase) {
      case PostPartumPhase.earlyRecovery:
        return 0.5; // 50% intensity
      case PostPartumPhase.rebuilding:
        return 0.7; // 70% intensity
      case PostPartumPhase.strengthening:
        return 0.9; // 90% intensity
      default:
        return 1.0;
    }
  }

  /// Get red flag warnings
  static List<String> getRedFlags() {
    return [
      '⚠️ Stop if you experience leaking (urine or fecal)',
      '⚠️ Stop if you feel pelvic pressure or heaviness',
      '⚠️ Stop if you see abdominal doming or bulging',
      '⚠️ Stop if you have pain (not just muscle soreness)',
      '⚠️ Stop if bleeding increases or returns',
      '⚠️ Consult pelvic floor PT if issues persist',
    ];
  }

  /// Get exercise substitutions for post-partum
  static Map<String, String> getSafeSubstitutions() {
    return {
      'Crunches': 'Dead bugs or bird dogs',
      'Sit-ups': 'Pelvic tilts or modified planks',
      'Running': 'Walking or elliptical',
      'Jumping jacks': 'Step touches',
      'Burpees': 'Modified squats + wall push-ups',
      'High plank': 'Incline plank or wall plank',
      'Heavy deadlifts': 'Glute bridges or light deadlifts',
    };
  }

  /// Check if core work needs diastasis assessment
  static bool needsDiastasisCheck(UserProfile profile, String exercise) {
    if (profile.postPartumStatus == 'no') return false;

    final weeks = getWeeksPostPartum(profile);
    if (weeks == null || weeks >= 24) return false; // After 6 months, less critical

    final coreExercises = [
      'planks',
      'crunches',
      'sit-ups',
      'leg raises',
      'mountain climbers',
      'v-ups',
    ];

    return coreExercises.any((ex) => exercise.toLowerCase().contains(ex));
  }

  /// Get color for phase (for UI)
  static String getPhaseColorHex(PostPartumPhase phase) {
    switch (phase) {
      case PostPartumPhase.earlyRecovery:
        return '#E1BEE7'; // Light purple
      case PostPartumPhase.rebuilding:
        return '#A5D6A7'; // Light green
      case PostPartumPhase.strengthening:
        return '#90CAF9'; // Light blue
      default:
        return '#E0E0E0'; // Gray
    }
  }

  /// Calculate expected clearance date (6 weeks post-delivery)
  static DateTime? getExpectedClearanceDate(UserProfile profile) {
    if (profile.deliveryDate == null) return null;
    
    // Standard clearance: 6 weeks
    // C-section: 8 weeks
    final weeksToAdd = profile.deliveryType == 'cesarean' ? 8 : 6;
    
    return profile.deliveryDate!.add(Duration(days: weeksToAdd * 7));
  }

  /// Check if user is cleared to start (>6 weeks + medical clearance)
  static bool isReadyToStart(UserProfile profile) {
    if (profile.postPartumStatus == 'no') return true;
    if (!profile.medicalClearance) return false;
    
    final weeks = getWeeksPostPartum(profile);
    if (weeks == null) return false;
    
    final minWeeks = profile.deliveryType == 'cesarean' ? 8 : 6;
    return weeks >= minWeeks;
  }
}
