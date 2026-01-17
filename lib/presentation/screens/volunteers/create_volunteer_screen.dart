// ============================================
// FILE: lib/presentation/screens/volunteers/create_volunteer_screen.dart
// UPDATED: Age is required, shows educational level based on age
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/firebase_constants.dart'; // ADD THIS IMPORT

class CreateVolunteerScreen extends StatefulWidget {
  const CreateVolunteerScreen({super.key});

  @override
  State<CreateVolunteerScreen> createState() => _CreateVolunteerScreenState();
}

class _CreateVolunteerScreenState extends State<CreateVolunteerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _educationalLevelController =
      TextEditingController(); // NEW

  bool _isLoading = false;
  int? _calculatedAge; // NEW: Store calculated age

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

        // Calculate age from birth date
        final now = DateTime.now();
        int age = now.year - picked.year;
        if (now.month < picked.month ||
            (now.month == picked.month && now.day < picked.day)) {
          age--;
        }

        if (age > 0) {
          _ageController.text = age.toString();
          _updateEducationalLevel(age);
        }
      });
    }
  }

  void _updateEducationalLevel(int age) {
    setState(() {
      _calculatedAge = age;
      final level = FirebaseConstants.getInitialEducationalLevel(age);
      _educationalLevelController.text = level;
    });
  }

  Future<void> _createVolunteer() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate age is provided
    if (_calculatedAge == null && _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال العمر'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Parse age
    final age = _calculatedAge ?? int.tryParse(_ageController.text);
    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عمر غير صحيح'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (age < 1 || age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال عمر صحيح (1-100)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final volunteerProvider = Provider.of<VolunteerProvider>(
      context,
      listen: false,
    );

    final volunteerId = await volunteerProvider.createVolunteer(
      name: _nameController.text,
      phone: _phoneController.text,
      email: '${_phoneController.text}@resala.com', // Default email
      address: _addressController.text,
      nationalId: _nationalIdController.text.isEmpty
          ? null
          : _nationalIdController.text,
      age: age, // PASS THE AGE
      hasInterview: false,
      committeeId: null, // You can add committee selection if needed
      committeeName: null,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (volunteerId != null) {
        Navigator.pop(context, volunteerId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إضافة المتطوع بنجاح (المستوى: ${_educationalLevelController.text})',
            ),
            backgroundColor: AppTheme.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إضافة المتطوع'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8DDD3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8DDD3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'قافلة',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Date and Location Fields (Empty for create screen)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: Row(
              children: [
                Expanded(child: _buildDisabledTextField('المكان')),
                const SizedBox(width: 16),
                Expanded(child: _buildDisabledTextField('التاريخ')),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Main Form Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Title
                      const Text(
                        'متطوع جديد',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name Field
                      _buildFormField(
                        controller: _nameController,
                        label: 'الاسم',
                        validator: Validators.validateName,
                      ),
                      const SizedBox(height: 16),

                      // Age and Phone Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: _ageController,
                              label: 'السن',
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  final age = int.tryParse(value);
                                  if (age != null && age > 0 && age <= 100) {
                                    _updateEducationalLevel(age);
                                  }
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'مطلوب';
                                }
                                final age = int.tryParse(value);
                                if (age == null) {
                                  return 'عمر غير صحيح';
                                }
                                if (age < 1 || age > 100) {
                                  return 'العمر 1-100';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFormField(
                              controller: _phoneController,
                              label: 'رقم التليفون',
                              keyboardType: TextInputType.phone,
                              validator: Validators.validatePhone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Educational Level Display (Read-only)
                      _buildFormField(
                        controller: _educationalLevelController,
                        label: 'المستوى التعليمي',
                        readOnly: true,
                        enabled: true,
                        suffixIcon: Icons.school,
                        onTap: _calculatedAge != null
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('المستوى التعليمي'),
                                    content: Text(
                                      'العمر: $_calculatedAge سنة\n'
                                      'المستوى: ${_educationalLevelController.text}\n\n'
                                      'قاعدة المستويات:\n'
                                      '• شبل: أقل من 17 سنة\n'
                                      '• جدد: 17 سنة أو أكثر',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('حسناً'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Address Field
                      _buildFormField(
                        controller: _addressController,
                        label: 'العنوان',
                        validator: (value) =>
                            Validators.validateRequired(value, 'العنوان'),
                      ),
                      const SizedBox(height: 16),

                      // National ID Field
                      _buildFormField(
                        controller: _nationalIdController,
                        label: 'الرقم القومي',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Birth Date Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: TextEditingController(),
                              label: 'الخبرة',
                              enabled: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFormField(
                              controller: _birthDateController,
                              label: 'تاريخ الميلاد',
                              readOnly: true,
                              onTap: _selectBirthDate,
                              suffixIcon: Icons.calendar_today,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createVolunteer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'إضافة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledTextField(String label) {
    return TextField(
      enabled: false,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    bool enabled = true,
    VoidCallback? onTap,
    IconData? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      onChanged: onChanged,
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 18, color: AppTheme.primary)
            : null,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _nationalIdController.dispose();
    _birthDateController.dispose();
    _educationalLevelController.dispose();
    super.dispose();
  }
}
