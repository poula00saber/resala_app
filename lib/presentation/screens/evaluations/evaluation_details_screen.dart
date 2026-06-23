// ============================================
// FILE 2: lib/presentation/screens/home/volunteer_evaluation_details_screen.dart
// UPDATED: Fixed notes display to show full text with wrapping
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/evaluation_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/whale_loading.dart';
import 'add_evaluation_screen.dart';
import '../../../data/models/evaluation_model.dart';

class VolunteerEvaluationDetailsScreen extends StatefulWidget {
  final dynamic volunteer;

  const VolunteerEvaluationDetailsScreen({super.key, required this.volunteer});

  @override
  State<VolunteerEvaluationDetailsScreen> createState() =>
      _VolunteerEvaluationDetailsScreenState();
}

class _VolunteerEvaluationDetailsScreenState
    extends State<VolunteerEvaluationDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.volunteer.name;
    _phoneController.text = widget.volunteer.phone;
    _ageController.text = widget.volunteer.age?.toString() ?? '';
  }

  void _openAddEvaluationDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AddEvaluationScreen(volunteer: widget.volunteer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE6D5F5),
                shape: BoxShape.circle,
                image:
                    widget.volunteer.profileImage != null &&
                        widget.volunteer.profileImage!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.volunteer.profileImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child:
                  widget.volunteer.profileImage == null ||
                      widget.volunteer.profileImage!.isEmpty
                  ? Icon(Icons.person, size: 60, color: AppTheme.primary)
                  : null,
            ),

            const SizedBox(height: 24),

            FutureBuilder<double>(
              future: Provider.of<EvaluationProvider>(
                context,
                listen: false,
              ).getAverageRating(widget.volunteer.id),
              builder: (context, snapshot) {
                final avg = snapshot.data ?? 0.0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'متوسط التقييم: ${avg.toStringAsFixed(1)}/10',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                );
              },
            ),

            // Name and Basic Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  // Name Field
                  _buildTextField(controller: _nameController, label: 'الاسم'),
                  const SizedBox(height: 12),

                  // Age and Phone Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _phoneController,
                          label: 'رقم التليفون',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _ageController,
                          label: 'السن',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // التقييمات Label
                  const Text(
                    'التقييمات',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Evaluations Table
                  Container(
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 800,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [_buildEvaluationsContent()],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _openAddEvaluationDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.textLight,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'إضافة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.textLight,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
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

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationsContent() {
    return StreamBuilder<List<EvaluationModel>>(
      stream: Provider.of<EvaluationProvider>(
        context,
      ).getEvaluationsForVolunteer(widget.volunteer.id),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: WhaleLoading()),
          );
        }

        // Handle error state
        if (snapshot.hasError) {
          String errorMessage = 'حدث خطأ في تحميل التقييمات';
          if (snapshot.error.toString().contains('PERMISSION_DENIED') ||
              snapshot.error.toString().contains(
                'Missing or insufficient permissions',
              )) {
            errorMessage = 'ليس لديك صلاحية لعرض التقييمات';
          }

          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                errorMessage,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppTheme.secondary,
                ),
              ),
            ),
          );
        }

        // Check if data exists
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text(
                'لا توجد تقييمات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppTheme.secondary,
                ),
              ),
            ),
          );
        }

        // Safely cast the data
        final evaluations = snapshot.data ?? [];
        return _buildEvaluationsTable(evaluations);
      },
    );
  }

  Widget _buildEvaluationsTable(List<EvaluationModel> evaluations) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              SizedBox(width: 40, child: _buildTableHeader('#')),
              const SizedBox(width: 20),
              SizedBox(width: 100, child: _buildTableHeader('الاسم')),
              const SizedBox(width: 20),
              SizedBox(width: 120, child: _buildTableHeader('اسم التقييم')),
              const SizedBox(width: 20),
              SizedBox(width: 80, child: _buildTableHeader('التقييم')),
              const SizedBox(width: 20),
              SizedBox(width: 100, child: _buildTableHeader('الشهر')),
              const SizedBox(width: 20),
              SizedBox(width: 200, child: _buildTableHeader('ملاحظات')),
            ],
          ),
        ),

        // Table Rows
        if (evaluations.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Text(
              'لا توجد تقييمات',
              style: TextStyle(fontFamily: 'Cairo', color: AppTheme.secondary),
            ),
          )
        else
          ...evaluations.asMap().entries.map((entry) {
            final index = entry.key;
            final evaluation = entry.value;
            try {
              final notes = evaluation.notes?.toString() ?? '-';
              final rating = evaluation.rating?.toString() ?? '0';
              final evaluatorName = evaluation.evaluatorName.toString().isEmpty
                  ? 'غير معروف'
                  : evaluation.evaluatorName.toString();
              final month = evaluation.month?.toString() ?? '-';
              final evaluationName =
                  evaluation.evaluationName.toString().isEmpty
                  ? '-'
                  : evaluation.evaluationName.toString();

              return Dismissible(
                key: ValueKey(evaluation.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return await _confirmDeleteEvaluation(evaluation);
                },
                background: Container(
                  color: Colors.red.withOpacity(0.1),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: _buildTableCell((index + 1).toString()),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 100,
                        child: _buildTableCell(evaluatorName),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 120,
                        child: _buildTableCell(evaluationName),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(width: 80, child: _buildTableCell('$rating/10')),
                      const SizedBox(width: 20),
                      SizedBox(width: 100, child: _buildTableCell(month)),
                      const SizedBox(width: 20),
                      SizedBox(width: 200, child: _buildNotesCell(notes)),
                    ],
                  ),
                ),
              );
            } catch (e) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: const Text(
                  'خطأ في عرض البيانات',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
                ),
              );
            }
          }),
      ],
    );
  }

  Future<bool> _confirmDeleteEvaluation(EvaluationModel evaluation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التقييم', style: TextStyle(fontFamily: 'Cairo')),
        content: Text(
          'هل تريد حذف التقييم "${evaluation.evaluationName}"؟',
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
              'حذف',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    final provider = Provider.of<EvaluationProvider>(context, listen: false);
    final success = await provider.deleteEvaluation(evaluation.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'تم حذف التقييم' : 'فشل حذف التقييم',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }

    return success;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
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
        fillColor: AppTheme.cardBackground,
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
    );
  }

  Widget _buildTableHeader(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          color: AppTheme.textDark,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Special widget for notes that can expand
  Widget _buildNotesCell(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          color: AppTheme.textDark,
        ),
        textAlign: TextAlign.right,
        maxLines: null,
        overflow: TextOverflow.visible,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
