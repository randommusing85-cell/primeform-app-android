import 'package:isar/isar.dart';

part 'user_profile.g.dart';

@collection
class UserProfile {
  Id id = Isar.autoIncrement;

  late int age;
  late String sex; // 'male' or 'female'
  late int heightCm;
  late double weightKg;

  late String goal; // 'cut', 'recomp', 'bulk'
  late String level; // 'beginner', 'intermediate', 'advanced'
  late String equipment; // 'gym', 'home_dumbbells', 'calisthenics'
  late int trainingDaysPerWeek;

  late DateTime createdAt;
  late DateTime updatedAt;

  // ===== CYCLE TRACKING FIELDS =====
  
  /// Whether user wants cycle-aware training
  bool trackCycle = false;
  
  /// Date of last period start (Day 1)
  DateTime? lastPeriodDate;
  
  /// Average cycle length in days (default 28)
  int cycleLength = 28;
  
  /// Average period duration in days (default 5)
  int periodDuration = 5;

  // ===== POST-PARTUM FIELDS =====
  
  /// Post-partum status: 'no', 'early' (0-12w), 'mid' (3-6m), 'late' (6-18m)
  String postPartumStatus = 'no';
  
  /// Date of delivery (for timeline calculation)
  DateTime? deliveryDate;
  
  /// Has medical clearance to exercise
  bool medicalClearance = false;
  
  /// Wants diastasis recti guidance
  bool checkDiastasis = false;
  
  /// Delivery type (affects recovery timeline)
  String deliveryType = 'unknown'; // 'vaginal', 'cesarean', 'unknown'

  // ===== INJURY/LIMITATION FIELDS =====
  
  /// List of injuries/limitations (stored as comma-separated string for Isar)
  /// Examples: 'lower_back', 'knee_left', 'shoulder_right', 'wrist'
  String injuries = '';
  
  /// Additional notes about injuries/limitations
  String? injuryNotes;

  // ===== NOTIFICATION PREFERENCES =====
  
  /// Whether to send daily check-in reminders
  bool notifyCheckIn = true;
  
  /// Whether to send workout day reminders
  bool notifyWorkout = true;
  
  /// Preferred reminder time (hour of day, 0-23)
  int reminderHour = 9;
  
  /// Preferred reminder time (minute, 0-59)
  int reminderMinute = 0;

  // ===== HELPER METHODS =====
  
  /// Get injuries as a list
  List<String> get injuryList {
    if (injuries.isEmpty) return [];
    return injuries.split(',').where((s) => s.isNotEmpty).toList();
  }
  
  /// Set injuries from a list
  set injuryList(List<String> list) {
    injuries = list.join(',');
  }
  
  /// Check if user has any injuries
  bool get hasInjuries => injuries.isNotEmpty;
  
  /// Get formatted injury text for display
  String get injuryDisplayText {
    final list = injuryList;
    if (list.isEmpty) return 'None';
    return list.map((i) => _formatInjuryName(i)).join(', ');
  }
  
  static String _formatInjuryName(String injury) {
    return injury
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1)}' 
            : '')
        .join(' ');
  }
}