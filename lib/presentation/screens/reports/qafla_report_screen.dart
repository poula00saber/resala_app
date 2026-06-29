import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../themes/app_theme.dart';
import '../reports/widgets/report_table_widget.dart';
import '../../providers/event_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../../data/models/event_model.dart';
import '../../../services/excel_export_helper.dart';

class QaflaReportScreen extends StatefulWidget {
  const QaflaReportScreen({super.key});

  @override
  State<QaflaReportScreen> createState() => _QaflaReportScreenState();
}

class _QaflaReportScreenState extends State<QaflaReportScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          title: const Text(
            'تقرير القوافل',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: AppTheme.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download, color: AppTheme.primary),
              onPressed: () async {
                final eventProvider = Provider.of<EventProvider>(
                  context,
                  listen: false,
                );
                final volunteerProvider = Provider.of<VolunteerProvider>(
                  context,
                  listen: false,
                );
                final rows = await _buildRows(
                  eventProvider.getQaflaEvents(),
                  volunteerProvider,
                );
                await ExcelExportHelper.exportQaflaReport(rows: rows);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تصدير تقرير القوافل بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              tooltip: 'تصدير إلى Excel',
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'البيانات المسبقة من الحدث تظهر أولاً، وآخر عمود يضم تفاصيل الوجبات.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppTheme.secondary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer2<EventProvider, VolunteerProvider>(
                builder: (context, eventProvider, volunteerProvider, _) {
                  final qaflaEvents = eventProvider.getQaflaEvents();
                  final rows = <List<String>>[];

                  if (qaflaEvents.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد قوافل بعد',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AppTheme.secondary,
                        ),
                      ),
                    );
                  }

                  return FutureBuilder<List<List<String>>>(
                    future: _buildRows(qaflaEvents, volunteerProvider),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final builtRows = snapshot.data ?? rows;
                      return ReportTableWidget(
                        headers: const [
                          'العنوان',
                          'التاريخ',
                          'المكان',
                          'عدد المتطوعين',
                          'الموزعين',
                          'التيشرتات',
                          'عدد العربيات',
                          'تفاصيل الوجبات',
                          'تفاصيل العربيات',
                        ],
                        rows: builtRows,
                        isLoading: false,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<List<String>>> _buildRows(
    List<EventModel> qaflaEvents,
    VolunteerProvider volunteerProvider,
  ) async {
    final rows = <List<String>>[];

    for (final event in qaflaEvents) {
      final volunteers = await volunteerProvider.getVolunteersByIds(
        event.volunteerIds,
      );
      final tshirtCount = volunteers
          .where((volunteer) => volunteer.hasTshirt)
          .length;
      final details = _extractMealDetails(event.additionalDetails);
      final carCount = _extractCarCount(event.additionalDetails);
      final carDetails = _extractCarDetails(event.additionalDetails);
      final distributedCount = event.qaflaDistribution.values
          .where((value) => value)
          .length;

      rows.add([
        event.title,
        event.date,
        event.location ?? '-',
        event.volunteerIds.length.toString(),
        distributedCount.toString(),
        tshirtCount.toString(),
        carCount.toString(),
        details,
        carDetails,
      ]);
    }

    return rows;
  }

  int _extractCarCount(String? additionalDetails) {
    if (additionalDetails == null || additionalDetails.isEmpty) return 0;

    try {
      final decoded = jsonDecode(additionalDetails) as Map<String, dynamic>;
      final carCount = decoded['carCount'];
      if (carCount is num) {
        return carCount.toInt();
      }
    } catch (_) {}

    return 0;
  }

  String _extractCarDetails(String? additionalDetails) {
    if (additionalDetails == null || additionalDetails.isEmpty) return '-';

    try {
      final decoded = jsonDecode(additionalDetails) as Map<String, dynamic>;
      final cars = decoded['cars'];
      if (cars is List && cars.isNotEmpty) {
        return cars
            .whereType<Map>()
            .map(
              (car) =>
                  '${car['vehicleType'] ?? ''} / ${car['driverName'] ?? ''} / ${car['carNumber'] ?? ''}',
            )
            .join(' • ');
      }
    } catch (_) {}

    return '-';
  }

  String _extractMealDetails(String? additionalDetails) {
    if (additionalDetails == null || additionalDetails.isEmpty) return '-';

    try {
      final decoded = jsonDecode(additionalDetails) as Map<String, dynamic>;
      return decoded['mealDetails']?.toString().isNotEmpty == true
          ? decoded['mealDetails'].toString()
          : '-';
    } catch (_) {
      return additionalDetails;
    }
  }
}
