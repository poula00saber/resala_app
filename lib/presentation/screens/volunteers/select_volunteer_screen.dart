// ============================================
// FILE: lib/presentation/screens/volunteers/select_volunteer_screen.dart
// UPDATED: Supports multi-select via long press + tap to toggle
// Single tap selects one (returns String), long press enables multi-select (returns List<String>)
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/firebase_constants.dart';

class SelectVolunteerScreen extends StatefulWidget {
  const SelectVolunteerScreen({super.key});

  @override
  State<SelectVolunteerScreen> createState() => _SelectVolunteerScreenState();
}

class _SelectVolunteerScreenState extends State<SelectVolunteerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isMultiSelectMode = false;
  final Set<String> _selectedIds = {};

  void _toggleMultiSelect(String volunteerId) {
    setState(() {
      if (_selectedIds.contains(volunteerId)) {
        _selectedIds.remove(volunteerId);
        if (_selectedIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedIds.add(volunteerId);
      }
    });
  }

  void _confirmMultiSelect() {
    if (_selectedIds.isNotEmpty) {
      Navigator.pop(context, _selectedIds.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8DDD3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8DDD3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isMultiSelectMode
              ? 'تم اختيار ${_selectedIds.length}'
              : 'اختيار متطوع حالي',
          style: const TextStyle(
            color: AppTheme.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isMultiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textDark),
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = false;
                  _selectedIds.clear();
                });
              },
            ),
          ],
        ],
      ),
      floatingActionButton: _isMultiSelectMode && _selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _confirmMultiSelect,
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.check, color: AppTheme.textLight),
              label: Text(
                'تأكيد (${_selectedIds.length})',
                style: const TextStyle(
                  color: AppTheme.cardBackground,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          const SizedBox(height: 8),
          if (_isMultiSelectMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 4),
              child: Text(
                'اضغط لتحديد أو إلغاء تحديد المتطوعين',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppTheme.secondary,
                ),
              ),
            ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: _searchController,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: 'بحث',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: AppTheme.secondary),
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder(
                      stream: Provider.of<VolunteerProvider>(
                        context,
                        listen: false,
                      ).searchVolunteers(_searchQuery),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'حدث خطأ: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        var volunteers = snapshot.data ?? [];

                        // Sort by degree then name
                        volunteers.sort(
                          (a, b) => FirebaseConstants.compareByDegreeAndName(
                            a.educationalLevel ?? '',
                            a.name,
                            b.educationalLevel ?? '',
                            b.name,
                          ),
                        );

                        if (volunteers.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا توجد نتائج',
                              style: TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: volunteers.length,
                          itemBuilder: (context, index) {
                            final volunteer = volunteers[index];
                            final isSelected = _selectedIds.contains(
                              volunteer.id,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_isMultiSelectMode) {
                                    _toggleMultiSelect(volunteer.id);
                                  } else {
                                    // Single select - return single ID
                                    Navigator.pop(context, volunteer.id);
                                  }
                                },
                                onLongPress: () {
                                  if (!_isMultiSelectMode) {
                                    setState(() {
                                      _isMultiSelectMode = true;
                                      _selectedIds.add(volunteer.id);
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? AppTheme.primary.withOpacity(0.8)
                                      : AppTheme.primary,
                                  foregroundColor: AppTheme.textLight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    side: isSelected
                                        ? const BorderSide(
                                            color: AppTheme.cardBackground,
                                            width: 2,
                                          )
                                        : BorderSide.none,
                                  ),
                                  elevation: isSelected ? 4 : 2,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (_isMultiSelectMode)
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: AppTheme.cardBackground,
                                        size: 22,
                                      ),
                                    if (_isMultiSelectMode)
                                      const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            volunteer.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                          Text(
                                            volunteer.educationalLevel ?? '-',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        size: 24,
                                        color: AppTheme.cardBackground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
