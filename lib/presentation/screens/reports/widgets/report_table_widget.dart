// ============================================
// FILE: lib/presentation/screens/reports/widgets/report_table_widget.dart
// Reusable table widget for reports
// ============================================

import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

class ReportTableWidget extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final bool isLoading;

  const ReportTableWidget({
    super.key,
    required this.headers,
    required this.rows,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                AppTheme.primary.withOpacity(0.1),
              ),
              columnSpacing: 20,
              horizontalMargin: 16,
              columns: headers.map((header) {
                return DataColumn(
                  label: Text(
                    header,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }).toList(),
              rows: rows.isEmpty
                  ? [
                      DataRow(
                        cells: List.generate(
                          headers.length,
                          (index) => DataCell(
                            Center(
                              child: index == 0
                                  ? const Text(
                                      'لا توجد بيانات',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Colors.grey,
                                      ),
                                    )
                                  : const Text(''),
                            ),
                          ),
                        ),
                      ),
                    ]
                  : rows.map((row) {
                      return DataRow(
                        cells: row.map((cell) {
                          return DataCell(
                            Center(
                              child: Text(
                                cell,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
