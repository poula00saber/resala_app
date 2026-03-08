// ============================================
// FILE: lib/presentation/screens/reports/monthly_report_screen.dart
// الشهري - Monthly Statistics Report Screen
// ============================================

import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../widgets/whale_loading.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/models/report_data_model.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final ReportRepository _reportRepository = ReportRepository();
  MonthlyReportStats? _stats;
  bool _isLoading = true;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await _reportRepository.getMonthlyReportStats(
      month: _selectedMonth,
      year: _selectedYear,
    );
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  void _showNonParticipants(
    String title,
    List<VolunteerReportData> volunteers,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                '${volunteers.length} متطوع',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppTheme.secondary,
                ),
              ),
              const Divider(),
              Flexible(
                child: volunteers.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'الكل شاركوا!',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: volunteers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final v = volunteers[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              v.volunteerName,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              v.committeeName ?? '-',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: AppTheme.secondary,
                              ),
                            ),
                            trailing: Text(
                              v.phone ?? '',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            'التقرير الشهري',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 20,
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
        body: Column(
          children: [
            // Month/Year picker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: InputDecoration(
                        labelText: 'الشهر',
                        labelStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(
                            ReportRepository.getArabicMonth(i + 1),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        if (v != null) {
                          _selectedMonth = v;
                          _loadData();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: InputDecoration(
                        labelText: 'السنة',
                        labelStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: List.generate(
                        6,
                        (i) => DropdownMenuItem(
                          value: 2024 + i,
                          child: Text(
                            '${2024 + i}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        if (v != null) {
                          _selectedYear = v;
                          _loadData();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Stats
            Expanded(
              child: _isLoading
                  ? Center(child: WhaleLoading())
                  : _stats == null
                  ? const Center(
                      child: Text(
                        'لا توجد بيانات',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      children: [
                        _buildStatCard(
                          'عدد المسئولين المشاركين',
                          _stats!.masoolParticipantCount.toString(),
                          Icons.person,
                        ),
                        _buildStatCard(
                          'عدد مشروع مسئول المشاركين',
                          _stats!.mashroParticipantCount.toString(),
                          Icons.person_outline,
                        ),
                        _buildStatCard(
                          'عدد الجدد المشاركين',
                          _stats!.gododCount.toString(),
                          Icons.person_add,
                        ),
                        _buildStatCard(
                          'عدد التيشيرتات',
                          _stats!.tshirtCount.toString(),
                          Icons.checkroom,
                        ),
                        _buildStatCard(
                          'عدد الأحداث',
                          _stats!.eventCount.toString(),
                          Icons.event,
                        ),
                        _buildStatCard(
                          'نسبة مشاركة مسئول (حد أقصى 8)',
                          '${_stats!.masoolParticipationRate.toStringAsFixed(1)}%',
                          Icons.trending_up,
                          onTap: () => _showNonParticipants(
                            'مسئول لم يشاركوا',
                            _stats!.masoolNonParticipants,
                          ),
                        ),
                        _buildStatCard(
                          'نسبة مشاركة مشروع مسئول (حد أقصى 8)',
                          '${_stats!.mashroParticipationRate.toStringAsFixed(1)}%',
                          Icons.trending_up,
                          onTap: () => _showNonParticipants(
                            'مشروع مسئول لم يشاركوا',
                            _stats!.mashroNonParticipants,
                          ),
                        ),
                        _buildMeetingsCard(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.cardBackground,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_left,
                  color: AppTheme.secondary,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingsCard() {
    if (_stats == null) return const SizedBox.shrink();

    final totalCommitteeMeetings = _stats!.committeeMeetingCounts.values
        .fold<int>(0, (sum, count) => sum + count);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.cardBackground,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'الاجتماعات',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                Text(
                  '${_stats!.leadersMeetingCount + _stats!.teamMeetingCount + totalCommitteeMeetings}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildMeetingRow('اجتماع ليدرات', _stats!.leadersMeetingCount),
            _buildMeetingRow('اجتماع الفريق', _stats!.teamMeetingCount),
            ..._stats!.committeeMeetingCounts.entries.map(
              (e) => _buildMeetingRow('اجتماع ${e.key}', e.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
