// ============================================
// FILE: lib/presentation/screens/reports/widgets/report_table_widget.dart
// Reusable table widget for reports
// ============================================

import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/whale_loading.dart';

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: WhaleLoading(),
        ),
      );
    }

    final indexedHeaders = ['#', ...headers];
    final indexedRows = rows.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;
      return [(index + 1).toString(), ...row];
    }).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
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
              columns: indexedHeaders.map((header) {
                return DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text(
                        header,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.primary,
                        ),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
              rows: indexedRows.isEmpty
                  ? [
                      DataRow(
                        cells: List.generate(
                          indexedHeaders.length,
                          (index) => DataCell(
                            Center(
                              child: index == 0
                                  ? const Text(
                                      'لا توجد بيانات',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: AppTheme.secondary,
                                      ),
                                    )
                                  : const Text(''),
                            ),
                          ),
                        ),
                      ),
                    ]
                  : indexedRows.map((row) {
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
