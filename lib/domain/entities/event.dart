// ============================================
// FILE: lib/domain/entities/event.dart
// FIXED: Added committeeId, committeeName, and qafla role fields
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
  final String? committeeId; // NEW
  final String? committeeName; // NEW
  final List<String> volunteerIds;
  final Map<String, bool> qaflaPreparation; // تجهيز per volunteer
  final Map<String, bool> qaflaFilling; // تعبئة per volunteer
  final Map<String, bool> qaflaDistribution; // توزيع per volunteer
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.description,
    this.location,
    this.meetingPlace,
    this.administrativeType,
    this.committeeId, // NEW
    this.committeeName, // NEW
    required this.volunteerIds,
    this.qaflaPreparation = const {},
    this.qaflaFilling = const {},
    this.qaflaDistribution = const {},
    required this.createdAt,
    required this.updatedAt,
  });
}
