// ============================================
// FILE: lib/domain/entities/event.dart
// UPDATED: Added meeting-specific fields for Word export
// ============================================

class Event {
  final String id;
  final String title;
  final String type;
  final String date;
  final String description;
  final String? location;
  final String? meetingPlace;
  final String? administrativeType;
  final String? committeeId;
  final String? committeeName;
  final List<String> volunteerIds;
  final Map<String, bool> qaflaPreparation;
  final Map<String, bool> qaflaFilling;
  final Map<String, bool> qaflaDistribution;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Meeting-specific fields (محضر الاجتماع)
  final String? meetingCategory;
  final List<String> previousMeetingPoints;
  final List<String> newMeetingPoints;
  final List<Map<String, String>> votingItems;
  final List<String> meetingDecisions;
  final List<String> deferredPoints;
  final String? additionalDetails;

  Event({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.description,
    this.location,
    this.meetingPlace,
    this.administrativeType,
    this.committeeId,
    this.committeeName,
    required this.volunteerIds,
    this.qaflaPreparation = const {},
    this.qaflaFilling = const {},
    this.qaflaDistribution = const {},
    required this.createdAt,
    required this.updatedAt,
    this.meetingCategory,
    this.previousMeetingPoints = const [],
    this.newMeetingPoints = const [],
    this.votingItems = const [],
    this.meetingDecisions = const [],
    this.deferredPoints = const [],
    this.additionalDetails,
  });
}
