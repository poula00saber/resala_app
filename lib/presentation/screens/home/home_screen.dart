import 'package:flutter/material.dart';
import 'package:resala/presentation/screens/contacts/contacts_screen.dart';
import 'package:resala/presentation/screens/promotions/promotions_screen.dart';
import 'package:resala/presentation/screens/committees/committees_management_screen.dart';
import 'package:resala/presentation/screens/login/login_screen.dart';
import 'package:resala/presentation/themes/app_theme.dart';
import '../profiles/profiles_screen.dart';
import '../events/events_screen.dart';
import '../evaluations/evaluations_screen.dart';
import '../reports/reports_screen.dart';
import '../interviews/interviews_screen.dart';
import '../administrative/administrative_screen.dart';
import '../users/user_management_screen.dart';
import '../users/operation_logs_screen.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/app_user_model.dart';
import '../../widgets/whale_loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Key for tracking if user just logged out
const String _justLoggedOutKey = 'just_logged_out';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // If user is not loaded yet, load from Firestore
    if (_authService.currentUser == null) {
      await _authService.initialize();
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while initializing auth
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: WhaleLoading()),
      );
    }

    // Get menu buttons based on permissions
    final menuButtons = _buildMenuButtons(context);

    // If no permissions and not admin, show message
    if (menuButtons.isEmpty && !_authService.isAdmin) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text(
            "الصفحة الرئيسية",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: AppTheme.cardBackground,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.textLight,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        drawer: _buildDrawer(context),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: AppTheme.secondary),
              SizedBox(height: 16),
              Text(
                'لا توجد صلاحيات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  color: AppTheme.secondary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'تواصل مع المسؤول للحصول على الصلاحيات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          "الصفحة الرئيسية",
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppTheme.cardBackground,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textLight,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          children: menuButtons,
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = _authService.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, Color(0xFF6B2636)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: AppTheme.cardBackground,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.displayName ?? user?.email ?? 'مدير النظام',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppTheme.cardBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user?.isAdmin == true)
                    const Text(
                      'مدير النظام',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            // User Management - Only for admins
            if (_authService.isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.people, color: AppTheme.primary),
                title: const Text(
                  'إدارة المستخدمين',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserManagementScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: AppTheme.primary),
                title: const Text(
                  'سجل العمليات',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OperationLogsScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
              ),
              onTap: () async {
                // Close the drawer first
                Navigator.pop(context);

                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(fontFamily: 'Cairo'),
                      textAlign: TextAlign.center,
                    ),
                    content: const Text(
                      'هل أنت متأكد من تسجيل الخروج؟',
                      style: TextStyle(fontFamily: 'Cairo'),
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && mounted) {
                  // Set flag to prevent auto-login on next app start
                  // Use delayed execution to avoid SharedPreferences channel error
                  Future.delayed(Duration.zero, () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(_justLoggedOutKey, true);
                  });

                  await _authService.signOut();
                  if (mounted) {
                    // Navigate to login and remove all previous routes
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuButtons(BuildContext context) {
    final buttons = <Widget>[];

    // For admin, show all buttons. For others, check permissions.
    if (_authService.isAdmin || _authService.canAccessPage(AppPages.profiles)) {
      buttons.add(
        _menuButton("بروفايلات", Icons.person, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilesScreen()),
          );
        }),
      );
    }

    if (_authService.isAdmin || _authService.canAccessPage(AppPages.reports)) {
      buttons.add(
        _menuButton("تقارير", Icons.lightbulb, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportsScreen()),
          );
        }),
      );
    }

    if (_authService.isAdmin || _authService.canAccessPage(AppPages.events)) {
      buttons.add(
        _menuButton("الأحداث", Icons.event, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EventsScreen()),
          );
        }),
      );
    }

    if (_authService.isAdmin ||
        _authService.canAccessPage(AppPages.evaluations)) {
      buttons.add(
        _menuButton("تقييمات", Icons.star, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EvaluationsScreen()),
          );
        }),
      );
    }

    if (_authService.isAdmin || _authService.canAccessPage(AppPages.contacts)) {
      buttons.add(
        _menuButton("اتصالات", Icons.phone, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContactsScreen()),
          );
        }),
      );
    }

    if (_authService.isAdmin ||
        _authService.canAccessPage(AppPages.interviews)) {
      buttons.add(
        _menuButton("مقابلات", Icons.people, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InterviewsScreen()),
          );
        }),
      );
    }

    if (_authService.isAdmin ||
        _authService.canAccessPage(AppPages.promotions)) {
      buttons.add(
        _menuButton("ترقيات", Icons.workspace_premium, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PromotionsScreen()),
          );
        }),
      );
    }

    if (_authService.isAdmin ||
        _authService.canAccessPage(AppPages.committees)) {
      buttons.add(
        _menuButton("الهيكل", Icons.groups_2_outlined, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CommitteesManagementScreen(),
            ),
          );
        }),
      );
    }

    if (_authService.isAdmin ||
        _authService.canAccessPage(AppPages.administrative)) {
      buttons.add(
        _menuButton("اداريات", Icons.admin_panel_settings, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdministrativeScreen(),
            ),
          );
        }),
      );
    }

    return buttons;
  }

  Widget _menuButton(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, Color(0xFF6B2636)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 40, color: AppTheme.textLight),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.cardBackground,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
