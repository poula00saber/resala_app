// ============================================
// FILE: lib/presentation/screens/profiles/add_existing_volunteer_screen.dart
// Add existing volunteer with full data from volunteer model
// ============================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/core/constants/firebase_constants.dart';
import 'package:resala/services/image_upload_service.dart';
import '../../providers/volunteer_provider.dart';
import '../../providers/committee_provider.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/volunteer_model.dart';

class AddExistingVolunteerScreen extends StatefulWidget {
  const AddExistingVolunteerScreen({super.key});

  @override
  State<AddExistingVolunteerScreen> createState() =>
      _AddExistingVolunteerScreenState();
}

class _AddExistingVolunteerScreenState
    extends State<AddExistingVolunteerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();

  File? _selectedImage;
  bool _uploadingImage = false;
  final ImageUploadService _imageUploadService = ImageUploadService();

  bool _isLoading = false;
  bool _hasTshirt = false;
  bool _hasInterview = false;
  String? _selectedCommitteeId;
  String? _selectedCommitteeName;
  String? _selectedGender;
  String? _selectedEducationalLevel;
  bool _committeesLoaded = false;
  final List<String> _genders = FirebaseConstants.genders;
  final List<String> _educationalLevels = FirebaseConstants.educationalLevels;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('من المعرض'),
              onTap: () async {
                Navigator.pop(context);
                await _selectImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقط صورة'),
              onTap: () async {
                Navigator.pop(context);
                await _selectImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImageFromGallery() async {
    final imageFile = await _imageUploadService.pickImageFromGallery();
    if (imageFile != null) {
      setState(() {
        _selectedImage = imageFile;
      });
    }
  }

  Future<void> _selectImageFromCamera() async {
    final imageFile = await _imageUploadService.pickImageFromCamera();
    if (imageFile != null) {
      setState(() {
        _selectedImage = imageFile;
      });
    }
  }

  Future<String?> _uploadImageToStorage(String volunteerId) async {
    if (_selectedImage == null) return null;

    try {
      final newImageUrl = await _imageUploadService.uploadImage(
        imageFile: _selectedImage!,
        volunteerId: volunteerId,
        oldImageUrl: null,
      );
      return newImageUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في رفع الصورة: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _saveVolunteer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCommitteeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار اللجنة التطوعية'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final volunteerProvider = Provider.of<VolunteerProvider>(
        context,
        listen: false,
      );

      // Create new volunteer with all fields
      final newVolunteer = VolunteerModel(
        id: '', // Will be assigned by Firestore
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        nationalId: _nationalIdController.text.trim().isNotEmpty
            ? _nationalIdController.text.trim()
            : null,
        age: int.tryParse(_ageController.text.trim()),
        committeeId: _selectedCommitteeId,
        committeeName: _selectedCommitteeName,
        hasInterview: _hasInterview,
        hasTshirt: _hasTshirt,
        createdAt: DateTime.now(),
        birthDate: _birthDateController.text.trim().isNotEmpty
            ? _birthDateController.text.trim()
            : null,
        gender: _selectedGender,
        educationalLevel: _selectedEducationalLevel,
        university: _universityController.text.trim().isNotEmpty
            ? _universityController.text.trim()
            : null,
        profileImage: null, // Will be updated after volunteer is created
      );

      // Add volunteer and get the ID
      final volunteerId = await volunteerProvider.addVolunteer(newVolunteer);

      if (volunteerId != null) {
        // Upload image if selected
        if (_selectedImage != null) {
          setState(() => _uploadingImage = true);
          final imageUrl = await _uploadImageToStorage(volunteerId);
          if (imageUrl != null) {
            // Update volunteer with image URL
            await volunteerProvider.updateVolunteerData(volunteerId, {
              'profileImage': imageUrl,
            });
          }
          setState(() => _uploadingImage = false);
        }

        setState(() => _isLoading = false);

        if (mounted) {
          Navigator.pop(context, volunteerId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة المتطوع بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('فشل في إضافة المتطوع');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _uploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get available educational levels based on age
  List<String> _getAvailableLevels() {
    final ageText = _ageController.text.trim();
    final age = int.tryParse(ageText);

    if (age == null) {
      // If no age entered yet, show all levels
      return _educationalLevels;
    }

    if (age <= 16) {
      // Under 17: only شبل and شبل مميز
      return ['شبل', 'شبل مميز'];
    } else {
      // 17 and above: جدد and higher (no شبل options)
      return ['جدد', 'تدريب', 'مشروع مسئول', 'مسئول'];
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: AppTheme.primary)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = _formatDate(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E9), // Light beige background
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header with back button and title
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.primary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'إضافة متطوع جديد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // For symmetry
                  ],
                ),

                const SizedBox(height: 20),

                // Profile Picture with decorative border
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primary, width: 3),
                        borderRadius: BorderRadius.circular(60),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(57),
                        child: _uploadingImage
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primary,
                                ),
                              )
                            : (_selectedImage != null
                                  ? Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppTheme.primary,
                                    )),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Name Field - الاسم
                _buildLabeledTextField(
                  controller: _nameController,
                  label: 'الاسم',
                  isRequired: true,
                ),

                const SizedBox(height: 16),

                // Phone and Age Row - رقم التليفون و السن
                Row(
                  children: [
                    Expanded(
                      child: _buildLabeledTextField(
                        controller: _ageController,
                        label: 'السن',
                        keyboardType: TextInputType.number,
                        isRequired: true,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'مطلوب';
                          final age = int.tryParse(v!);
                          if (age == null || age < 1 || age > 100) {
                            return 'سن غير صحيح';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          // Reset educational level when age changes
                          final age = int.tryParse(value);
                          if (age != null) {
                            setState(() {
                              // Clear selection if it's not valid for the new age
                              if (age <= 16 &&
                                  _selectedEducationalLevel != null &&
                                  ![
                                    'شبل',
                                    'شبل مميز',
                                  ].contains(_selectedEducationalLevel)) {
                                _selectedEducationalLevel = null;
                              } else if (age >= 17 &&
                                  _selectedEducationalLevel != null &&
                                  [
                                    'شبل',
                                    'شبل مميز',
                                  ].contains(_selectedEducationalLevel)) {
                                _selectedEducationalLevel = null;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLabeledTextField(
                        controller: _phoneController,
                        label: 'رقم التليفون',
                        keyboardType: TextInputType.phone,
                        isRequired: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Email - البريد الإلكتروني
                _buildLabeledTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // Address - العنوان
                _buildLabeledTextField(
                  controller: _addressController,
                  label: 'العنوان',
                ),

                const SizedBox(height: 16),

                // National ID - الرقم القومي
                _buildLabeledTextField(
                  controller: _nationalIdController,
                  label: 'الرقم القومي',
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Birth Date and Committee Row - تاريخ الميلاد و اللجنة
                Row(
                  children: [
                    // Committee Dropdown - اللجنة
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, right: 4),
                            child: RichText(
                              text: const TextSpan(
                                text: 'اللجنة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  color: AppTheme.primary,
                                ),
                                children: [
                                  TextSpan(
                                    text: ' *',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          StreamBuilder(
                            stream: Provider.of<CommitteeProvider>(
                              context,
                              listen: false,
                            ).getActiveCommittees(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return _buildLoadingDropdown();
                              }

                              if (snapshot.hasError) {
                                print(
                                  'Committee loading error: ${snapshot.error}',
                                );
                                return _buildErrorDropdown();
                              }

                              if (!snapshot.hasData || snapshot.data == null) {
                                return _buildEmptyDropdown();
                              }

                              final committees = snapshot.data ?? [];

                              if (committees.isEmpty) {
                                return _buildEmptyDropdown();
                              }

                              if (!_committeesLoaded) {
                                _committeesLoaded = true;
                                final committeeIds = committees
                                    .map((c) => c.id)
                                    .toList();
                                if (_selectedCommitteeId != null &&
                                    !committeeIds.contains(
                                      _selectedCommitteeId,
                                    )) {
                                  _selectedCommitteeId = null;
                                  _selectedCommitteeName = null;
                                }
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCommitteeId,
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          'اختر اللجنة',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      ...committees.map(
                                        (committee) => DropdownMenuItem(
                                          value: committee.id,
                                          child: Text(
                                            committee.name,
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCommitteeId = value;
                                        _selectedCommitteeName = value != null
                                            ? committees
                                                  .firstWhere(
                                                    (c) => c.id == value,
                                                  )
                                                  .name
                                            : null;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Birth Date - تاريخ الميلاد
                    Expanded(
                      child: _buildDateFieldWithLabel(
                        controller: _birthDateController,
                        label: 'تاريخ الميلاد',
                        onTap: () => _selectDate(_birthDateController),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Gender and Educational Level Row - النوع و الدرجة التطوعية
                Row(
                  children: [
                    // Educational Level Dropdown - الدرجة التطوعية
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8, right: 4),
                            child: Text(
                              'الدرجة التطوعية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primary,
                                width: 1.5,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedEducationalLevel,
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      'اختر الدرجة',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  ..._getAvailableLevels().map(
                                    (level) => DropdownMenuItem(
                                      value: level,
                                      child: Text(
                                        level,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedEducationalLevel = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Gender Dropdown - النوع
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8, right: 4),
                            child: Text(
                              'النوع',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primary,
                                width: 1.5,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGender,
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      'اختر النوع',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  ..._genders.map(
                                    (gender) => DropdownMenuItem(
                                      value: gender,
                                      child: Text(
                                        gender,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // University - الجامعة
                _buildLabeledTextField(
                  controller: _universityController,
                  label: 'الجامعة',
                ),

                const SizedBox(height: 24),

                // Interview and T-shirt Checkboxes Row
                Row(
                  children: [
                    // Has Interview Checkbox
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text(
                            'المقابلة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Checkbox(
                            value: _hasInterview,
                            onChanged: (value) {
                              setState(() {
                                _hasInterview = value ?? false;
                              });
                            },
                            activeColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // T-shirt Checkbox
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text(
                            'التيشيرت',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Checkbox(
                            value: _hasTshirt,
                            onChanged: (value) {
                              setState(() {
                                _hasTshirt = value ?? false;
                              });
                            },
                            activeColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Save Button - حفظ
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveVolunteer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: AppTheme.primary.withOpacity(0.3),
                    ),
                    child: _isLoading || _uploadingImage
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'إضافة المتطوع',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool isRequired = false,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppTheme.primary,
              ),
              children: isRequired
                  ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ]
                  : [],
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.right,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            hintText: 'أدخل $label',
            hintStyle: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          validator:
              validator ??
              (isRequired
                  ? (value) =>
                        value?.isEmpty ?? true ? 'يرجى إدخال $label' : null
                  : null),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateFieldWithLabel({
    required TextEditingController controller,
    required String label,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppTheme.primary,
            ),
          ),
        ),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: AppTheme.primary,
                ),
                Text(
                  controller.text.isEmpty ? 'اختر $label' : controller.text,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: controller.text.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingDropdown() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary, width: 1.5),
      ),
      child: const Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorDropdown() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 1.5),
      ),
      child: const Center(
        child: Text(
          'خطأ في تحميل اللجان',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: Colors.red,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDropdown() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 1.5),
      ),
      child: const Center(
        child: Text(
          'لا توجد لجان',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: Colors.orange,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _nationalIdController.dispose();
    _birthDateController.dispose();
    _universityController.dispose();
    super.dispose();
  }
}
