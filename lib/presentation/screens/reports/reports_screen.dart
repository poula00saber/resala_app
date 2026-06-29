// ============================================
// FILE: lib/presentation/screens/reports/reports_screen.dart
// Main Reports Menu Screen
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/presentation/themes/app_theme.dart';
import 'package:resala/services/auth_service.dart';
import 'package:resala/data/models/app_user_model.dart';
import 'comprehensive_report_screen.dart';
import 'family_day_report_screen.dart';
import 'cubs_report_screen.dart';
import 'meetings_report_screen.dart';
import 'fund_report_screen.dart';
import 'marketing_report_screen.dart';
import 'monthly_report_screen.dart';
import 'qafla_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            "التقارير",
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                if (authService.canAccessSubPage(
                  AppPages.reports,
                  AppPages.reportComprehensive,
                )) ...[
                  _buildReportButton(
                    context,
                    title: 'الكلي',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ComprehensiveReportScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (authService.canAccessSubPage(
                  AppPages.reports,
                  AppPages.reportFamilyDay,
                )) ...[
                  _buildReportButton(
                    context,
                    title: 'اليوم العائلي',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FamilyDayReportScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (authService.canAccessSubPage(
                  AppPages.reports,
                  AppPages.reportCubs,
                )) ...[
                  _buildReportButton(
                    context,
                    title: 'الأشبال',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CubsReportScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (authService.canAccessSubPage(
                  AppPages.reports,
                  AppPages.reportMeetings,
                )) ...[
                  _buildReportButton(
                    context,
                    title: 'الاجتماعات',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MeetingsReportScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (authService.canAccessSubPage(
                  AppPages.reports,
                  AppPages.reportFund,
                )) ...[
                  _buildReportButton(
                    context,
                    title: 'الصندوق',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FundReportScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (authService.canAccessSubPage(
                  AppPages.reports,
                  AppPages.reportMarketing,
                )) ...[
                  _buildReportButton(
                    context,
                    title: 'الدعايا',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MarketingReportScreen(),
                      ),
                    ),
                  ),
                ],
                if (authService.canAccessSubPage(
                  AppPages.reports,
                  AppPages.reportMonthly,
                )) ...[
                  const SizedBox(height: 16),
                  _buildReportButton(
                    context,
                    title: 'الشهري',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MonthlyReportScreen(),
                      ),
                    ),
                  ),
                ],
                if (authService.canAccessSubPage(
                  AppPages.reports,
                  AppPages.reportQafla,
                )) ...[
                  const SizedBox(height: 16),
                  _buildReportButton(
                    context,
                    title: 'القوافل',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QaflaReportScreen(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportButton(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.textLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 2,
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
