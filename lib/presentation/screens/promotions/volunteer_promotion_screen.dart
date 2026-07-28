// ============================================
// FILE: lib/presentation/screens/promotions/volunteer_promotion_screen.dart
// UPDATED: New hierarchy with age checks
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/core/constants/firebase_constants.dart';
import 'package:resala/data/models/promotion_model.dart';
import 'package:resala/presentation/providers/promotion_provider.dart';
import 'package:resala/presentation/providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/whale_loading.dart';

class VolunteerPromotionScreen extends StatefulWidget {
  final dynamic volunteer;

  const VolunteerPromotionScreen({super.key, required this.volunteer});

  @override
  State<VolunteerPromotionScreen> createState() =>
      _VolunteerPromotionScreenState();
}

class _VolunteerPromotionScreenState extends State<VolunteerPromotionScreen> {
  late String _currentLevel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.volunteer.educationalLevel ?? 'جدد';
    _loadPromotionRequirements();
  }

  Future<void> _loadPromotionRequirements() async {
    final promotionProvider = Provider.of<PromotionProvider>(
      context,
      listen: false,
    );

    final nextLevel = FirebaseConstants.getNextLevel(
      _currentLevel,
      age: widget.volunteer.age,
    );

    if (nextLevel != null) {
      await promotionProvider.loadPromotionRequirements(
        volunteerId: widget.volunteer.id,
        currentLevel: _currentLevel,
        nextLevel: nextLevel,
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleRequirement(int index) async {
    final promotionProvider = Provider.of<PromotionProvider>(
      context,
      listen: false,
    );

    final requirement =
        promotionProvider.currentPromotionRequirement!.requirements[index];
    final newStatus = !requirement.isCompleted;

    await promotionProvider.toggleRequirementStatus(
      requirementId: requirement.id,
      isCompleted: newStatus,
    );
  }

  Future<void> _promoteVolunteer() async {
    final nextLevel = FirebaseConstants.getNextLevel(
      _currentLevel,
      age: widget.volunteer.age,
    );

    if (nextLevel != null) {
      // Special check for شبل مميز to مشروع مسئول
      if (_currentLevel == 'شبل مميز' && nextLevel == 'مشروع مسئول') {
        if (widget.volunteer.age < 17) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'لا يمكن الترقية: يجب أن يكون المتطوع فوق سن 17',
                style: TextStyle(fontFamily: 'Cairo'),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      // Update volunteer level
      await Provider.of<VolunteerProvider>(
        context,
        listen: false,
      ).updateVolunteerLevel(widget.volunteer.id, nextLevel);

      // Delete old promotion requirements
      final promotionProvider = Provider.of<PromotionProvider>(
        context,
        listen: false,
      );
      await promotionProvider.deleteCurrentPromotionRequirements();

      // Update UI
      setState(() {
        _currentLevel = nextLevel;
      });

      // Load new requirements for next level (if any)
      final newNextLevel = FirebaseConstants.getNextLevel(
        nextLevel,
        age: widget.volunteer.age,
      );
      if (newNextLevel != null) {
        await promotionProvider.loadPromotionRequirements(
          volunteerId: widget.volunteer.id,
          currentLevel: nextLevel,
          nextLevel: newNextLevel,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم ترقية ${widget.volunteer.name} إلى $nextLevel',
            style: const TextStyle(fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  Future<void> _returnFromResignation() async {
    final activeLevel = FirebaseConstants.getActiveLevel(_currentLevel);
    if (activeLevel == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'تأكيد الإعادة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'هل تريد إعادة ${widget.volunteer.name} من $_currentLevel إلى $activeLevel؟',
          style: const TextStyle(fontFamily: 'Cairo'),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'تأكيد',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await Provider.of<VolunteerProvider>(
      context,
      listen: false,
    ).updateVolunteerLevel(widget.volunteer.id, activeLevel);

    setState(() {
      _currentLevel = activeLevel;
    });

    // Load promotion requirements for the active level
    final nextLevel = FirebaseConstants.getNextLevel(
      activeLevel,
      age: widget.volunteer.age,
    );
    if (nextLevel != null) {
      await Provider.of<PromotionProvider>(
        context,
        listen: false,
      ).loadPromotionRequirements(
        volunteerId: widget.volunteer.id,
        currentLevel: activeLevel,
        nextLevel: nextLevel,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إعادة ${widget.volunteer.name} كـ $activeLevel',
            style: const TextStyle(fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final promotionProvider = Provider.of<PromotionProvider>(context);
    final nextLevel = FirebaseConstants.getNextLevel(
      _currentLevel,
      age: widget.volunteer.age,
    );
    final bool isMaxLevel = nextLevel == null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.volunteer.name,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading || promotionProvider.isLoading
          ? Center(child: WhaleLoading())
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
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.05),
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
                            color: AppTheme.secondary,
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
                        // Show age requirement warning for شبل مميز
                        if (_currentLevel == 'شبل مميز' &&
                            widget.volunteer.age < 17)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'يجب أن يكون المتطوع فوق سن 17 للترقية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
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
                          if (promotionProvider.currentPromotionRequirement !=
                              null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                '${promotionProvider.currentPromotionRequirement!.completedCount}/${promotionProvider.currentPromotionRequirement!.totalCount} مكتمل',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Requirements Section
                  if (!isMaxLevel &&
                      promotionProvider.currentPromotionRequirement !=
                          null) ...[
                    const Text(
                      'متطلبات الترقية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يجب إكمال جميع المتطلبات لترقية ${widget.volunteer.name} من $_currentLevel إلى $nextLevel',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Requirements Checkboxes
                    Column(
                      children: List.generate(
                        promotionProvider
                            .currentPromotionRequirement!
                            .requirements
                            .length,
                        (index) => _buildRequirementItem(
                          promotionProvider
                              .currentPromotionRequirement!
                              .requirements[index],
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
                              promotionProvider.currentPromotionRequirement !=
                                  null &&
                              promotionProvider
                                  .currentPromotionRequirement!
                                  .isComplete &&
                              // Additional check for age requirement
                              !(_currentLevel == 'شبل مميز' &&
                                  widget.volunteer.age < 17))
                          ? _promoteVolunteer
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (!isMaxLevel &&
                                promotionProvider.currentPromotionRequirement !=
                                    null &&
                                promotionProvider
                                    .currentPromotionRequirement!
                                    .isComplete &&
                                !(_currentLevel == 'شبل مميز' &&
                                    widget.volunteer.age < 17))
                            ? AppTheme.primary
                            : Colors.grey,
                        foregroundColor: AppTheme.textLight,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isMaxLevel
                            ? (FirebaseConstants.isResignedLevel(_currentLevel)
                                  ? 'مستقيل'
                                  : 'أعلى مستوى')
                            : (_currentLevel == 'شبل مميز' &&
                                  widget.volunteer.age < 17)
                            ? 'يجب أن يكون فوق 17 للترقية'
                            : 'ترقية من $_currentLevel إلى $nextLevel',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Return from resignation button
                  if (FirebaseConstants.isResignedLevel(_currentLevel)) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _returnFromResignation,
                        icon: const Icon(Icons.undo),
                        label: Text(
                          'إعادة كـ ${FirebaseConstants.getActiveLevel(_currentLevel)}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: AppTheme.textLight,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],

                  // Downgrade from تدريب to داخل متابعه
                  if (_currentLevel == 'تدريب') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text(
                                'تأكيد التغييز',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              content: Text(
                                'هل تريد خفض ${widget.volunteer.name} من تدريب إلى داخل متابعه؟',
                                style: const TextStyle(fontFamily: 'Cairo'),
                                textAlign: TextAlign.center,
                              ),
                              actionsAlignment: MainAxisAlignment.center,
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text(
                                    'إلغاء',
                                    style: TextStyle(fontFamily: 'Cairo'),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[800],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    'تأكيد',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmed != true) return;

                          // Perform downgrade
                          await Provider.of<VolunteerProvider>(
                            context,
                            listen: false,
                          ).updateVolunteerLevel(
                            widget.volunteer.id,
                            'داخل متابعه',
                          );

                          setState(() {
                            _currentLevel = 'داخل متابعه';
                          });

                          // Load promotion requirements for the downgraded level
                          final nextLevel = FirebaseConstants.getNextLevel(
                            _currentLevel,
                            age: widget.volunteer.age,
                          );
                          if (nextLevel != null) {
                            await promotionProvider.loadPromotionRequirements(
                              volunteerId: widget.volunteer.id,
                              currentLevel: _currentLevel,
                              nextLevel: nextLevel,
                            );
                          } else {
                            await promotionProvider
                                .deleteCurrentPromotionRequirements();
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم خفض ${widget.volunteer.name} إلى داخل متابعه',
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                  textAlign: TextAlign.center,
                                ),
                                backgroundColor: Colors.orange[800],
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.arrow_downward),
                        label: const Text(
                          'خفض إلى داخل متابعه',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          foregroundColor: AppTheme.textLight,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
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
    // Special handling for age requirement in شبل مميز
    bool isAgeRequirement = requirement.description.contains('فوق سن 17');
    bool canToggle = !isAgeRequirement || widget.volunteer.age >= 17;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: requirement.isCompleted ? AppTheme.primary : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: canToggle ? () => _toggleRequirement(index) : null,
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
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppTheme.textLight,
                      )
                    : (isAgeRequirement && widget.volunteer.age < 17)
                    ? Icon(Icons.block, size: 16, color: Colors.grey[400])
                    : null,
              ),

              const SizedBox(width: 16),

              // Requirement Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
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
                    ),
                    if (isAgeRequirement && widget.volunteer.age < 17)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'غير متاح (المتطوع تحت 17 سنة)',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (requirement.completedAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  _formatDate(requirement.completedAt!),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: AppTheme.secondary,
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
