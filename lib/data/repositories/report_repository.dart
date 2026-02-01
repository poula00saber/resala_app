// ============================================
// FILE: lib/data/repositories/report_repository.dart
// Repository for fetching and aggregating report data
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_data_model.dart';
import '../models/volunteer_model.dart';
import '../models/event_model.dart';
import '../../core/constants/firebase_constants.dart';

class ReportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Arabic month names
  static const List<String> arabicMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static String getArabicMonth(int month) {
    if (month >= 1 && month <= 12) {
      return arabicMonths[month - 1];
    }
    return '';
  }

  // Get all volunteers
  Future<List<VolunteerModel>> getAllVolunteers() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.volunteersCollection)
          .get();
      return snapshot.docs
          .map((doc) => VolunteerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting volunteers: $e');
      return [];
    }
  }

  // Get all events
  Future<List<EventModel>> getAllEvents() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.eventsCollection)
          .get();
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting events: $e');
      return [];
    }
  }

  // Get events by date filter
  Future<List<EventModel>> getEventsByFilter({int? month, int? year}) async {
    try {
      final events = await getAllEvents();

      if (month == null && year == null) {
        return events;
      }

      return events.where((event) {
        try {
          final eventDate = DateTime.parse(event.date);
          bool matches = true;
          if (month != null) {
            matches = matches && eventDate.month == month;
          }
          if (year != null) {
            matches = matches && eventDate.year == year;
          }
          return matches;
        } catch (e) {
          return false;
        }
      }).toList();
    } catch (e) {
      print('Error getting events by filter: $e');
      return [];
    }
  }

  // Get event month number from date string
  int? _getEventMonthNumber(String date) {
    try {
      final eventDate = DateTime.parse(date);
      return eventDate.month;
    } catch (e) {
      return null;
    }
  }

  // Helper to check if event is a cubs-specific event (ايفينت اشبال)
  bool _isCubsEvent(EventModel event) {
    return event.type == 'ايفينت اشبال' ||
        event.title.contains('أشبال') ||
        event.title.contains('شبل') ||
        event.description.contains('أشبال');
  }

  // Get comprehensive report data (الكلي)
  Future<List<VolunteerReportData>> getComprehensiveReportData({
    ReportFilter? filter,
  }) async {
    try {
      final volunteers = await getAllVolunteers();
      final events = await getEventsByFilter(
        month: filter?.month,
        year: filter?.year,
      );

      Map<String, VolunteerReportData> reportDataMap = {};

      // Initialize report data for all volunteers
      for (var volunteer in volunteers) {
        // Apply volunteer filters
        if (filter?.volunteerName != null &&
            !volunteer.name.contains(filter!.volunteerName!)) {
          continue;
        }
        if (filter?.educationalLevel != null &&
            volunteer.educationalLevel != filter!.educationalLevel) {
          continue;
        }

        reportDataMap[volunteer.id] = VolunteerReportData(
          volunteerId: volunteer.id,
          volunteerName: volunteer.name,
          educationalLevel: volunteer.educationalLevel,
          committeeName: volunteer.committeeName,
          committeeId: volunteer.committeeId,
        );
      }

      // Process events
      for (var event in events) {
        final eventMonth = _getEventMonthNumber(event.date);

        for (var volunteerId in event.volunteerIds) {
          if (!reportDataMap.containsKey(volunteerId)) continue;

          var data = reportDataMap[volunteerId]!;

          if (eventMonth != null) {
            data.monthsParticipated.add(eventMonth);
          }

          // Categorize event
          switch (event.type) {
            case 'يوم عائلي':
              data.familyDayCount++;
              break;
            case 'اجتماع':
              if (event.administrativeType == 'اجتماع ليدرات') {
                data.leadersMeetingCount++;
              } else if (event.committeeName != null) {
                data.committeeMeetingCount++;
              } else {
                data.teamMeetingCount++;
              }
              break;
            case 'ايفينت اشبال':
              data.cubsEventCount++;
              break;
            default:
              data.eventsCount++;
          }
        }
      }

      return reportDataMap.values.toList();
    } catch (e) {
      print('Error generating comprehensive report: $e');
      return [];
    }
  }

  // Get Family Day report (اليوم العائلي)
  Future<List<VolunteerReportData>> getFamilyDayReportData({
    ReportFilter? filter,
    bool cubsOnly = false,
  }) async {
    try {
      final volunteers = await getAllVolunteers();
      final events = await getEventsByFilter(
        month: filter?.month,
        year: filter?.year,
      );

      Map<String, VolunteerReportData> reportDataMap = {};

      // Filter volunteers
      for (var volunteer in volunteers) {
        if (filter?.volunteerName != null &&
            !volunteer.name.contains(filter!.volunteerName!)) {
          continue;
        }
        if (filter?.educationalLevel != null &&
            volunteer.educationalLevel != filter!.educationalLevel) {
          continue;
        }

        // Filter cubs vs non-cubs
        bool isCub =
            volunteer.educationalLevel == 'شبل' ||
            volunteer.educationalLevel == 'شبل مميز';
        if (cubsOnly && !isCub) continue;
        if (!cubsOnly && isCub) continue;

        reportDataMap[volunteer.id] = VolunteerReportData(
          volunteerId: volunteer.id,
          volunteerName: volunteer.name,
          educationalLevel: volunteer.educationalLevel,
          committeeName: volunteer.committeeName,
        );
      }

      // Process family day events
      for (var event in events) {
        if (event.type != 'يوم عائلي') continue;

        final eventMonth = _getEventMonthNumber(event.date);

        for (var volunteerId in event.volunteerIds) {
          if (!reportDataMap.containsKey(volunteerId)) continue;

          var data = reportDataMap[volunteerId]!;
          data.familyDayCount++;
          if (eventMonth != null) {
            data.monthsParticipated.add(eventMonth);
          }
        }
      }

      return reportDataMap.values.toList();
    } catch (e) {
      print('Error generating family day report: $e');
      return [];
    }
  }

  // Get Cubs report (الأشبال)
  Future<List<VolunteerReportData>> getCubsReportData({
    ReportFilter? filter,
    String? eventCategory, // 'الاحداث', 'الأيفنات', 'اليوم العائلي'
  }) async {
    try {
      final volunteers = await getAllVolunteers();
      final events = await getEventsByFilter(
        month: filter?.month,
        year: filter?.year,
      );

      Map<String, VolunteerReportData> reportDataMap = {};

      // Only get cubs volunteers
      for (var volunteer in volunteers) {
        bool isCub =
            volunteer.educationalLevel == 'شبل' ||
            volunteer.educationalLevel == 'شبل مميز';
        if (!isCub) continue;

        if (filter?.volunteerName != null &&
            !volunteer.name.contains(filter!.volunteerName!)) {
          continue;
        }
        if (filter?.educationalLevel != null &&
            volunteer.educationalLevel != filter!.educationalLevel) {
          continue;
        }

        reportDataMap[volunteer.id] = VolunteerReportData(
          volunteerId: volunteer.id,
          volunteerName: volunteer.name,
          educationalLevel: volunteer.educationalLevel,
          committeeName: volunteer.committeeName,
        );
      }

      // Process events
      for (var event in events) {
        final eventMonth = _getEventMonthNumber(event.date);

        for (var volunteerId in event.volunteerIds) {
          if (!reportDataMap.containsKey(volunteerId)) continue;

          var data = reportDataMap[volunteerId]!;
          if (eventMonth != null) {
            data.monthsParticipated.add(eventMonth);
          }

          if (event.type == 'يوم عائلي') {
            data.familyDayCount++;
          } else if (event.type == 'ايفينت اشبال' || _isCubsEvent(event)) {
            data.cubsEventCount++;
          } else if (event.type != 'اجتماع') {
            data.eventsCount++;
          }
        }
      }

      return reportDataMap.values.toList();
    } catch (e) {
      print('Error generating cubs report: $e');
      return [];
    }
  }

  // Get Meetings report (الأجتماعات)
  Future<List<VolunteerReportData>> getMeetingsReportData({
    ReportFilter? filter,
  }) async {
    try {
      final volunteers = await getAllVolunteers();
      final events = await getEventsByFilter(
        month: filter?.month,
        year: filter?.year,
      );

      Map<String, VolunteerReportData> reportDataMap = {};

      // Filter volunteers
      for (var volunteer in volunteers) {
        if (filter?.volunteerName != null &&
            !volunteer.name.contains(filter!.volunteerName!)) {
          continue;
        }
        if (filter?.educationalLevel != null &&
            volunteer.educationalLevel != filter!.educationalLevel) {
          continue;
        }
        if (filter?.committeeId != null &&
            volunteer.committeeId != filter!.committeeId) {
          continue;
        }

        reportDataMap[volunteer.id] = VolunteerReportData(
          volunteerId: volunteer.id,
          volunteerName: volunteer.name,
          educationalLevel: volunteer.educationalLevel,
          committeeName: volunteer.committeeName,
          committeeId: volunteer.committeeId,
        );
      }

      // Process meeting events
      for (var event in events) {
        if (event.type != 'اجتماع') continue;

        final eventMonth = _getEventMonthNumber(event.date);

        for (var volunteerId in event.volunteerIds) {
          if (!reportDataMap.containsKey(volunteerId)) continue;

          var data = reportDataMap[volunteerId]!;
          if (eventMonth != null) {
            data.monthsParticipated.add(eventMonth);
          }

          if (event.administrativeType == 'اجتماع ليدرات') {
            data.leadersMeetingCount++;
          } else if (event.committeeName != null &&
              event.committeeName!.isNotEmpty) {
            data.committeeMeetingCount++;
          } else {
            data.teamMeetingCount++;
          }
        }
      }

      return reportDataMap.values.toList();
    } catch (e) {
      print('Error generating meetings report: $e');
      return [];
    }
  }

  // Get Fund report (الصندوق) - fetches from funds collection
  Future<List<VolunteerReportData>> getFundReportData({
    ReportFilter? filter,
  }) async {
    try {
      final volunteers = await getAllVolunteers();

      Map<String, VolunteerReportData> reportDataMap = {};

      for (var volunteer in volunteers) {
        if (filter?.volunteerName != null &&
            !volunteer.name.contains(filter!.volunteerName!)) {
          continue;
        }
        if (filter?.educationalLevel != null &&
            volunteer.educationalLevel != filter!.educationalLevel) {
          continue;
        }

        reportDataMap[volunteer.id] = VolunteerReportData(
          volunteerId: volunteer.id,
          volunteerName: volunteer.name,
          educationalLevel: volunteer.educationalLevel,
          committeeName: volunteer.committeeName,
        );
      }

      // Get fund data from funds collection
      try {
        final fundsSnapshot = await _firestore.collection('funds').get();

        for (var doc in fundsSnapshot.docs) {
          final data = doc.data();
          final volunteerId = data['volunteerId'] as String?;
          final amount = (data['amount'] as num?)?.toDouble() ?? 0;
          final month = data['month'] as int?;
          final year = data['year'] as int?;
          final isWithdrawal = data['isWithdrawal'] ?? false;

          if (volunteerId != null && reportDataMap.containsKey(volunteerId)) {
            // Apply date filter
            if (filter?.month != null && month != filter!.month) continue;
            if (filter?.year != null && year != filter!.year) continue;

            var reportData = reportDataMap[volunteerId]!;

            if (isWithdrawal) {
              reportData.totalFundAmount -= amount;
            } else {
              reportData.fundCount++; // Increment count of contributions
              reportData.fundAmount += amount;
              reportData.totalFundAmount += amount;
            }

            if (month != null) {
              reportData.monthsParticipated.add(month);
            }
          }
        }
      } catch (e) {
        print('No funds collection or error: $e');
      }

      // Filter out volunteers with no fund activity
      return reportDataMap.values
          .where((data) => data.fundCount > 0 || data.totalFundAmount != 0)
          .toList();
    } catch (e) {
      print('Error generating fund report: $e');
      return [];
    }
  }

  // Get Marketing report (الدعايا) - fetches from marketing collection
  Future<List<VolunteerReportData>> getMarketingReportData({
    ReportFilter? filter,
  }) async {
    try {
      final volunteers = await getAllVolunteers();

      Map<String, VolunteerReportData> reportDataMap = {};

      for (var volunteer in volunteers) {
        if (filter?.volunteerName != null &&
            !volunteer.name.contains(filter!.volunteerName!)) {
          continue;
        }
        if (filter?.educationalLevel != null &&
            volunteer.educationalLevel != filter!.educationalLevel) {
          continue;
        }

        reportDataMap[volunteer.id] = VolunteerReportData(
          volunteerId: volunteer.id,
          volunteerName: volunteer.name,
          educationalLevel: volunteer.educationalLevel,
          committeeName: volunteer.committeeName,
        );
      }

      // Get marketing data from marketing collection
      try {
        final marketingSnapshot = await _firestore
            .collection('marketing')
            .get();

        for (var doc in marketingSnapshot.docs) {
          final data = doc.data();
          final volunteerId = data['volunteerId'] as String?;
          final month = data['month'] as int?;
          final year = data['year'] as int?;

          if (volunteerId != null && reportDataMap.containsKey(volunteerId)) {
            // Apply date filter
            if (filter?.month != null && month != filter!.month) continue;
            if (filter?.year != null && year != filter!.year) continue;

            var reportData = reportDataMap[volunteerId]!;
            reportData.storyCount++;
            if (month != null) {
              reportData.monthsParticipated.add(month);
            }
          }
        }
      } catch (e) {
        print('No marketing collection or error: $e');
      }

      // Filter out volunteers with no marketing activity
      return reportDataMap.values.where((data) => data.storyCount > 0).toList();
    } catch (e) {
      print('Error generating marketing report: $e');
      return [];
    }
  }

  // Get total fund amount
  Future<double> getTotalFundAmount({int? month, int? year}) async {
    try {
      final fundsSnapshot = await _firestore.collection('funds').get();
      double total = 0;

      for (var doc in fundsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final docMonth = data['month'] as int?;
        final docYear = data['year'] as int?;
        final isWithdrawal = data['isWithdrawal'] ?? false;

        if (month != null && docMonth != month) continue;
        if (year != null && docYear != year) continue;

        if (isWithdrawal) {
          total -= amount;
        } else {
          total += amount;
        }
      }

      return total;
    } catch (e) {
      print('Error getting total fund: $e');
      return 0;
    }
  }
}
