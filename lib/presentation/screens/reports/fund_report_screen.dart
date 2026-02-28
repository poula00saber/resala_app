// ============================================
// FILE: lib/presentation/screens/reports/fund_report_screen.dart
// الصندوق - Fund Report Screen
// ============================================

import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/models/report_data_model.dart';
import '../../../services/excel_export_helper.dart';
import 'widgets/report_filter_widget.dart';
import 'widgets/report_table_widget.dart';

class FundReportScreen extends StatefulWidget {
  const FundReportScreen({super.key});

  @override
  State<FundReportScreen> createState() => _FundReportScreenState();
}

class _FundReportScreenState extends State<FundReportScreen> {
  final ReportRepository _reportRepository = ReportRepository();
  List<VolunteerReportData> _reportData = [];
  bool _isLoading = true;
  ReportFilter _filter = ReportFilter();
  double _totalFund = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    final data = await _reportRepository.getFundReportData(filter: _filter);

    final total = await _reportRepository.getTotalFundAmount(
      months: _filter.months,
      year: _filter.year,
    );

    data.sort((a, b) {
      final deg = FirebaseConstants.educationalLevelsOrder;
      final oa = deg[a.educationalLevel] ?? 0;
      final ob = deg[b.educationalLevel] ?? 0;
      if (oa != ob) return ob.compareTo(oa);
      if (a.totalFundAmount != b.totalFundAmount)
        return b.totalFundAmount.compareTo(a.totalFundAmount);
      return a.volunteerName.compareTo(b.volunteerName);
    });

    setState(() {
      _reportData = data;
      _totalFund = total;
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
      await ExcelExportHelper.exportFundReport(
        reportData: _reportData,
        totalFund: _totalFund,
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
      'الصندوق',
      'الإجمالي',
      'الشهور',
    ];

    final rows = _reportData.map((data) {
      return [
        data.volunteerName,
        data.phone ?? '-',
        data.committeeName ?? '-',
        data.educationalLevel ?? '-',
        data.fundCount.toString(), // Number of contributions
        data.totalFundAmount.toStringAsFixed(0),
        data.monthsString, // comma-separated month numbers
      ];
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            'الصندوق',
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

            // Total fund display
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppTheme.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إجمالي ما في الصندوق',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    '${_totalFund.toStringAsFixed(0)} جنيه',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primary,
                    ),
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
}
