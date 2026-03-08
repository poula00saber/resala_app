import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../themes/app_theme.dart';
import '../widgets/whale_loading.dart';
import 'home/home_screen.dart';
import 'login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Wait 2 seconds for splash display
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Check if user is already logged in
      final isLoggedIn = _authService.isLoggedIn;

      if (mounted) {
        if (isLoggedIn) {
          // Navigate to home screen
          Navigator.of(context).pushReplacementNamed('/');
        } else {
          // Navigate to login screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cardBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo - Large and centered with better visibility
            Container(
              padding: const EdgeInsets.all(30),
              child: Image.asset(
                'assets/images/resala_logo.png',
                width: 280,
                height: 280,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator with app color
            WhaleLoading(size: 60),
          ],
        ),
      ),
    );
  }
}
