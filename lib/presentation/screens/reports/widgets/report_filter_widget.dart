// ============================================
// FILE: lib/presentation/screens/reports/widgets/report_filter_widget.dart
// Reusable filter widget for reports
// ============================================

import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../data/repositories/committee_repository.dart';
import '../../../../data/models/committee_model.dart';
import '../../../../data/repositories/report_repository.dart';

class ReportFilterWidget extends StatefulWidget {
  final Function(String? name, String? level, String? committeeId, int? month)
  onFilterChanged;
  final bool showCommitteeFilter;
  final bool showLevelFilter;

  const ReportFilterWidget({
    super.key,
    required this.onFilterChanged,
    this.showCommitteeFilter = false,
    this.showLevelFilter = true,
  });

  @override
  State<ReportFilterWidget> createState() => _ReportFilterWidgetState();
}

class _ReportFilterWidgetState extends State<ReportFilterWidget> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedLevel;
  String? _selectedCommitteeId;
  int? _selectedMonth;
  List<CommitteeModel> _committees = [];

  @override
  void initState() {
    super.initState();
    if (widget.showCommitteeFilter) {
      _loadCommittees();
    }
  }

  Future<void> _loadCommittees() async {
    final committeeRepo = CommitteeRepository();
    committeeRepo.getActiveCommittees().listen((committees) {
      if (mounted) {
        setState(() {
          _committees = committees;
        });
      }
    });
  }

  void _applyFilters() {
    widget.onFilterChanged(
      _nameController.text.isEmpty ? null : _nameController.text,
      _selectedLevel,
      _selectedCommitteeId,
      _selectedMonth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Name filter
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _nameController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'الاسم',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            onChanged: (_) => _applyFilters(),
          ),
        ),

        // Level and Month dropdowns
        Row(
          children: [
            // Month dropdown
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppTheme.primary),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    hint: const Text(
                      'الشهور',
                      style: TextStyle(color: Colors.grey),
                    ),
                    value: _selectedMonth,
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('كل الشهور'),
                      ),
                      ...List.generate(12, (index) {
                        return DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text(ReportRepository.arabicMonths[index]),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
              ),
            ),

            // Level dropdown
            if (widget.showLevelFilter)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: AppTheme.primary),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text(
                        'التصنيف',
                        style: TextStyle(color: Colors.grey),
                      ),
                      value: _selectedLevel,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('الكل'),
                        ),
                        ...FirebaseConstants.educationalLevels.map((level) {
                          return DropdownMenuItem<String>(
                            value: level,
                            child: Text(level),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLevel = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Committee dropdown (if needed)
        if (widget.showCommitteeFilter)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppTheme.primary),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text(
                  'اللجنة',
                  style: TextStyle(color: Colors.grey),
                ),
                value: _selectedCommitteeId,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('كل اللجان'),
                  ),
                  ..._committees.map((committee) {
                    return DropdownMenuItem<String>(
                      value: committee.id,
                      child: Text(committee.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCommitteeId = value;
                  });
                  _applyFilters();
                },
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
