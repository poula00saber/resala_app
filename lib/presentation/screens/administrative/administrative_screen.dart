// ============================================
// FILE: lib/presentation/screens/administrative/administrative_screen.dart
// اداريات - Administrative Main Screen
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../themes/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/app_user_model.dart';
import 'fund_entry_screen.dart';
import 'marketing_entry_screen.dart';

class AdministrativeScreen extends StatelessWidget {
  const AdministrativeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            'اداريات',
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
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              if (authService.canAccessSubPage(
                AppPages.administrative,
                AppPages.adminFund,
              )) ...[
                _buildMenuButton(
                  context,
                  title: 'الصندوق',
                  icon: Icons.account_balance_wallet,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FundEntryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
              if (authService.canAccessSubPage(
                AppPages.administrative,
                AppPages.adminMarketing,
              ))
                _buildMenuButton(
                  context,
                  title: 'الدعايا',
                  icon: Icons.campaign,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MarketingEntryScreen(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 60, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
