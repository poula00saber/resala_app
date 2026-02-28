// ============================================
// FILE: lib/data/models/report_data_model.dart
// Model for aggregated report data
// ============================================

class VolunteerReportData {
  final String volunteerId;
  final String volunteerName;
  final String? phone;
  final String? educationalLevel;
  final String? committeeName;
  final String? committeeId;

  // Event participation counts
  int familyDayCount;
  int cubsEventCount;
  int eventsCount;
  int committeeMeetingCount;
  int teamMeetingCount;
  int leadersMeetingCount;

  // Financial
  double fundAmount;
  double totalFundAmount;
  int fundCount; // Number of contributions

  // Marketing
  int storyCount;

  // Months participated - store as month numbers (1-12)
  Set<int> monthsParticipated;

  // Unique participation dates (for مشاركات count)
  Set<String> uniqueDates;

  VolunteerReportData({
    required this.volunteerId,
    required this.volunteerName,
    this.phone,
    this.educationalLevel,
    this.committeeName,
    this.committeeId,
    this.familyDayCount = 0,
    this.cubsEventCount = 0,
    this.eventsCount = 0,
    this.committeeMeetingCount = 0,
    this.teamMeetingCount = 0,
    this.leadersMeetingCount = 0,
    this.fundAmount = 0,
    this.totalFundAmount = 0,
    this.fundCount = 0,
    this.storyCount = 0,
    Set<int>? monthsParticipated,
    Set<String>? uniqueDates,
  }) : monthsParticipated = monthsParticipated ?? {},
       uniqueDates = uniqueDates ?? {};

  int get totalEvents => familyDayCount + cubsEventCount + eventsCount;

  // Unique participation days count (مشاركات)
  int get participationDays => uniqueDates.length;

  int get totalMeetings =>
      committeeMeetingCount + teamMeetingCount + leadersMeetingCount;

  // Get months as comma-separated numbers sorted
  String get monthsString {
    if (monthsParticipated.isEmpty) return '-';
    final sortedMonths = monthsParticipated.toList()..sort();
    return sortedMonths.join(',');
  }

  int get monthsCount => monthsParticipated.length;

  // Check if volunteer is a cub (شبل)
  bool get isCub => educationalLevel == 'شبل' || educationalLevel == 'شبل مميز';

  Map<String, dynamic> toMap() {
    return {
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'educationalLevel': educationalLevel,
      'committeeName': committeeName,
      'familyDayCount': familyDayCount,
      'cubsEventCount': cubsEventCount,
      'eventsCount': eventsCount,
      'committeeMeetingCount': committeeMeetingCount,
      'teamMeetingCount': teamMeetingCount,
      'leadersMeetingCount': leadersMeetingCount,
      'fundAmount': fundAmount,
      'totalFundAmount': totalFundAmount,
      'fundCount': fundCount,
      'storyCount': storyCount,
      'monthsCount': monthsCount,
    };
  }
}

class ReportFilter {
  String? volunteerName;
  List<String>? educationalLevels; // Multi-select degrees
  String? committeeId;
  List<int>? months; // Multi-select months
  int? year;

  ReportFilter({
    this.volunteerName,
    this.educationalLevels,
    this.committeeId,
    this.months,
    this.year,
  });

  bool get hasFilters =>
      volunteerName != null ||
      (educationalLevels != null && educationalLevels!.isNotEmpty) ||
      committeeId != null ||
      (months != null && months!.isNotEmpty);
}
