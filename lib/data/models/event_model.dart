// ============================================
// FILE: lib/data/models/event_model.dart
// UPDATED: Added meeting-specific fields for Word export
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
    super.committeeId,
    super.committeeName,
    required super.volunteerIds,
    super.qaflaPreparation,
    super.qaflaFilling,
    super.qaflaDistribution,
    required super.createdAt,
    required super.updatedAt,
    super.meetingCategory,
    super.previousMeetingPoints,
    super.newMeetingPoints,
    super.votingItems,
    super.meetingDecisions,
    super.deferredPoints,
    super.additionalDetails,
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
      committeeId: data['committeeId'],
      committeeName: data['committeeName'],
      volunteerIds: List<String>.from(data['volunteerIds'] ?? []),
      qaflaPreparation: Map<String, bool>.from(data['qaflaPreparation'] ?? {}),
      qaflaFilling: Map<String, bool>.from(data['qaflaFilling'] ?? {}),
      qaflaDistribution: Map<String, bool>.from(
        data['qaflaDistribution'] ?? {},
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      meetingCategory: data['meetingCategory'],
      previousMeetingPoints: List<String>.from(
        data['previousMeetingPoints'] ?? [],
      ),
      newMeetingPoints: List<String>.from(data['newMeetingPoints'] ?? []),
      votingItems:
          (data['votingItems'] as List<dynamic>?)
              ?.map((item) => Map<String, String>.from(item as Map))
              .toList() ??
          [],
      meetingDecisions: List<String>.from(data['meetingDecisions'] ?? []),
      deferredPoints: List<String>.from(data['deferredPoints'] ?? []),
      additionalDetails: data['additionalDetails'],
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
      'committeeId': committeeId,
      'committeeName': committeeName,
      'volunteerIds': volunteerIds,
      'qaflaPreparation': qaflaPreparation,
      'qaflaFilling': qaflaFilling,
      'qaflaDistribution': qaflaDistribution,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.now(),
      'meetingCategory': meetingCategory,
      'previousMeetingPoints': previousMeetingPoints,
      'newMeetingPoints': newMeetingPoints,
      'votingItems': votingItems,
      'meetingDecisions': meetingDecisions,
      'deferredPoints': deferredPoints,
      'additionalDetails': additionalDetails,
    };
  }
}
