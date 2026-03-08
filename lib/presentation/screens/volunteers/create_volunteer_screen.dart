// ============================================
// FILE: lib/presentation/screens/volunteers/create_volunteer_screen.dart
// UPDATED: Only needs name, phone, address, national ID
// Birth date, age, gender, educational level auto-derived from NID
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/whale_loading.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/firebase_constants.dart';

class CreateVolunteerScreen extends StatefulWidget {
  const CreateVolunteerScreen({super.key});

  @override
  State<CreateVolunteerScreen> createState() => _CreateVolunteerScreenState();
}

class _CreateVolunteerScreenState extends State<CreateVolunteerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();

  // Auto-derived fields (read-only display)
  String? _birthDate;
  int? _age;
  String? _gender;
  String? _educationalLevel;

  bool _isLoading = false;

  void _onNationalIdChanged(String value) {
    if (value.length == 14) {
      final data = Validators.parseNationalId(value);
      if (data != null) {
        setState(() {
          _birthDate = data.birthDate;
          _age = data.age;
          _gender = data.gender;
          _educationalLevel = FirebaseConstants.getInitialEducationalLevel(
            data.age,
          );
        });
        return;
      }
    }
    // Clear derived fields if NID is incomplete/invalid
    if (_birthDate != null || _age != null) {
      setState(() {
        _birthDate = null;
        _age = null;
        _gender = null;
        _educationalLevel = null;
      });
    }
  }

  Future<void> _createVolunteer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رقم قومي صحيح لحساب العمر'),
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
      email: '${_phoneController.text}@resala.com',
      address: _addressController.text,
      nationalId: _nationalIdController.text,
      age: _age!,
      birthDate: _birthDate,
      gender: _gender,
      hasInterview: false,
      committeeId: null,
      committeeName: null,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (volunteerId != null) {
        Navigator.pop(context, volunteerId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إضافة المتطوع بنجاح (المستوى: $_educationalLevel)',
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
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'اضافة متطوع',
          style: TextStyle(
            color: AppTheme.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.1),
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

                      // Phone Field
                      _buildFormField(
                        controller: _phoneController,
                        label: 'رقم التليفون',
                        keyboardType: TextInputType.phone,
                        validator: Validators.validatePhone,
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

                      // National ID Field (required, auto-fills other fields)
                      _buildFormField(
                        controller: _nationalIdController,
                        label: 'الرقم القومي',
                        keyboardType: TextInputType.number,
                        onChanged: _onNationalIdChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال الرقم القومي';
                          }
                          return Validators.validateNationalId(value);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Auto-derived fields display
                      if (_age != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'بيانات مستخرجة من الرقم القومي',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow('تاريخ الميلاد', _birthDate ?? '-'),
                              _buildInfoRow('السن', '$_age سنة'),
                              _buildInfoRow('النوع', _gender ?? '-'),
                              _buildInfoRow(
                                'المستوى',
                                _educationalLevel ?? '-',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 16),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createVolunteer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.textLight,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? WhaleLoading(
                                size: 20,
                                color: AppTheme.cardBackground,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppTheme.secondary,
            ),
          ),
        ],
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
    _addressController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }
}
