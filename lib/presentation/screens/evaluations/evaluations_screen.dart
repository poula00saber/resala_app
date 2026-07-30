// ============================================
// FILE 1: lib/presentation/screens/home/evaluations_screen.dart
// Image 1 - List of all volunteers for evaluation
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/presentation/screens/evaluations/evaluation_details_screen.dart';
import '../../providers/evaluation_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/whale_loading.dart';
import '../../../services/auth_service.dart';

class EvaluationsScreen extends StatefulWidget {
  const EvaluationsScreen({super.key});

  @override
  State<EvaluationsScreen> createState() => _EvaluationsScreenState();
}

class _EvaluationsScreenState extends State<EvaluationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  String _searchQuery = '';
  String? _evaluatorCommitteeId;
  String? _evaluatorCommitteeName;
  bool _loadingCommittee = true;
  bool _isGeneratingBulkEvaluations = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvaluatorCommittee();
    });
  }

  Future<void> _loadEvaluatorCommittee() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || currentUser.isAdmin) {
      if (mounted) {
        setState(() => _loadingCommittee = false);
      }
      return;
    }

    final email = currentUser.email.trim();
    if (email.isEmpty) {
      if (mounted) {
        setState(() => _loadingCommittee = false);
      }
      return;
    }

    final provider = Provider.of<VolunteerProvider>(context, listen: false);
    final volunteer = await provider.getVolunteerByEmail(email);

    if (mounted) {
      setState(() {
        _evaluatorCommitteeId = volunteer?.committeeId;
        _evaluatorCommitteeName = volunteer?.committeeName;
        _loadingCommittee = false;
      });
    }
  }

  List<dynamic> _filterByCommittee(List<dynamic> volunteers) {
    if (_authService.isAdmin) return volunteers;
    if (_evaluatorCommitteeId == null) return [];
    return volunteers
        .where(
          (v) =>
              v.committeeId == _evaluatorCommitteeId ||
              (_evaluatorCommitteeName != null &&
                  v.committeeName == _evaluatorCommitteeName),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'التقييمات',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: AppTheme.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'بحث',
                hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppTheme.secondary,
                ),
                prefixIcon: const Icon(Icons.search, color: AppTheme.secondary),
                filled: true,
                fillColor: AppTheme.cardBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 180,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingBulkEvaluations
                        ? null
                        : _createMonthlyAttendanceBulkEvaluations,
                    icon: const Icon(Icons.fact_check),
                    label: const Text(
                      'تقييم الحضور الشهري',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.textLight,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingBulkEvaluations
                        ? null
                        : _createMonthlyDistributionBulkEvaluations,
                    icon: const Icon(Icons.percent),
                    label: const Text(
                      'تقييم نسبة التوزيع',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: AppTheme.textLight,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Volunteers List
          Expanded(
            child: StreamBuilder(
              stream: Provider.of<VolunteerProvider>(
                context,
                listen: false,
              ).searchActiveVolunteers(_searchQuery),
              builder: (context, snapshot) {
                if (_loadingCommittee && !_authService.isAdmin) {
                  return Center(child: WhaleLoading());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: WhaleLoading());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'حدث خطأ: ${snapshot.error}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.red,
                      ),
                    ),
                  );
                }

                final volunteers = _filterByCommittee(snapshot.data ?? []);

                if (!_authService.isAdmin && _evaluatorCommitteeId == null) {
                  return const Center(
                    child: Text(
                      'لا توجد لجنة مرتبطة بحسابك',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppTheme.secondary,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                if (!_authService.isAdmin && volunteers.isNotEmpty) {
                  return Column(
                    children: [
                      if (_evaluatorCommitteeName != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'لجنتك: ${_evaluatorCommitteeName!}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: AppTheme.secondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      Expanded(child: _buildVolunteerList(volunteers)),
                    ],
                  );
                }

                if (volunteers.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد تقييمات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppTheme.secondary,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return _buildVolunteerList(volunteers);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createMonthlyAttendanceBulkEvaluations() async {
    if (_isGeneratingBulkEvaluations) return;

    final evaluationProvider = Provider.of<EvaluationProvider>(
      context,
      listen: false,
    );
    final volunteerProvider = Provider.of<VolunteerProvider>(
      context,
      listen: false,
    );
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    setState(() => _isGeneratingBulkEvaluations = true);

    try {
      final now = DateTime.now();
      final evaluatedMonthDate = now.month == 1
          ? DateTime(now.year - 1, 12, 1)
          : DateTime(now.year, now.month - 1, 1);
      final monthKey =
          '${evaluatedMonthDate.year}-${evaluatedMonthDate.month.toString().padLeft(2, '0')}';
      final evaluationDate = DateTime(now.year, now.month, 1);
      final volunteers = await volunteerProvider.getActiveVolunteersOnce();
      final qaflaEvents = eventProvider.getQaflaEvents();
      final createdCount = await evaluationProvider
          .createBulkAttendanceEvaluations(
            volunteers: volunteers,
            qaflaEvents: qaflaEvents,
            month: monthKey,
            evaluationDate: evaluationDate,
            evaluationName:
                'حضور قوافل شهر ${_arabicMonthName(evaluatedMonthDate.month)}',
            evaluatorName: 'شهري',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              createdCount > 0
                  ? 'تم إنشاء $createdCount تقييمًا جديدًا'
                  : 'لا توجد تقييمات جديدة لإضافتها',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: createdCount > 0
                ? Colors.green
                : AppTheme.secondary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingBulkEvaluations = false);
      }
    }
  }

  Future<void> _createMonthlyDistributionBulkEvaluations() async {
    if (_isGeneratingBulkEvaluations) return;

    final evaluationProvider = Provider.of<EvaluationProvider>(
      context,
      listen: false,
    );
    final volunteerProvider = Provider.of<VolunteerProvider>(
      context,
      listen: false,
    );
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    setState(() => _isGeneratingBulkEvaluations = true);

    try {
      final now = DateTime.now();
      final evaluatedMonthDate = now.month == 1
          ? DateTime(now.year - 1, 12, 1)
          : DateTime(now.year, now.month - 1, 1);
      final monthKey =
          '${evaluatedMonthDate.year}-${evaluatedMonthDate.month.toString().padLeft(2, '0')}';
      final evaluationDate = DateTime(now.year, now.month, 1);
      final volunteers = await volunteerProvider.getActiveVolunteersOnce();
      final qaflaEvents = eventProvider.getQaflaEvents();
      final createdCount = await evaluationProvider
          .createBulkDistributionEvaluations(
            volunteers: volunteers,
            qaflaEvents: qaflaEvents,
            month: monthKey,
            evaluationDate: evaluationDate,
            evaluationName:
                'نسبة التوزيع شهر ${_arabicMonthName(evaluatedMonthDate.month)}',
            evaluatorName: 'شهري',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              createdCount > 0
                  ? 'تم إنشاء $createdCount تقييمًا جديدًا'
                  : 'لا توجد تقييمات جديدة لإضافتها',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: createdCount > 0
                ? Colors.green
                : AppTheme.secondary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingBulkEvaluations = false);
      }
    }
  }

  String _arabicMonthName(int month) {
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
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  Widget _buildVolunteerList(List<dynamic> volunteers) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: volunteers.length,
      itemBuilder: (context, index) {
        final volunteer = volunteers[index];
        return _buildVolunteerCard(volunteer);
      },
    );
  }

  Widget _buildVolunteerCard(dynamic volunteer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  VolunteerEvaluationDetailsScreen(volunteer: volunteer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Left - Edit Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppTheme.cardBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),

              const Spacer(),

              // Right - Name
              Expanded(
                flex: 3,
                child: Text(
                  volunteer.name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppTheme.cardBackground,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 12),

              // Profile Circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  shape: BoxShape.circle,
                  image:
                      volunteer.profileImage != null &&
                          volunteer.profileImage!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(volunteer.profileImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child:
                    volunteer.profileImage == null ||
                        volunteer.profileImage!.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: AppTheme.primary,
                        size: 24,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
