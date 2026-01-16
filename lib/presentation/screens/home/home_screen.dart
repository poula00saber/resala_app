import 'package:flutter/material.dart';
import 'package:resala/presentation/screens/promotions/promotions_screen.dart';
import 'package:resala/presentation/screens/settings/committees_management_screen.dart';
import 'package:resala/presentation/themes/app_theme.dart';
import 'profiles_screen.dart';
import '../events/events_screen.dart';
import 'evaluations_screen.dart';
import 'communications_screen.dart';
import 'reports_screen.dart';
import 'interviews_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الصفحة الرئيسية"),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),

      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              _menuButton("بروفايلات", Icons.person, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilesScreen(),
                  ),
                );
              }),
              _menuButton("تقارير", Icons.lightbulb, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                );
              }),
              _menuButton("الأحداث", Icons.event, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventsScreen()),
                );
              }),
              _menuButton("تقييمات", Icons.star, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EvaluationsScreen(),
                  ),
                );
              }),
              _menuButton("اتصالات", Icons.phone, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommunicationsScreen(),
                  ),
                );
              }),
              _menuButton("مقابلات", Icons.people, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InterviewsScreen(),
                  ),
                );
              }),
              _menuButton("ترقيات", Icons.workspace_premium, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PromotionsScreen(),
                  ),
                );
              }),
              _menuButton("اللجان", Icons.groups_2_outlined, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommitteesManagementScreen(),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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
