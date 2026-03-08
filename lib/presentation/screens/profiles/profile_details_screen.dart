// ============================================
// FILE: lib/presentation/screens/home/profile_details_screen.dart
// REDESIGNED - Exact match to your image layout
// ============================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/core/constants/firebase_constants.dart';
import 'package:resala/services/image_upload_service.dart';
import '../../../core/utils/validators.dart';
import '../../providers/volunteer_provider.dart';
import '../../providers/committee_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/whale_loading.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/app_user_model.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final dynamic volunteer;

  const ProfileDetailsScreen({super.key, required this.volunteer});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool get _canAddDelete =>
      _authService.isAdmin ||
      _authService.canAddDeleteOnPage(AppPages.profiles);

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _addressController;
  late TextEditingController _nationalIdController;
  late TextEditingController _birthDateController;
  late TextEditingController _joinDateController;
  late TextEditingController _educationalLevelController;
  late TextEditingController _universityController;
  File? _selectedImage;
  String? _imageUrl;
  bool _uploadingImage = false;
  final ImageUploadService _imageUploadService = ImageUploadService();

  bool _isLoading = false;
  bool _hasTshirt = false;
  String? _selectedCommitteeId;
  String? _selectedCommitteeName;
  String? _selectedGender;
  bool _committeesLoaded = false;
  final List<String> _genders = FirebaseConstants.genders;
  final List<String> _educationalLevels = FirebaseConstants.educationalLevels;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.volunteer.name ?? '');
    _phoneController = TextEditingController(
      text: widget.volunteer.phone ?? '',
    );
    _ageController = TextEditingController(
      text: widget.volunteer.age?.toString() ?? '',
    );
    _addressController = TextEditingController(
      text: widget.volunteer.address ?? '',
    );
    _nationalIdController = TextEditingController(
      text: widget.volunteer.nationalId ?? '',
    );
    _birthDateController = TextEditingController(
      text: widget.volunteer.birthDate ?? '',
    );
    _joinDateController = TextEditingController(
      text: _formatDate(widget.volunteer.createdAt),
    );
    _educationalLevelController = TextEditingController(
      text: widget.volunteer.educationalLevel ?? '',
    );
    _universityController = TextEditingController(
      text: widget.volunteer.university ?? '',
    );

    // Initialize with volunteer's current data
    _selectedCommitteeId = widget.volunteer.committeeId;
    _selectedCommitteeName = widget.volunteer.committeeName;
    _hasTshirt = widget.volunteer.hasTshirt ?? false;
    _selectedGender = widget.volunteer.gender;
    _imageUrl = widget.volunteer.profileImage; // Initialize with existing image
  }

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
      // Image will be uploaded during save
    }
  }

  Future<void> _selectImageFromCamera() async {
    final imageFile = await _imageUploadService.pickImageFromCamera();
    if (imageFile != null) {
      setState(() {
        _selectedImage = imageFile;
      });
      // Image will be uploaded during save
    }
  }

  Future<String?> _uploadImageToStorage() async {
    if (_selectedImage == null) return null;

    try {
      final newImageUrl = await _imageUploadService.uploadImage(
        imageFile: _selectedImage!,
        volunteerId: widget.volunteer.id,
        oldImageUrl: _imageUrl,
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

  // Update the save method to include profileImage
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final volunteerProvider = Provider.of<VolunteerProvider>(
        context,
        listen: false,
      );

      // Upload image if one was selected
      String? newImageUrl = _imageUrl;
      if (_selectedImage != null) {
        setState(() => _uploadingImage = true);
        final uploadedUrl = await _uploadImageToStorage();
        setState(() => _uploadingImage = false);
        if (uploadedUrl != null) {
          newImageUrl = uploadedUrl;
          _imageUrl = uploadedUrl;
        } else {
          // Upload failed - stop save so user can retry
          setState(() => _isLoading = false);
          return;
        }
      }

      final updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'address': _addressController.text.trim(),
        'nationalId': _nationalIdController.text.trim(),
        'birthDate': _birthDateController.text.trim(),
        'committeeId': _selectedCommitteeId,
        'committeeName': _selectedCommitteeName,
        'gender': _selectedGender,
        'hasTshirt': _hasTshirt,
        // Educational level is managed from promotions screen - not included here
        'university': _universityController.text.trim(),
      };

      // Always include profileImage in update data
      updateData['profileImage'] = newImageUrl;

      await volunteerProvider.updateVolunteerData(
        widget.volunteer.id,
        updateData,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ البيانات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<void> _resignVolunteer() async {
    final currentLevel = widget.volunteer.educationalLevel ?? '';
    final resignedLevel = FirebaseConstants.getResignedLevel(currentLevel);
    if (resignedLevel == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'تأكيد الاستقالة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          content: Text(
            'هل أنت متأكد من تغيير تصنيف ${widget.volunteer.name} من "$currentLevel" إلى "$resignedLevel"؟',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'تأكيد',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final volunteerProvider = Provider.of<VolunteerProvider>(
        context,
        listen: false,
      );
      await volunteerProvider.updateVolunteerData(widget.volunteer.id, {
        'educationalLevel': resignedLevel,
      });
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تغيير التصنيف إلى $resignedLevel',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                          'تفاصيل الملف الشخصي',
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
                        color: AppTheme.cardBackground,
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
                            ? Center(child: WhaleLoading(size: 32))
                            : (_selectedImage != null
                                  ? Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : (_imageUrl != null && _imageUrl!.isNotEmpty
                                        ? Image.network(
                                            _imageUrl!,
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                    child: WhaleLoading(
                                                      size: 32,
                                                    ),
                                                  );
                                                },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color: AppTheme.primary,
                                                  );
                                                },
                                          )
                                        : const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: AppTheme.primary,
                                          ))),
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
                            border: Border.all(
                              color: AppTheme.cardBackground,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: AppTheme.cardBackground,
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
                        readOnly: true,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'مطلوب';
                          final age = int.tryParse(v!);
                          if (age == null || age < 1 || age > 100) {
                            return 'سن غير صحيح';
                          }
                          return null;
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
                  validator: Validators.validateNationalId,
                  onChanged: (value) {
                    if (value.length == 14) {
                      final data = Validators.parseNationalId(value);
                      if (data != null) {
                        setState(() {
                          _birthDateController.text = data.birthDate;
                          _ageController.text = data.age.toString();
                          _selectedGender = data.gender;
                        });
                      }
                    }
                  },
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
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8, right: 4),
                            child: Text(
                              'اللجنة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: AppTheme.primary,
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
                                // Log the actual error
                                print(
                                  'Committee loading error: ${snapshot.error}',
                                );
                                print('Stack trace: ${snapshot.stackTrace}');
                                return _buildErrorDropdown();
                              }

                              // Add this null check
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
                                  color: AppTheme.cardBackground,
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
                                      color: AppTheme.textDark,
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          'اختر اللجنة',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            color: AppTheme.secondary,
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
                        enabled: false,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Gender and Join Date Row - النوع و تاريخ الانضمام
                Row(
                  children: [
                    // Join Date - تاريخ الانضمام
                    Expanded(
                      child: _buildDateFieldWithLabel(
                        controller: _joinDateController,
                        label: 'تاريخ الانضمام',
                        enabled: false,
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
                              color: AppTheme.cardBackground,
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
                                  color: AppTheme.textDark,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      'اختر النوع',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: AppTheme.secondary,
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

                // Educational Level and University Row - الدرجة التعليمية و الجامعة
                Row(
                  children: [
                    // University - الجامعة
                    Expanded(
                      child: _buildLabeledTextField(
                        controller: _universityController,
                        label: 'الجامعة',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Educational Level - الدرجة التعليمية (READ ONLY)
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
                          // Changed from DropdownButton to a read-only display
                          Container(
                            height: 56, // Match the dropdown height
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Colors.grey[100], // Light grey for read-only
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors
                                    .grey[400]!, // Grey border for read-only
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(
                                  Icons.school,
                                  size: 20,
                                  color: AppTheme.secondary,
                                ),
                                Expanded(
                                  child: Text(
                                    _educationalLevelController.text.isNotEmpty
                                        ? _educationalLevelController.text
                                        : 'لا توجد درجة',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14,
                                      color:
                                          _educationalLevelController
                                              .text
                                              .isNotEmpty
                                          ? Colors.black
                                          : Colors.grey,
                                      fontWeight:
                                          _educationalLevelController
                                              .text
                                              .isNotEmpty
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Help text
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // T-shirt Checkbox - التيشيرت
                Row(
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

                const SizedBox(height: 32),

                // Save Button - حفظ (only if has permission)
                if (_canAddDelete)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.textLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: AppTheme.primary.withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? WhaleLoading(
                              size: 24,
                              color: AppTheme.cardBackground,
                            )
                          : const Text(
                              'حفظ',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                // Resign Button - استقالة (only for eligible levels with permission)
                if (_canAddDelete &&
                    FirebaseConstants.getResignedLevel(
                          widget.volunteer.educationalLevel ?? '',
                        ) !=
                        null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _resignVolunteer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'استقالة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                // No permission message
                if (!_canAddDelete)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ليس لديك صلاحية لتعديل البيانات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
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
    bool readOnly = false,
    ValueChanged<String>? onChanged,
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
          readOnly: readOnly,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: readOnly ? Colors.grey[700] : Colors.black,
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
            fillColor: readOnly ? Colors.grey[100] : Colors.white,
            hintText: 'أدخل $label',
            hintStyle: const TextStyle(
              fontFamily: 'Cairo',
              color: AppTheme.secondary,
              fontSize: 13,
            ),
          ),
          validator: validator,
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
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary, width: 1.5),
      ),
      child: Center(child: WhaleLoading(size: 20)),
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
    _ageController.dispose();
    _addressController.dispose();
    _nationalIdController.dispose();
    _birthDateController.dispose();
    _joinDateController.dispose();
    _educationalLevelController.dispose();
    _universityController.dispose();
    super.dispose();
  }
}
