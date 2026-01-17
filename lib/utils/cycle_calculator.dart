import '../models/user_profile.dart';

/// Menstrual cycle phases
enum CyclePhase {
  menstrual,   // Days 1-5 (period)
  follicular,  // Days 6-14 (post-period, building energy)
  ovulation,   // Days 14-16 (peak energy and strength)
  luteal,      // Days 17-28 (declining energy, PMS)
}

/// Calculate current cycle phase and provide training guidance
class CycleCalculator {
  /// Calculate which phase user is currently in
  static CyclePhase? getCurrentPhase(UserProfile profile) {
    if (!profile.trackCycle || profile.lastPeriodDate == null) {
      return null;
    }

    final now = DateTime.now();
    final lastPeriod = profile.lastPeriodDate!;
    final daysSinceLastPeriod = now.difference(lastPeriod).inDays;
    
    // Handle cases where we're past the expected cycle length
    final cycleDay = (daysSinceLastPeriod % profile.cycleLength) + 1;
    
    return _getPhaseForDay(cycleDay, profile.periodDuration);
  }

  /// Get phase for a specific cycle day
  static CyclePhase _getPhaseForDay(int cycleDay, int periodDuration) {
    if (cycleDay <= periodDuration) {
      return CyclePhase.menstrual;
    } else if (cycleDay <= 14) {
      return CyclePhase.follicular;
    } else if (cycleDay <= 16) {
      return CyclePhase.ovulation;
    } else {
      return CyclePhase.luteal;
    }
  }

  /// Get current cycle day (1-28+)
  static int? getCurrentCycleDay(UserProfile profile) {
    if (!profile.trackCycle || profile.lastPeriodDate == null) {
      return null;
    }

    final now = DateTime.now();
    final lastPeriod = profile.lastPeriodDate!;
    final daysSinceLastPeriod = now.difference(lastPeriod).inDays;
    
    return (daysSinceLastPeriod % profile.cycleLength) + 1;
  }

  /// Get days until next period
  static int? getDaysUntilNextPeriod(UserProfile profile) {
    if (!profile.trackCycle || profile.lastPeriodDate == null) {
      return null;
    }

    final now = DateTime.now();
    final lastPeriod = profile.lastPeriodDate!;
    final daysSinceLastPeriod = now.difference(lastPeriod).inDays;
    final cycleDay = (daysSinceLastPeriod % profile.cycleLength) + 1;
    
    return profile.cycleLength - cycleDay;
  }

  /// Get user-friendly phase name
  static String getPhaseName(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal';
    }
  }

  /// Get phase emoji
  static String getPhaseEmoji(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return '🌙';
      case CyclePhase.follicular:
        return '🌱';
      case CyclePhase.ovulation:
        return '⭐';
      case CyclePhase.luteal:
        return '🍂';
    }
  }

  /// Get training guidance for current phase
  static String getTrainingGuidance(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Your body is recovering. Focus on lighter training, more rest, and listen to your body.';
      case CyclePhase.follicular:
        return 'Great time to push harder! Your hormones support muscle building and recovery.';
      case CyclePhase.ovulation:
        return 'Peak performance window! You\'re at your strongest. Challenge yourself today.';
      case CyclePhase.luteal:
        return 'Energy may be lower - that\'s completely normal. Maintaining is winning this week.';
    }
  }

  /// Get short guidance (for home screen)
  static String getShortGuidance(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Recovery week - be gentle with yourself';
      case CyclePhase.follicular:
        return 'Great time to build strength';
      case CyclePhase.ovulation:
        return 'Peak performance - push yourself!';
      case CyclePhase.luteal:
        return 'Lower energy is normal - maintain';
    }
  }

  /// Get intensity recommendation (0.8-1.2 multiplier)
  static double getIntensityMultiplier(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 0.85; // 15% easier
      case CyclePhase.follicular:
        return 1.05; // 5% harder
      case CyclePhase.ovulation:
        return 1.1; // 10% harder
      case CyclePhase.luteal:
        return 0.9; // 10% easier
    }
  }

  /// Get color for phase (for UI)
  static String getPhaseColorHex(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return '#FF6B9D'; // Pink
      case CyclePhase.follicular:
        return '#4CAF50'; // Green
      case CyclePhase.ovulation:
        return '#FFC107'; // Gold
      case CyclePhase.luteal:
        return '#FF9800'; // Orange
    }
  }
}
