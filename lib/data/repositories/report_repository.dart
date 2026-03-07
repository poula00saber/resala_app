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

  // Get events by date filter (supports multiple months)
  Future<List<EventModel>> getEventsByFilter({
    List<int>? months,
    int? year,
  }) async {
    try {
      final events = await getAllEvents();

      if ((months == null || months.isEmpty) && year == null) {
        return events;
      }

      return events.where((event) {
        try {
          final eventDate = DateTime.parse(event.date);
          bool matches = true;
          if (months != null && months.isNotEmpty) {
            matches = matches && months.contains(eventDate.month);
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
        months: filter?.months,
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
        if (filter?.educationalLevels != null &&
            filter!.educationalLevels!.isNotEmpty &&
            !filter.educationalLevels!.contains(volunteer.educationalLevel)) {
          continue;
        }

        reportDataMap[volunteer.id] = VolunteerReportData(
          volunteerId: volunteer.id,
          volunteerName: volunteer.name,
          phone: volunteer.phone,
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

          // Track unique participation dates (date part only)
          try {
            final eventDate = DateTime.parse(event.date);
            final dateOnly =
                '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';
            data.uniqueDates.add(dateOnly);
          } catch (_) {}

          // Categorize event
          switch (event.type) {
            case 'يوم عائلي':
              data.familyDayCount++;
              break;
            case 'اجتماع':
              if (event.administrativeType == 'اجتماع ليدרات') {
                data.leadersMeetingCount++;
              } else if (event.committeeName != null &&
                  event.committeeName!.isNotEmpty) {
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
        months: filter?.months,
        year: filter?.year,
      );

      Map<String, VolunteerReportData> reportDataMap = {};

      // Filter volunteers
      for (var volunteer in volunteers) {
        if (filter?.volunteerName != null &&
            !volunteer.name.contains(filter!.volunteerName!)) {
          continue;
        }
        if (filter?.educationalLevels != null &&
            filter!.educationalLevels!.isNotEmpty &&
            !filter.educationalLevels!.contains(volunteer.educationalLevel)) {
          continue;
        }

        // Filter cubs vs non-cubs
        bool isCub =
            volunteer.educationalLevel == 'شبل' ||
            volunteer.educationalLevel == 'شبل مميز';
        if (cubsOnly && !isCub) continue;
        if (!cubsOnly && isCub) continue;
        // When showing الفريق (non-cubs), also exclude جدد
        if (!cubsOnly && volunteer.educationalLevel == 'جدد') continue;

        reportDataMap[volunteer.id] = VolunteerReportData(
          volunteerId: volunteer.id,
          volunteerName: volunteer.name,
          phone: volunteer.phone,
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
        months: filter?.months,
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
        if (filter?.educationalLevels != null &&
            filter!.educationalLevels!.isNotEmpty &&
            !filter.educationalLevels!.contains(volunteer.educationalLevel)) {
          continue;
        }

        reportDataMap[volunteer.id] = VolunteerReportData(
          volunteerId: volunteer.id,
          volunteerName: volunteer.name,
          phone: volunteer.phone,
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
        months: filter?.months,
        year: filter?.year,
      );

      Map<String, VolunteerReportData> reportDataMap = {};

      // Filter volunteers
      for (var volunteer in volunteers) {
        if (filter?.volunteerName != null &&
            !volunteer.name.contains(filter!.volunteerName!)) {
          continue;
        }
        if (filter?.educationalLevels != null &&
            filter!.educationalLevels!.isNotEmpty &&
            !filter.educationalLevels!.contains(volunteer.educationalLevel)) {
          continue;
        }
        if (filter?.committeeId != null &&
            volunteer.committeeId != filter!.committeeId) {
          continue;
        }

        reportDataMap[volunteer.id] = VolunteerReportData(
          volunteerId: volunteer.id,
          volunteerName: volunteer.name,
          phone: volunteer.phone,
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
        if (filter?.educationalLevels != null &&
            filter!.educationalLevels!.isNotEmpty &&
            !filter.educationalLevels!.contains(volunteer.educationalLevel)) {
          continue;
        }
        // Exclude جدد and شبل from fund report
        if (volunteer.educationalLevel == 'جدد' ||
            volunteer.educationalLevel == 'شبل') {
          continue;
        }

        reportDataMap[volunteer.id] = VolunteerReportData(
          volunteerId: volunteer.id,
          volunteerName: volunteer.name,
          phone: volunteer.phone,
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
            if (filter?.months != null &&
                filter!.months!.isNotEmpty &&
                (month == null || !filter.months!.contains(month)))
              continue;
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
        if (filter?.educationalLevels != null &&
            filter!.educationalLevels!.isNotEmpty &&
            !filter.educationalLevels!.contains(volunteer.educationalLevel)) {
          continue;
        }
        // Exclude جدد and شبل from marketing report
        if (volunteer.educationalLevel == 'جدد' ||
            volunteer.educationalLevel == 'شبل') {
          continue;
        }

        reportDataMap[volunteer.id] = VolunteerReportData(
          volunteerId: volunteer.id,
          volunteerName: volunteer.name,
          phone: volunteer.phone,
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
            if (filter?.months != null &&
                filter!.months!.isNotEmpty &&
                (month == null || !filter.months!.contains(month)))
              continue;
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
  Future<double> getTotalFundAmount({List<int>? months, int? year}) async {
    try {
      final fundsSnapshot = await _firestore.collection('funds').get();
      double total = 0;

      for (var doc in fundsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final docMonth = data['month'] as int?;
        final docYear = data['year'] as int?;
        final isWithdrawal = data['isWithdrawal'] ?? false;

        if (months != null &&
            months.isNotEmpty &&
            (docMonth == null || !months.contains(docMonth)))
          continue;
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

  // Get monthly report statistics
  Future<MonthlyReportStats> getMonthlyReportStats({
    required int month,
    required int year,
  }) async {
    try {
      final volunteers = await getAllVolunteers();
      final events = await getEventsByFilter(months: [month], year: year);

      // Categorize volunteers by level
      final masoolVolunteers = volunteers
          .where((v) => v.educationalLevel == 'مسئول')
          .toList();
      final mashroVolunteers = volunteers
          .where((v) => v.educationalLevel == 'مشروع مسئول')
          .toList();
      final gododVolunteers = volunteers
          .where((v) => v.educationalLevel == 'جدد')
          .toList();

      // Track who participated
      final Set<String> allParticipantIds = {};
      final Set<String> masoolParticipantIds = {};
      final Set<String> mashroParticipantIds = {};
      final Set<String> gododParticipantIds = {};
      int tshirtCount = 0;
      int leadersMeetingCount = 0;
      int teamMeetingCount = 0;
      final Map<String, int> committeeMeetingCounts = {};

      // Track per-volunteer participation count (capped at 8)
      final Map<String, int> masoolParticipationCount = {};
      final Map<String, int> mashroParticipationCount = {};

      for (var event in events) {
        // Count meetings
        if (event.type == 'اجتماع') {
          if (event.administrativeType == 'اجتماع ليدرات') {
            leadersMeetingCount++;
          } else if (event.committeeName != null &&
              event.committeeName!.isNotEmpty) {
            committeeMeetingCounts[event.committeeName!] =
                (committeeMeetingCounts[event.committeeName!] ?? 0) + 1;
          } else {
            teamMeetingCount++;
          }
        }

        // Count t-shirts
        for (var volunteerId in event.volunteerIds) {
          final volunteer = volunteers
              .where((v) => v.id == volunteerId)
              .firstOrNull;
          if (volunteer != null && (volunteer as VolunteerModel).hasTshirt) {
            tshirtCount++;
          }
        }

        // Count participants
        for (var volunteerId in event.volunteerIds) {
          allParticipantIds.add(volunteerId);

          // Check masool
          if (masoolVolunteers.any((v) => v.id == volunteerId)) {
            masoolParticipantIds.add(volunteerId);
            masoolParticipationCount[volunteerId] =
                (masoolParticipationCount[volunteerId] ?? 0) + 1;
          }
          // Check mashro
          if (mashroVolunteers.any((v) => v.id == volunteerId)) {
            mashroParticipantIds.add(volunteerId);
            mashroParticipationCount[volunteerId] =
                (mashroParticipationCount[volunteerId] ?? 0) + 1;
          }
          // Check godod
          if (gododVolunteers.any((v) => v.id == volunteerId)) {
            gododParticipantIds.add(volunteerId);
          }
        }
      }

      // Calculate participation rates (capped at 8)
      double masoolRate = 0;
      if (masoolVolunteers.isNotEmpty) {
        final totalPossible = masoolVolunteers.length * 8;
        final totalActual = masoolParticipationCount.values.fold<int>(
          0,
          (sum, count) => sum + (count > 8 ? 8 : count),
        );
        masoolRate = (totalActual / totalPossible) * 100;
      }

      double mashroRate = 0;
      if (mashroVolunteers.isNotEmpty) {
        final totalPossible = mashroVolunteers.length * 8;
        final totalActual = mashroParticipationCount.values.fold<int>(
          0,
          (sum, count) => sum + (count > 8 ? 8 : count),
        );
        mashroRate = (totalActual / totalPossible) * 100;
      }

      // Build non-participant lists
      VolunteerReportData _toReportData(VolunteerModel v) {
        return VolunteerReportData(
          volunteerId: v.id,
          volunteerName: v.name,
          phone: v.phone,
          educationalLevel: v.educationalLevel,
          committeeName: v.committeeName,
          committeeId: v.committeeId,
        );
      }

      final masoolNonParticipants = masoolVolunteers
          .where((v) => !masoolParticipantIds.contains(v.id))
          .map((v) => _toReportData(v as VolunteerModel))
          .toList();

      final mashroNonParticipants = mashroVolunteers
          .where((v) => !mashroParticipantIds.contains(v.id))
          .map((v) => _toReportData(v as VolunteerModel))
          .toList();

      return MonthlyReportStats(
        masoolParticipantCount: masoolParticipantIds.length,
        mashroParticipantCount: mashroParticipantIds.length,
        gododCount: gododParticipantIds.length,
        tshirtCount: tshirtCount,
        eventCount: events.where((e) => e.type != 'اجتماع').length,
        masoolParticipationRate: masoolRate,
        mashroParticipationRate: mashroRate,
        leadersMeetingCount: leadersMeetingCount,
        teamMeetingCount: teamMeetingCount,
        committeeMeetingCounts: committeeMeetingCounts,
        masoolNonParticipants: masoolNonParticipants,
        mashroNonParticipants: mashroNonParticipants,
      );
    } catch (e) {
      print('Error generating monthly report: $e');
      return MonthlyReportStats(
        masoolParticipantCount: 0,
        mashroParticipantCount: 0,
        gododCount: 0,
        tshirtCount: 0,
        eventCount: 0,
        masoolParticipationRate: 0,
        mashroParticipationRate: 0,
        leadersMeetingCount: 0,
        teamMeetingCount: 0,
        committeeMeetingCounts: {},
        masoolNonParticipants: [],
        mashroNonParticipants: [],
      );
    }
  }
}
