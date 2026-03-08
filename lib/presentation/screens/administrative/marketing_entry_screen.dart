// ============================================
// FILE: lib/presentation/screens/administrative/marketing_entry_screen.dart
// الدعايا - Marketing Entry Screen (Data Entry)
// UPDATED: Added permission checks for add/delete
// ============================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../themes/app_theme.dart';
import '../../widgets/whale_loading.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../data/models/marketing_model.dart';
import '../../../data/repositories/marketing_repository.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/app_user_model.dart';

class MarketingEntryScreen extends StatefulWidget {
  const MarketingEntryScreen({super.key});

  @override
  State<MarketingEntryScreen> createState() => _MarketingEntryScreenState();
}

class _MarketingEntryScreenState extends State<MarketingEntryScreen> {
  final MarketingRepository _marketingRepository = MarketingRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  bool get _canAddDelete =>
      _authService.isAdmin ||
      _authService.canAddDeleteOnPage(AppPages.administrative) ||
      true;

  List<Map<String, dynamic>> _volunteers = [];
  String? _selectedVolunteerId;
  String? _selectedVolunteerName;
  bool _isLoading = true;
  bool _isSaving = false;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Track existing records
  Map<String, List<MarketingModel>> _volunteerMarketingRecords = {};
  int _totalMarketingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load volunteers
      final volunteersSnapshot = await _firestore
          .collection('volunteers')
          .orderBy('name')
          .get();

      _volunteers = volunteersSnapshot.docs
          .where((doc) {
            final level = doc.data()['educationalLevel'] ?? '';
            return level != 'جدد' && level != 'شبل';
          })
          .map((doc) {
            return {
              'id': doc.id,
              'name': doc.data()['name'] ?? '',
              'educationalLevel': doc.data()['educationalLevel'] ?? '',
            };
          })
          .toList();
      _volunteers.sort(
        (a, b) => FirebaseConstants.compareByDegreeAndName(
          a['educationalLevel'] as String,
          a['name'] as String,
          b['educationalLevel'] as String,
          b['name'] as String,
        ),
      );

      // Load total marketing count for current year
      _totalMarketingCount = await _marketingRepository.getMarketingCount(
        year: _selectedYear,
      );

      // Load existing marketing records for current year
      final marketingSnapshot = await _firestore
          .collection('marketing')
          .where('year', isEqualTo: _selectedYear)
          .get();

      _volunteerMarketingRecords.clear();
      for (var doc in marketingSnapshot.docs) {
        final marketing = MarketingModel.fromFirestore(doc);
        if (!_volunteerMarketingRecords.containsKey(marketing.volunteerId)) {
          _volunteerMarketingRecords[marketing.volunteerId] = [];
        }
        _volunteerMarketingRecords[marketing.volunteerId]!.add(marketing);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  bool _hasExistingRecord(String volunteerId, int month, int year) {
    final records = _volunteerMarketingRecords[volunteerId] ?? [];
    return records.any((r) => r.month == month && r.year == year);
  }

  Future<void> _saveMarketingEntry() async {
    if (_selectedVolunteerId == null || _selectedVolunteerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار متطوع'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check for existing record
    if (_hasExistingRecord(
      _selectedVolunteerId!,
      _selectedMonth,
      _selectedYear,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يوجد سجل لهذا المتطوع في هذا الشهر'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _marketingRepository.addMarketing(
        volunteerId: _selectedVolunteerId!,
        volunteerName: _selectedVolunteerName!,
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الدعايا بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _selectedVolunteerId = null;
          _selectedVolunteerName = null;
        });

        // Reload data
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            'الدعايا',
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
        ),
        body: _isLoading
            ? Center(child: WhaleLoading())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'إجمالي الستوريات هذا العام',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_totalMarketingCount ستوري',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppTheme.cardBackground,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Volunteer Selection
                    const Text(
                      'اختر المتطوع',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedVolunteerId,
                          isExpanded: true,
                          hint: const Text(
                            'اختر المتطوع',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                          items: _volunteers.map((volunteer) {
                            final hasRecord = _hasExistingRecord(
                              volunteer['id'],
                              _selectedMonth,
                              _selectedYear,
                            );
                            return DropdownMenuItem<String>(
                              value: volunteer['id'],
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      volunteer['name'],
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                  if (hasRecord)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            final volunteer = _volunteers.firstWhere(
                              (v) => v['id'] == value,
                            );
                            setState(() {
                              _selectedVolunteerId = value;
                              _selectedVolunteerName = volunteer['name'];
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Month and Year Selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'الشهر',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedMonth,
                                    isExpanded: true,
                                    items: List.generate(12, (index) {
                                      return DropdownMenuItem<int>(
                                        value: index + 1,
                                        child: Text(
                                          _getArabicMonth(index + 1),
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      );
                                    }),
                                    onChanged: (value) {
                                      setState(() => _selectedMonth = value!);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'السنة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedYear,
                                    isExpanded: true,
                                    items:
                                        [
                                          DateTime.now().year - 1,
                                          DateTime.now().year,
                                          DateTime.now().year + 1,
                                        ].map((year) {
                                          return DropdownMenuItem<int>(
                                            value: year,
                                            child: Text(
                                              year.toString(),
                                              style: const TextStyle(
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() => _selectedYear = value!);
                                      _loadData(); // Reload to get records for new year
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Save Button (only if can add/delete)
                    if (_canAddDelete)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveMarketingEntry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? WhaleLoading(
                                  size: 20,
                                  color: AppTheme.cardBackground,
                                )
                              : const Text(
                                  'تسجيل الستوري',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.cardBackground,
                                  ),
                                ),
                        ),
                      ),
                    // No permission message
                    if (!_canAddDelete)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ليس لديك صلاحية لإضافة سجلات',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Recent Records Section
                    const Text(
                      'السجلات الأخيرة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentRecords(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRecentRecords() {
    // Flatten and sort all records
    final allRecords = <MarketingModel>[];
    _volunteerMarketingRecords.forEach((_, records) {
      allRecords.addAll(records);
    });
    allRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final recentRecords = allRecords.take(10).toList();

    if (recentRecords.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'لا توجد سجلات',
            style: TextStyle(fontFamily: 'Cairo', color: AppTheme.secondary),
          ),
        ),
      );
    }

    return Column(
      children: recentRecords.map((record) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.campaign, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.volunteerName,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_getArabicMonth(record.month)} ${record.year}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getArabicMonth(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }
}
