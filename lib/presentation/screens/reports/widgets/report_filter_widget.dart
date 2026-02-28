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
  final Function(
    String? name,
    List<String>? levels,
    String? committeeId,
    List<int>? months,
  )
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
  List<String> _selectedLevels = [];
  String? _selectedCommitteeId;
  List<int> _selectedMonths = [];
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
      _selectedLevels.isEmpty ? null : _selectedLevels,
      _selectedCommitteeId,
      _selectedMonths.isEmpty ? null : _selectedMonths,
    );
  }

  void _showMonthSelectionDialog() {
    // Create a temporary copy of selected months for the dialog
    List<int> tempSelectedMonths = List.from(_selectedMonths);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'اختر الشهور',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Select All / Deselect All
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempSelectedMonths = List.generate(
                                12,
                                (i) => i + 1,
                              );
                            });
                          },
                          child: const Text(
                            'تحديد الكل',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempSelectedMonths.clear();
                            });
                          },
                          child: const Text(
                            'إلغاء الكل',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    // Month checkboxes
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final monthNum = index + 1;
                          final isSelected = tempSelectedMonths.contains(
                            monthNum,
                          );
                          return CheckboxListTile(
                            title: Text(
                              ReportRepository.arabicMonths[index],
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            value: isSelected,
                            activeColor: AppTheme.primary,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  tempSelectedMonths.add(monthNum);
                                } else {
                                  tempSelectedMonths.remove(monthNum);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Cairo', color: AppTheme.secondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMonths = tempSelectedMonths;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  child: const Text(
                    'تطبيق',
                    style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textLight),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLevelSelectionDialog() {
    List<String> tempSelectedLevels = List.from(_selectedLevels);
    final allLevels = FirebaseConstants.educationalLevels;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'اختر التصنيفات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempSelectedLevels = List.from(allLevels);
                            });
                          },
                          child: const Text(
                            'تحديد الكل',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempSelectedLevels.clear();
                            });
                          },
                          child: const Text(
                            'إلغاء الكل',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allLevels.length,
                        itemBuilder: (context, index) {
                          final level = allLevels[index];
                          final isSelected = tempSelectedLevels.contains(level);
                          return CheckboxListTile(
                            title: Text(
                              level,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            value: isSelected,
                            activeColor: AppTheme.primary,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  tempSelectedLevels.add(level);
                                } else {
                                  tempSelectedLevels.remove(level);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Cairo', color: AppTheme.secondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedLevels = tempSelectedLevels;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  child: const Text(
                    'تطبيق',
                    style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textLight),
                  ),
                ),
              ],
            );
          },
        );
      },
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
              fillColor: AppTheme.cardBackground,
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
            // Month multi-select button
            Expanded(
              child: GestureDetector(
                onTap: _showMonthSelectionDialog,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: AppTheme.primary),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedMonths.isEmpty
                              ? 'كل الشهور'
                              : _selectedMonths.length == 12
                              ? 'كل الشهور'
                              : '${_selectedMonths.length} شهور',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: _selectedMonths.isEmpty
                                ? Colors.grey
                                : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        _selectedMonths.isEmpty
                            ? Icons.arrow_drop_down
                            : Icons.check_circle,
                        color: _selectedMonths.isEmpty
                            ? Colors.grey
                            : AppTheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Level multi-select button
            if (widget.showLevelFilter)
              Expanded(
                child: GestureDetector(
                  onTap: _showLevelSelectionDialog,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppTheme.primary),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedLevels.isEmpty
                                ? 'كل التصنيفات'
                                : _selectedLevels.length ==
                                      FirebaseConstants.educationalLevels.length
                                ? 'كل التصنيفات'
                                : '${_selectedLevels.length} تصنيفات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: _selectedLevels.isEmpty
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          _selectedLevels.isEmpty
                              ? Icons.arrow_drop_down
                              : Icons.check_circle,
                          color: _selectedLevels.isEmpty
                              ? Colors.grey
                              : AppTheme.primary,
                          size: 20,
                        ),
                      ],
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
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppTheme.primary),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text(
                  'اللجنة',
                  style: TextStyle(color: AppTheme.secondary),
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
