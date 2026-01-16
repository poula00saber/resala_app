// ============================================
// FILE: lib/presentation/screens/promotions/volunteer_promotion_screen.dart
// UPDATED VERSION
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/core/constants/firebase_constants.dart';
import 'package:resala/data/models/promotion_model.dart';
import 'package:resala/data/repositories/promotion_repository.dart';
import 'package:resala/presentation/providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';

class VolunteerPromotionScreen extends StatefulWidget {
  final dynamic volunteer;

  const VolunteerPromotionScreen({super.key, required this.volunteer});

  @override
  State<VolunteerPromotionScreen> createState() =>
      _VolunteerPromotionScreenState();
}

class _VolunteerPromotionScreenState extends State<VolunteerPromotionScreen> {
  final List<String> _educationalLevels = FirebaseConstants.educationalLevels;


  late String _currentLevel;
  late int _currentLevelIndex;
  late PromotionRepository _promotionRepository;
  PromotionRequirement? _promotionRequirement;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _promotionRepository = PromotionRepository();
    _currentLevel = widget.volunteer.educationalLevel ?? 'جدد';
    _currentLevelIndex = _educationalLevels.indexOf(_currentLevel);
    _loadPromotionRequirements();
  }

  Future<void> _loadPromotionRequirements() async {
    if (_currentLevelIndex < _educationalLevels.length - 1) {
      final nextLevel = _educationalLevels[_currentLevelIndex + 1];
      _promotionRequirement = await _promotionRepository
          .getPromotionRequirements(
            widget.volunteer.id,
            _currentLevel,
            nextLevel,
          );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleRequirement(int index) async {
    if (_promotionRequirement == null) return;

    final requirement = _promotionRequirement!.requirements[index];
    final newStatus = !requirement.isCompleted;

    final success = await _promotionRepository.updateRequirementStatus(
      _promotionRequirement!.id,
      requirement.id,
      newStatus,
    );

    if (success) {
      await _loadPromotionRequirements(); // Reload to get updated data
    }
  }

  Future<void> _promoteVolunteer() async {
    if (_currentLevelIndex < _educationalLevels.length - 1) {
      final nextLevel = _educationalLevels[_currentLevelIndex + 1];

      // Update volunteer level
      await Provider.of<VolunteerProvider>(
        context,
        listen: false,
      ).updateVolunteerLevel(widget.volunteer.id, nextLevel);

      // Delete old promotion requirements
      if (_promotionRequirement != null) {
        await _promotionRepository.deletePromotionRequirements(
          _promotionRequirement!.id,
        );
      }

      // Update UI
      setState(() {
        _currentLevelIndex++;
        _currentLevel = nextLevel;
        _promotionRequirement = null;
      });

      // Load new requirements for next level (if any)
      if (_currentLevelIndex < _educationalLevels.length - 1) {
        await _loadPromotionRequirements();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم ترقية ${widget.volunteer.name} إلى $_currentLevel',
            style: const TextStyle(fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMaxLevel = _currentLevelIndex == _educationalLevels.length - 1;
    final String nextLevel = isMaxLevel
        ? 'أعلى مستوى'
        : _educationalLevels[_currentLevelIndex + 1];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.volunteer.name,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Level Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'المستوى الحالي',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentLevel,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        if (!isMaxLevel) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.arrow_upward,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'المستوى التالي: $nextLevel',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          if (_promotionRequirement != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                '${_promotionRequirement!.completedCount}/${_promotionRequirement!.totalCount} مكتمل',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Requirements Section
                  if (!isMaxLevel && _promotionRequirement != null) ...[
                    const Text(
                      'متطلبات الترقية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'يجب إكمال جميع المتطلبات لتفعيل زر الترقية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Requirements Checkboxes
                    Column(
                      children: List.generate(
                        _promotionRequirement!.requirements.length,
                        (index) => _buildRequirementItem(
                          _promotionRequirement!.requirements[index],
                          index,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Promotion Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (!isMaxLevel &&
                              _promotionRequirement != null &&
                              _promotionRequirement!.isComplete)
                          ? _promoteVolunteer
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (!isMaxLevel &&
                                _promotionRequirement != null &&
                                _promotionRequirement!.isComplete)
                            ? AppTheme.primary
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isMaxLevel ? 'أعلى مستوى' : 'ترقية إلى $nextLevel',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (isMaxLevel) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'المتطوع وصل إلى أعلى مستوى',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildRequirementItem(Requirement requirement, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: requirement.isCompleted ? AppTheme.primary : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleRequirement(index),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: requirement.isCompleted
                      ? AppTheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: requirement.isCompleted
                        ? AppTheme.primary
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: requirement.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),

              const SizedBox(width: 16),

              // Requirement Description
              Expanded(
                child: Text(
                  requirement.description,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: requirement.isCompleted
                        ? AppTheme.primary
                        : Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              if (requirement.completedAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  _formatDate(requirement.completedAt!),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
