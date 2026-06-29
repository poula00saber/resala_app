import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../themes/app_theme.dart';
import '../reports/widgets/report_table_widget.dart';
import '../../providers/event_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../../data/models/event_model.dart';

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
                          'التاريخ',
                          'المكان',
                          'عدد المتطوعين',
                          'التيشرتات',
                          'تفاصيل الوجبات',
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

      rows.add([
        event.date,
        event.location ?? '-',
        event.volunteerIds.length.toString(),
        tshirtCount.toString(),
        details,
      ]);
    }

    return rows;
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
