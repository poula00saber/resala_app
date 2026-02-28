// ============================================
// FILE: lib/presentation/screens/reports/family_day_report_screen.dart
// اليوم العائلي - Family Day Report Screen
// ============================================

import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/models/report_data_model.dart';
import '../../../services/excel_export_helper.dart';
import 'widgets/report_filter_widget.dart';
import 'widgets/report_table_widget.dart';

class FamilyDayReportScreen extends StatefulWidget {
  const FamilyDayReportScreen({super.key});

  @override
  State<FamilyDayReportScreen> createState() => _FamilyDayReportScreenState();
}

class _FamilyDayReportScreenState extends State<FamilyDayReportScreen> {
  final ReportRepository _reportRepository = ReportRepository();
  List<VolunteerReportData> _reportData = [];
  bool _isLoading = true;
  ReportFilter _filter = ReportFilter();
  bool _showCubsOnly = false; // false = الفريق, true = الأشبال

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    final data = await _reportRepository.getFamilyDayReportData(
      filter: _filter,
      cubsOnly: _showCubsOnly,
    );

    data.sort((a, b) {
      final deg = FirebaseConstants.educationalLevelsOrder;
      final oa = deg[a.educationalLevel] ?? 0;
      final ob = deg[b.educationalLevel] ?? 0;
      if (oa != ob) return ob.compareTo(oa);
      if (a.familyDayCount != b.familyDayCount)
        return b.familyDayCount.compareTo(a.familyDayCount);
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
      await ExcelExportHelper.exportFamilyDayReport(
        reportData: _reportData,
        isCubs: _showCubsOnly,
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
      'يوم عائلي',
      'الشهور',
    ];

    final rows = _reportData.map((data) {
      return [
        data.volunteerName,
        data.phone ?? '-',
        data.committeeName ?? '-',
        data.educationalLevel ?? '-',
        data.familyDayCount.toString(),
        data.monthsString, // comma-separated month numbers
      ];
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            'اليوم العائلي',
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
              showCommitteeFilter: false,
              showLevelFilter: true,
            ),

            // Toggle buttons for Cubs vs Team
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToggleButton(
                    title: 'الأشبال',
                    isSelected: _showCubsOnly,
                    onTap: () {
                      setState(() => _showCubsOnly = true);
                      _loadReportData();
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildToggleButton(
                    title: 'الفريق',
                    isSelected: !_showCubsOnly,
                    onTap: () {
                      setState(() => _showCubsOnly = false);
                      _loadReportData();
                    },
                  ),
                ],
              ),
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

  Widget _buildToggleButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppTheme.primary),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}
