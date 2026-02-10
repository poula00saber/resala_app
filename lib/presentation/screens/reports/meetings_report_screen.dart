// ============================================
// FILE: lib/presentation/screens/reports/meetings_report_screen.dart
// الأجتماعات - Meetings Report Screen
// ============================================

import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/models/report_data_model.dart';
import '../../../services/excel_export_helper.dart';
import 'widgets/report_filter_widget.dart';
import 'widgets/report_table_widget.dart';

class MeetingsReportScreen extends StatefulWidget {
  const MeetingsReportScreen({super.key});

  @override
  State<MeetingsReportScreen> createState() => _MeetingsReportScreenState();
}

class _MeetingsReportScreenState extends State<MeetingsReportScreen> {
  final ReportRepository _reportRepository = ReportRepository();
  List<VolunteerReportData> _reportData = [];
  bool _isLoading = true;
  ReportFilter _filter = ReportFilter();

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    final data = await _reportRepository.getMeetingsReportData(filter: _filter);

    setState(() {
      _reportData = data;
      _isLoading = false;
    });
  }

  void _onFilterChanged(
    String? name,
    List<String>? levels,
    String? committeeId,
    List<int>? months,
  ) {
    _filter = ReportFilter(
      volunteerName: name,
      educationalLevels: levels,
      committeeId: committeeId,
      months: months,
    );
    _loadReportData();
  }

  Future<void> _exportToExcel() async {
    try {
      await ExcelExportHelper.exportMeetingsReport(
        reportData: _reportData,
        filterMonth: _filter.months != null && _filter.months!.isNotEmpty
            ? _filter.months!
                  .map((m) => ReportRepository.getArabicMonth(m))
                  .join(', ')
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تصدير التقرير بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headers = [
      'الاسم',
      'اللجنة',
      'اجتماع اللجنة',
      'اجتماع الفريق',
      'اجتماع الليدرات',
      'الشهور',
    ];

    final rows = _reportData.map((data) {
      return [
        data.volunteerName,
        data.committeeName ?? '-',
        data.committeeMeetingCount.toString(),
        data.teamMeetingCount.toString(),
        data.leadersMeetingCount.toString(),
        data.monthsString,
      ];
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            'الأجتماعات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: AppTheme.primary,
            ),
          ),
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download, color: AppTheme.primary),
              onPressed: _exportToExcel,
              tooltip: 'تصدير إلى Excel',
            ),
          ],
        ),
        body: Column(
          children: [
            ReportFilterWidget(
              onFilterChanged: _onFilterChanged,
              showCommitteeFilter: true,
              showLevelFilter: true,
            ),

            Expanded(
              child: ReportTableWidget(
                headers: headers,
                rows: rows,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
