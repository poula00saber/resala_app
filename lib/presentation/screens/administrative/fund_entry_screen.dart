// ============================================
// FILE: lib/presentation/screens/administrative/fund_entry_screen.dart
// الصندوق - Fund Entry Screen (Data Entry)
// UPDATED: Added permission checks for add/delete
// ============================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../themes/app_theme.dart';
import '../../widgets/whale_loading.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../data/models/fund_model.dart';
import '../../../data/repositories/fund_repository.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/app_user_model.dart';

class FundEntryScreen extends StatefulWidget {
  const FundEntryScreen({super.key});

  @override
  State<FundEntryScreen> createState() => _FundEntryScreenState();
}

class _FundEntryScreenState extends State<FundEntryScreen> {
  final FundRepository _fundRepository = FundRepository();
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
  bool _showAllWithdrawals = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _withdrawReasonController =
      TextEditingController();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isWithdrawal = false;

  // Track existing records
  Map<String, List<FundModel>> _volunteerFundRecords = {};
  double _totalFundBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _withdrawReasonController.dispose();
    super.dispose();
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
            return FirebaseConstants.teamWorkLevels.contains(level);
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

      // Load total fund balance
      _totalFundBalance = await _fundRepository.getTotalFundAmount();

      // Load existing fund records for current year
      final fundsSnapshot = await _firestore
          .collection('funds')
          .where('year', isEqualTo: _selectedYear)
          .get();

      _volunteerFundRecords.clear();
      for (var doc in fundsSnapshot.docs) {
        final fund = FundModel.fromFirestore(doc);
        if (!_volunteerFundRecords.containsKey(fund.volunteerId)) {
          _volunteerFundRecords[fund.volunteerId] = [];
        }
        _volunteerFundRecords[fund.volunteerId]!.add(fund);
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
    final records = _volunteerFundRecords[volunteerId] ?? [];
    return records.any(
      (r) => r.month == month && r.year == year && !r.isWithdrawal,
    );
  }

  Future<void> _saveFundEntry() async {
    if (_selectedVolunteerId == null || _selectedVolunteerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار متطوع'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال المبلغ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال مبلغ صحيح'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isWithdrawal && _withdrawReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال سبب السحب'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check for existing record (only for deposits)
    if (!_isWithdrawal &&
        _hasExistingRecord(
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
      if (_isWithdrawal) {
        await _fundRepository.addWithdrawal(
          volunteerId: _selectedVolunteerId!,
          volunteerName: _selectedVolunteerName!,
          amount: amount,
          reason: _withdrawReasonController.text.trim(),
        );
      } else {
        await _fundRepository.addFund(
          volunteerId: _selectedVolunteerId!,
          volunteerName: _selectedVolunteerName!,
          amount: amount,
          month: _selectedMonth,
          year: _selectedYear,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isWithdrawal ? 'تم تسجيل السحب بنجاح' : 'تم تسجيل الإيداع بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        _amountController.clear();
        _withdrawReasonController.clear();
        setState(() {
          _selectedVolunteerId = null;
          _selectedVolunteerName = null;
          _isWithdrawal = false;
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
        ),
        body: _isLoading
            ? Center(child: WhaleLoading())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Balance Card
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
                            'إجمالي الصندوق',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_totalFundBalance.toStringAsFixed(0)} جنيه',
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

                    // Transaction Type Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _isWithdrawal = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: !_isWithdrawal
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(11),
                                  ),
                                ),
                                child: Text(
                                  'إيداع',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    color: !_isWithdrawal
                                        ? Colors.white
                                        : AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isWithdrawal = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _isWithdrawal
                                      ? Colors.red
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(11),
                                  ),
                                ),
                                child: Text(
                                  'سحب',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    color: _isWithdrawal
                                        ? Colors.white
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

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
                                  if (hasRecord && !_isWithdrawal)
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

                    // Month and Year Selection (only for deposits)
                    if (!_isWithdrawal) ...[
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
                      const SizedBox(height: 20),
                    ],

                    // Amount Field
                    const Text(
                      'المبلغ',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontFamily: 'Cairo'),
                        decoration: const InputDecoration(
                          hintText: 'أدخل المبلغ',
                          hintStyle: TextStyle(fontFamily: 'Cairo'),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixText: 'جنيه',
                          suffixStyle: TextStyle(
                            fontFamily: 'Cairo',
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Withdrawal Reason (only for withdrawals)
                    if (_isWithdrawal) ...[
                      const Text(
                        'سبب السحب',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _withdrawReasonController,
                          maxLines: 3,
                          style: const TextStyle(fontFamily: 'Cairo'),
                          decoration: const InputDecoration(
                            hintText: 'أدخل سبب السحب',
                            hintStyle: TextStyle(fontFamily: 'Cairo'),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Save Button (only if can add/delete)
                    if (_canAddDelete)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveFundEntry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isWithdrawal
                                ? Colors.red
                                : AppTheme.primary,
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
                              : Text(
                                  _isWithdrawal
                                      ? 'تسجيل السحب'
                                      : 'تسجيل الإيداع',
                                  style: const TextStyle(
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
    final allRecords = <FundModel>[];
    _volunteerFundRecords.forEach((_, records) {
      allRecords.addAll(records);
    });
    allRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final withdrawals = allRecords.where((r) => r.isWithdrawal).toList();
    final deposits = allRecords.where((r) => !r.isWithdrawal).toList();

    final visibleWithdrawals = _showAllWithdrawals
        ? withdrawals
        : withdrawals.take(10).toList();
    final visibleDeposits = deposits.take(10).toList();

    if (withdrawals.isEmpty && deposits.isEmpty) {
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آخر السحوبات',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        if (visibleWithdrawals.isEmpty)
          const Text(
            'لا توجد سحوبات',
            style: TextStyle(fontFamily: 'Cairo', color: AppTheme.secondary),
          )
        else
          Column(
            children: visibleWithdrawals
                .map(_buildRecordCard)
                .toList(growable: false),
          ),
        if (withdrawals.length > 10)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                setState(() => _showAllWithdrawals = !_showAllWithdrawals);
              },
              child: Text(
                _showAllWithdrawals ? 'عرض أقل' : 'عرض المزيد',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'آخر الإيداعات',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        if (visibleDeposits.isEmpty)
          const Text(
            'لا توجد إيداعات',
            style: TextStyle(fontFamily: 'Cairo', color: AppTheme.secondary),
          )
        else
          Column(
            children: visibleDeposits
                .map(_buildRecordCard)
                .toList(growable: false),
          ),
      ],
    );
  }

  Widget _buildRecordCard(FundModel record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: record.isWithdrawal
              ? Colors.red.withOpacity(0.3)
              : AppTheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: record.isWithdrawal
                  ? Colors.red.withOpacity(0.1)
                  : AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              record.isWithdrawal ? Icons.arrow_upward : Icons.arrow_downward,
              color: record.isWithdrawal ? Colors.red : AppTheme.primary,
            ),
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
                if (record.isWithdrawal && record.withdrawalReason != null)
                  Text(
                    record.withdrawalReason!,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppTheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
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
          Text(
            '${record.isWithdrawal ? "-" : "+"}${record.amount.toStringAsFixed(0)} جنيه',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: record.isWithdrawal ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
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
