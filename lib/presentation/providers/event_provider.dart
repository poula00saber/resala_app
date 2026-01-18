// ============================================
// FILE: lib/presentation/providers/event_provider.dart
// ============================================

import 'package:flutter/foundation.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';

enum EventFilter { last7Days, lastMonth, all }

class EventProvider with ChangeNotifier {
  final EventRepository _repository = EventRepository();

  List<EventModel> _events = [];
  List<EventModel> get events => _events;

  EventFilter _currentFilter = EventFilter.last7Days;
  EventFilter get currentFilter => _currentFilter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Initialize events stream
  void initEvents() {
    _repository.getAllEvents().listen(
      (events) {
        _events = events;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Get filtered events
  List<EventModel> getFilteredEvents() {
    final now = DateTime.now();

    switch (_currentFilter) {
      case EventFilter.last7Days:
        return _events.where((event) {
          final eventDate = DateTime.parse(event.date);
          final difference = eventDate.difference(now).inDays;
          return difference <= 7 && difference >= 0;
        }).toList();

      case EventFilter.lastMonth:
        return _events.where((event) {
          final eventDate = DateTime.parse(event.date);
          //make it for the next 30 days
          final difference = eventDate.difference(now).inDays;
          return difference <= 30 && difference >= 0;
        }).toList();

      case EventFilter.all:
        return _events;
    }
  }

  // Group events by date
  Map<String, List<EventModel>> getGroupedEvents() {
    final filteredEvents = getFilteredEvents();
    final Map<String, List<EventModel>> grouped = {};

    for (var event in filteredEvents) {
      if (!grouped.containsKey(event.date)) {
        grouped[event.date] = [];
      }
      grouped[event.date]!.add(event);
    }

    return grouped;
  }

  // Set filter
  void setFilter(EventFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  // Create event
  Future<String?> createEvent({
    required String title,
    required String type,
    required String date,
    required String description,
    String? location,
    String? meetingPlace,
    String? administrativeType,
    String? committeeId, // ADD THIS
    String? committeeName, // ADD THIS
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final event = EventModel(
        id: '',
        title: title,
        type: type,
        date: date,
        description: description,
        location: location,
        meetingPlace: meetingPlace,
        administrativeType: administrativeType,
        committeeId: committeeId, // ADD THIS
        committeeName: committeeName, // ADD THIS
        volunteerIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await _repository.createEvent(event);
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update event
  Future<bool> updateEvent(String id, EventModel event) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.updateEvent(id, event);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.deleteEvent(id);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add volunteer to event
  Future<bool> addVolunteerToEvent(String eventId, String volunteerId) async {
    try {
      return await _repository.addVolunteerToEvent(eventId, volunteerId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove volunteer from event
  Future<bool> removeVolunteerFromEvent(
    String eventId,
    String volunteerId,
  ) async {
    try {
      return await _repository.removeVolunteerFromEvent(eventId, volunteerId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get event by ID
  Future<EventModel?> getEventById(String id) async {
    return await _repository.getEventById(id);
  }
}
