// ============================================
// FILE: lib/data/models/report_data_model.dart
// Model for aggregated report data
// ============================================

class VolunteerReportData {
  final String volunteerId;
  final String volunteerName;
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

  VolunteerReportData({
    required this.volunteerId,
    required this.volunteerName,
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
  }) : monthsParticipated = monthsParticipated ?? {};

  int get totalEvents => familyDayCount + cubsEventCount + eventsCount;

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
  String? educationalLevel;
  String? committeeId;
  int? month;
  int? year;

  ReportFilter({
    this.volunteerName,
    this.educationalLevel,
    this.committeeId,
    this.month,
    this.year,
  });

  bool get hasFilters =>
      volunteerName != null ||
      educationalLevel != null ||
      committeeId != null ||
      month != null;
}
