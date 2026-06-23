// ============================================
// FILE: lib/data/repositories/event_repository.dart
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../../core/constants/firebase_constants.dart';
import '../../services/operation_log_service.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all events (Stream for real-time updates)
  Stream<List<EventModel>> getAllEvents() {
    return _firestore
        .collection(FirebaseConstants.eventsCollection)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get events by date range
  Stream<List<EventModel>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    final startDateStr =
        "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
    final endDateStr =
        "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

    return _firestore
        .collection(FirebaseConstants.eventsCollection)
        .where('date', isGreaterThanOrEqualTo: startDateStr)
        .where('date', isLessThanOrEqualTo: endDateStr)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get events by date range (one-time fetch)
  Future<List<EventModel>> getEventsByDateRangeOnce(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr =
          "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      final endDateStr =
          "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

      final snapshot = await _firestore
          .collection(FirebaseConstants.eventsCollection)
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting events by date range: $e');
      return [];
    }
  }

  // Get event by ID
  Future<EventModel?> getEventById(String id) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.eventsCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting event: $e');
      return null;
    }
  }

  // Create event
  Future<String?> createEvent(EventModel event) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConstants.eventsCollection)
          .add(event.toFirestore());
      await OperationLogService.log(
        action: 'create',
        entityType: 'event',
        entityId: docRef.id,
        entityName: event.title,
        details: {'type': event.type, 'date': event.date},
      );
      return docRef.id;
    } catch (e) {
      print('Error creating event: $e');
      return null;
    }
  }

  // Update event
  Future<bool> updateEvent(String id, EventModel event) async {
    try {
      await _firestore
          .collection(FirebaseConstants.eventsCollection)
          .doc(id)
          .update(event.toFirestore());
      await OperationLogService.log(
        action: 'update',
        entityType: 'event',
        entityId: id,
        entityName: event.title,
        details: {'type': event.type, 'date': event.date},
      );
      return true;
    } catch (e) {
      print('Error updating event: $e');
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String id) async {
    try {
      await _firestore
          .collection(FirebaseConstants.eventsCollection)
          .doc(id)
          .delete();
      await OperationLogService.log(
        action: 'delete',
        entityType: 'event',
        entityId: id,
      );
      return true;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  // Add volunteer to event
  Future<bool> addVolunteerToEvent(String eventId, String volunteerId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.eventsCollection)
          .doc(eventId)
          .update({
            'volunteerIds': FieldValue.arrayUnion([volunteerId]),
            'updatedAt': Timestamp.now(),
          });
      await OperationLogService.log(
        action: 'update',
        entityType: 'event_volunteer_add',
        entityId: eventId,
        details: {'volunteerId': volunteerId},
      );
      return true;
    } catch (e) {
      print('Error adding volunteer to event: $e');
      return false;
    }
  }

  // Remove volunteer from event
  Future<bool> removeVolunteerFromEvent(
    String eventId,
    String volunteerId,
  ) async {
    try {
      await _firestore
          .collection(FirebaseConstants.eventsCollection)
          .doc(eventId)
          .update({
            'volunteerIds': FieldValue.arrayRemove([volunteerId]),
            'updatedAt': Timestamp.now(),
          });
      await OperationLogService.log(
        action: 'update',
        entityType: 'event_volunteer_remove',
        entityId: eventId,
        details: {'volunteerId': volunteerId},
      );
      return true;
    } catch (e) {
      print('Error removing volunteer from event: $e');
      return false;
    }
  }
}
