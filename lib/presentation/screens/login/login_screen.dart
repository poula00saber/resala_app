import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resala/presentation/themes/app_theme.dart';
import 'package:resala/services/auth_service.dart';
import '../home/home_screen.dart';

// Key for tracking if user just logged out
const String _justLoggedOutKey = 'just_logged_out';

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
  bool _isAutoLoggingIn = false;

  // List of saved accounts for account switching
  List<Map<String, String>> _savedAccounts = [];
  String? _selectedAccountEmail;

  // Shared preferences keys
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';
  static const String _accountsKey = 'saved_accounts';

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
    // Set auth persistence to LOCAL to maintain session across app restarts
    _setAuthPersistence();

    // Delay SharedPreferences calls until after widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedCredentials();
      _loadSavedAccounts();
      // Check if already logged in and auto-login
      _checkAutoLogin();
    });
  }

  Future<void> _setAuthPersistence() async {
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      debugPrint('Firebase Auth persistence set to LOCAL');
    } catch (e) {
      debugPrint('Error setting auth persistence: $e');
    }
  }

  Future<void> _checkAutoLogin() async {
    // Check if user just logged out (don't auto-login in this case)
    final prefs = await SharedPreferences.getInstance();
    final justLoggedOut = prefs.getBool(_justLoggedOutKey) ?? false;

    if (justLoggedOut) {
      // User explicitly logged out, don't auto-login
      await prefs.setBool(_justLoggedOutKey, false);
      debugPrint('User just logged out, skipping auto-login');
      return;
    }

    // Check if user is already logged in with Firebase
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      debugPrint('User already logged in: ${currentUser.email}');
      // Navigate to home directly
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }
    }

    // If remember me is checked and credentials exist, auto-login
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (rememberMe) {
      final savedEmail = prefs.getString(_savedEmailKey) ?? '';
      final savedPassword = prefs.getString(_savedPasswordKey) ?? '';

      if (savedEmail.isNotEmpty && savedPassword.isNotEmpty) {
        debugPrint('Auto-login with saved credentials for: $savedEmail');
        setState(() {
          _isAutoLoggingIn = true;
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
        });
        // Auto-login after a small delay to allow UI to render
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          await _login();
        }
      }
    }
  }

  Future<void> _loadSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getStringList(_accountsKey) ?? [];

    List<Map<String, String>> accounts = [];
    for (String accountJson in accountsJson) {
      // Format: email|password|name
      final parts = accountJson.split('|');
      if (parts.length >= 2) {
        accounts.add({
          'email': parts[0],
          'password': parts[1],
          'name': parts.length > 2 ? parts[2] : parts[0].split('@')[0],
        });
      }
    }

    if (mounted) {
      setState(() {
        _savedAccounts = accounts;
      });
    }
  }

  Future<void> _saveAccountToList(
    String email,
    String password,
    String name,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getStringList(_accountsKey) ?? [];

    // Check if account already exists, if so update it
    final existingIndex = accountsJson.indexWhere(
      (acc) => acc.startsWith('$email|'),
    );

    if (existingIndex == -1) {
      // Add new account: email|password|name
      accountsJson.add('$email|$password|$name');
    } else {
      // Update existing account
      accountsJson[existingIndex] = '$email|$password|$name';
    }

    await prefs.setStringList(_accountsKey, accountsJson);
    await _loadSavedAccounts();
  }

  Future<void> _removeAccountFromList(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getStringList(_accountsKey) ?? [];

    accountsJson.removeWhere((acc) => acc.startsWith('$email|'));
    await prefs.setStringList(_accountsKey, accountsJson);
    await _loadSavedAccounts();
  }

  void _selectAccount(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _selectedAccountEmail = email;
      _rememberMe = true;
    });

    // Auto-login when account is selected
    if (password.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _login();
        }
      });
    }
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
    final email = _emailController.text.trim();

    if (_rememberMe) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_savedEmailKey, email);
      await prefs.setString(_savedPasswordKey, _passwordController.text);

      // Also save to accounts list for account switching
      await _saveAccountToList(
        email,
        _passwordController.text,
        email.split('@')[0],
      );
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

                          // Account switching UI (Facebook-like)
                          if (_savedAccounts.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'اختر حساباً',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: _savedAccounts.map((account) {
                                        final isSelected =
                                            account['email'] ==
                                            _selectedAccountEmail;
                                        return GestureDetector(
                                          onTap: () {
                                            _selectAccount(
                                              account['email']!,
                                              account['password'] ?? '',
                                            );
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            child: Column(
                                              children: [
                                                CircleAvatar(
                                                  radius: 28,
                                                  backgroundColor: isSelected
                                                      ? AppTheme.primary
                                                      : Colors.grey.shade300,
                                                  child: Icon(
                                                    Icons.person,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.grey.shade600,
                                                    size: 28,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                SizedBox(
                                                  width: 60,
                                                  child: Text(
                                                    account['name']!,
                                                    style: TextStyle(
                                                      fontFamily: 'Cairo',
                                                      fontSize: 10,
                                                      color: isSelected
                                                          ? AppTheme.primary
                                                          : Colors
                                                                .grey
                                                                .shade600,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
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
                              onPressed: _isLoading || _isAutoLoggingIn
                                  ? null
                                  : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shadowColor: AppTheme.primary.withOpacity(0.4),
                              ),
                              child: _isLoading || _isAutoLoggingIn
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
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(
              icon,
              color: AppTheme.primary.withOpacity(0.7),
              size: 22,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.primary.withOpacity(0.5),
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
