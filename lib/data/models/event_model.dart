// ============================================
// FILE: lib/data/models/event_model.dart
// UPDATED: Added committeeId and committeeName fields
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/event.dart';

class EventModel extends Event {
  EventModel({
    required super.id,
    required super.title,
    required super.type,
    required super.date,
    required super.description,
    super.location,
    super.meetingPlace,
    super.administrativeType,
    super.committeeId, // NEW
    super.committeeName, // NEW
    required super.volunteerIds,
    required super.createdAt,
    required super.updatedAt,
  });

  // From Firestore
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      type: data['type'] ?? '',
      date: data['date'] ?? '',
      description: data['description'] ?? '',
      location: data['location'],
      meetingPlace: data['meetingPlace'],
      administrativeType: data['administrativeType'],
      committeeId: data['committeeId'], // NEW
      committeeName: data['committeeName'], // NEW
      volunteerIds: List<String>.from(data['volunteerIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'type': type,
      'date': date,
      'description': description,
      'location': location,
      'meetingPlace': meetingPlace,
      'administrativeType': administrativeType,
      'committeeId': committeeId, // NEW
      'committeeName': committeeName, // NEW
      'volunteerIds': volunteerIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.now(),
    };
  }
}
