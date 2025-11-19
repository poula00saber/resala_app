// ============================================
// FILE 3: lib/presentation/screens/home/profile_details_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../providers/committee_provider.dart';
import '../../themes/app_theme.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final dynamic volunteer;

  const ProfileDetailsScreen({super.key, required this.volunteer});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _nationalIdController;

  bool _isLoading = false;
  String? _selectedCommitteeId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.volunteer.name);
    _phoneController = TextEditingController(text: widget.volunteer.phone);
    _emailController = TextEditingController(text: widget.volunteer.email);
    _addressController = TextEditingController(text: widget.volunteer.address);
    _nationalIdController = TextEditingController(
      text: widget.volunteer.nationalId ?? '',
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // TODO: Update volunteer in Firebase
    // For now just show success message

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم حفظ البيانات بنجاح',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Circle
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6D5F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: AppTheme.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Name
              _buildTextField(
                controller: _nameController,
                label: 'الاسم',
                validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
              ),

              const SizedBox(height: 16),

              // Phone and Age Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _phoneController,
                      label: 'رقم التليفون',
                      validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: TextEditingController(),
                      label: 'السن',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Address
              _buildTextField(controller: _addressController, label: 'العنوان'),

              const SizedBox(height: 16),

              // National ID
              _buildTextField(
                controller: _nationalIdController,
                label: 'الرقم القومي',
              ),

              const SizedBox(height: 16),

              // Committee Dropdown
              StreamBuilder(
                stream: Provider.of<CommitteeProvider>(
                  context,
                  listen: false,
                ).getActiveCommittees(),
                builder: (context, snapshot) {
                  final committees = snapshot.data ?? [];

                  return DropdownButtonFormField<String>(
                    value: _selectedCommitteeId,
                    decoration: InputDecoration(
                      hintText: 'اللجنة التطوعية',
                      hintStyle: const TextStyle(fontFamily: 'Cairo'),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: AppTheme.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: AppTheme.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: AppTheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    items: committees
                        .map(
                          (committee) => DropdownMenuItem(
                            value: committee.id,
                            child: Text(
                              committee.name,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCommitteeId = value;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
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
                          'حفظ',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          fontFamily: 'Cairo',
          color: Colors.grey[400],
          fontSize: 12,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: AppTheme.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: AppTheme.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }
}
