// ============================================
// FILE: lib/presentation/screens/reports/cubs_report_screen.dart
// الأشبال - Cubs Report Screen
// ============================================

import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/models/report_data_model.dart';
import '../../../services/excel_export_helper.dart';
import 'widgets/report_filter_widget.dart';
import 'widgets/report_table_widget.dart';

class CubsReportScreen extends StatefulWidget {
  const CubsReportScreen({super.key});

  @override
  State<CubsReportScreen> createState() => _CubsReportScreenState();
}

class _CubsReportScreenState extends State<CubsReportScreen> {
  final ReportRepository _reportRepository = ReportRepository();
  List<VolunteerReportData> _reportData = [];
  bool _isLoading = true;
  ReportFilter _filter = ReportFilter();
  String _selectedCategory = 'الاحداث'; // Default category

  final List<String> _categories = ['الاحداث', 'اليوم العائلي'];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    final data = await _reportRepository.getCubsReportData(
      filter: _filter,
      eventCategory: _selectedCategory,
    );

    data.sort((a, b) {
      final deg = FirebaseConstants.educationalLevelsOrder;
      final oa = deg[a.educationalLevel] ?? 0;
      final ob = deg[b.educationalLevel] ?? 0;
      if (oa != ob) return ob.compareTo(oa);
      if (a.cubsEventCount != b.cubsEventCount)
        return b.cubsEventCount.compareTo(a.cubsEventCount);
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
      await ExcelExportHelper.exportCubsReport(
        reportData: _reportData,
        category: _selectedCategory,
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
      'ايفنت الأشبال',
      'الأحداث',
      'الشهور',
    ];

    final rows = _reportData.map((data) {
      return [
        data.volunteerName,
        data.phone ?? '-',
        data.committeeName ?? '-',
        data.educationalLevel ?? '-',
        data.familyDayCount.toString(),
        data.cubsEventCount.toString(),
        data.eventsCount.toString(),
        data.monthsString, // comma-separated month numbers
      ];
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            'الأشبال',
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

            // Category toggle buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildToggleButton(
                      title: category,
                      isSelected: _selectedCategory == category,
                      onTap: () {
                        setState(() => _selectedCategory = category);
                        _loadReportData();
                      },
                    ),
                  );
                }).toList(),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            fontSize: 13,
            color: isSelected ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}
