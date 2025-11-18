// ============================================
// FILE: lib/domain/entities/event.dart
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
  final List<String> volunteerIds;
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
    required this.volunteerIds,
    required this.createdAt,
    required this.updatedAt,
  });
}
