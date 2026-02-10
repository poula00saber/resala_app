import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resala/presentation/themes/app_theme.dart';
import 'package:resala/services/auth_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  // Shared preferences keys
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  // Default admin credentials
  static const String _defaultAdminEmail = 'admin.resala@gmail.com';
  static const String _defaultAdminPassword = 'Resala@2026Dev';

  @override
  void initState() {
    super.initState();
    // Disable app verification for emulators/testing
    if (kDebugMode) {
      FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
    }
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (rememberMe) {
      final savedEmail = prefs.getString(_savedEmailKey) ?? '';
      final savedPassword = prefs.getString(_savedPasswordKey) ?? '';

      setState(() {
        _rememberMe = rememberMe;
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    if (_rememberMe) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_savedEmailKey, _emailController.text.trim());
      await prefs.setString(_savedPasswordKey, _passwordController.text);
    } else {
      await prefs.setBool(_rememberMeKey, false);
      await prefs.remove(_savedEmailKey);
      await prefs.remove(_savedPasswordKey);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController
          .text; // Don't trim password - might have intentional spaces

      // Validate inputs
      if (email.isEmpty) {
        setState(() {
          _errorMessage = 'يرجى إدخال البريد الإلكتروني';
          _isLoading = false;
        });
        return;
      }
      if (password.isEmpty) {
        setState(() {
          _errorMessage = 'يرجى إدخال كلمة المرور';
          _isLoading = false;
        });
        return;
      }

      // Auto-login with default admin credentials if "auto" is entered or fields are empty
      // if (email.toLowerCase() == 'auto' ||
      //     (email.isEmpty && password.isEmpty)) {
      //   email = _defaultAdminEmail;
      //   password = _defaultAdminPassword;
      // }

      // Disable reCAPTCHA verification for testing
      FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );

      // Sign in with Firebase Auth
      debugPrint('Attempting login with email: $email');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Firebase Auth login successful');

      // Save credentials if remember me is checked (don't let this break login)
      try {
        await _saveCredentials();
        debugPrint('Credentials saved successfully');
      } catch (e) {
        debugPrint('Error saving credentials: $e');
      }

      // Initialize AuthService to load user permissions from Firestore
      try {
        final authService = AuthService();
        await authService.initialize();
        debugPrint('AuthService initialized successfully');
      } catch (e) {
        debugPrint('Error initializing AuthService: $e');
        // Continue anyway - user can still access the app
      }

      debugPrint('About to navigate to HomeScreen, mounted: $mounted');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        debugPrint('Navigation to HomeScreen triggered');
      }
    } on FirebaseAuthException catch (e) {
      String message = _getErrorMessage(e.code);
      setState(() => _errorMessage = message);
    } catch (e) {
      // Handle all other Firebase errors
      String errorStr = e.toString().toLowerCase();
      String message = 'حدث خطأ في تسجيل الدخول';

      if (errorStr.contains('user-not-found')) {
        message = 'المستخدم غير موجود';
      } else if (errorStr.contains('wrong-password')) {
        message = 'كلمة المرور غير صحيحة';
      } else if (errorStr.contains('invalid-email')) {
        message = 'البريد الإلكتروني غير صالح';
      } else if (errorStr.contains('user-disabled')) {
        message = 'تم تعطيل هذا الحساب';
      } else if (errorStr.contains('invalid-credential')) {
        message = 'بيانات الدخول غير صحيحة';
      } else if (errorStr.contains('network')) {
        message = 'خطأ في الاتصال بالإنترنت';
      } else if (errorStr.contains('too-many-requests')) {
        message = 'محاولات كثيرة، حاول لاحقاً';
      }

      setState(() => _errorMessage = message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'المستخدم غير موجود';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'invalid-credential':
        return 'بيانات الدخول غير صحيحة';
      case 'network-request-failed':
        return 'خطأ في الاتصال بالإنترنت';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      default:
        return 'حدث خطأ في تسجيل الدخول';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primary.withOpacity(0.1),
              Colors.white,
              const Color(0xFFF8F4E9),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.05),

                  // Logo
                  Hero(
                    tag: 'resala_logo',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/resala_logo.png',
                        height: 120,
                        width: 120,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Welcome text
                  const Column(
                    children: [
                      Text(
                        'مرحباً بك',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'سجل دخولك للمتابعة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Login form card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Email field
                          _buildModernTextField(
                            controller: _emailController,
                            label: 'البريد الإلكتروني',
                            hint: 'أدخل البريد الإلكتروني',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 20),

                          // Password field
                          _buildModernTextField(
                            controller: _passwordController,
                            label: 'كلمة المرور',
                            hint: 'أدخل كلمة المرور',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),

                          const SizedBox(height: 16),

                          // Remember Me checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                                child: const Text(
                                  'تذكرني',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Login button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shadowColor: AppTheme.primary.withOpacity(0.4),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.login, size: 22),
                                        SizedBox(width: 10),
                                        Text(
                                          'تسجيل الدخول',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick login button
                  // TextButton.icon(
                  //   onPressed: _isLoading
                  //       ? null
                  //       : () {
                  //           _emailController.text = 'auto';
                  //           _login();
                  //         },
                  //   icon: const Icon(Icons.flash_on, color: AppTheme.primary),
                  //   label: const Text(
                  //     'دخول سريع',
                  //     style: TextStyle(
                  //       fontFamily: 'Cairo',
                  //       fontSize: 16,
                  //       color: AppTheme.primary,
                  //       fontWeight: FontWeight.w600,
                  //     ),
                  //   ),
                  //   style: TextButton.styleFrom(
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 24,
                  //       vertical: 12,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //       side: const BorderSide(
                  //         color: AppTheme.primary,
                  //         width: 1.5,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 40),

                  // Footer
                  const Text(
                    'رسالة © 2026',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? _obscurePassword : false,
            keyboardType: keyboardType,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: AppTheme.primary, size: 22),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
