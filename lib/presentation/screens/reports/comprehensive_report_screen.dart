// ============================================
// FILE: lib/presentation/screens/reports/comprehensive_report_screen.dart
// الكلي - Comprehensive Report Screen
// ============================================

import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/models/report_data_model.dart';
import '../../../services/excel_export_helper.dart';
import 'widgets/report_filter_widget.dart';
import 'widgets/report_table_widget.dart';

class ComprehensiveReportScreen extends StatefulWidget {
  const ComprehensiveReportScreen({super.key});

  @override
  State<ComprehensiveReportScreen> createState() =>
      _ComprehensiveReportScreenState();
}

class _ComprehensiveReportScreenState extends State<ComprehensiveReportScreen> {
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

    final data = await _reportRepository.getComprehensiveReportData(
      filter: _filter,
    );

    data.sort((a, b) {
      final deg = FirebaseConstants.educationalLevelsOrder;
      final oa = deg[a.educationalLevel] ?? 0;
      final ob = deg[b.educationalLevel] ?? 0;
      if (oa != ob) return ob.compareTo(oa);
      if (a.totalEvents != b.totalEvents)
        return b.totalEvents.compareTo(a.totalEvents);
      return a.volunteerName.compareTo(b.volunteerName);
    });

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
      await ExcelExportHelper.exportComprehensiveReport(
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
      'الهاتف',
      'اللجنة',
      'الدرجة التطوعية',
      'الشهور',
      'اجتماع لجنة',
      'يوم عائلي',
      'اجتماع فريق',
      'احداث',
      'اكشنز',
      'مشاركات',
    ];

    final rows = _reportData.map((data) {
      return [
        data.volunteerName,
        data.phone ?? '-',
        data.committeeName ?? '-',
        data.educationalLevel ?? '-',
        data.monthsString,
        data.committeeMeetingCount.toString(),
        data.familyDayCount.toString(),
        (data.leadersMeetingCount + data.teamMeetingCount).toString(),
        data.eventsCount.toString(),
        data.totalEvents.toString(),
        data.participationDays.toString(),
      ];
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            'الكلي',
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
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textDark),
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
              showCommitteeFilter: false,
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
