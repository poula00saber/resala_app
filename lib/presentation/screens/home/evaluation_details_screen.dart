// ============================================
// FILE 2: lib/presentation/screens/home/volunteer_evaluation_details_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/evaluation_provider.dart';
import '../../themes/app_theme.dart';
import 'add_evaluation_screen.dart';

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
          icon: const Icon(Icons.arrow_forward, color: Colors.black),
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
              ),
              child: Icon(Icons.person, size: 60, color: AppTheme.primary),
            ),

            const SizedBox(height: 24),

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
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Evaluations Table
                  Container(
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
                    child: _buildEvaluationsContent(),
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
                            foregroundColor: Colors.white,
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
                            foregroundColor: Colors.white,
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
    return StreamBuilder<List<dynamic>>(
      stream: Provider.of<EvaluationProvider>(
        context,
      ).getEvaluationsForVolunteer(widget.volunteer.id),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        // Handle error state - FIXED HERE
        if (snapshot.hasError) {
          print('❌ Stream error: ${snapshot.error}');
          print('📋 Stack trace: ${snapshot.stackTrace}');

          // Check if the error is a Firebase permission error
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
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
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
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
              ),
            ),
          );
        }

        // Safely cast the data
        try {
          final evaluations = snapshot.data as List<dynamic>;
          print('✅ Loaded ${evaluations.length} evaluations');

          return _buildEvaluationsTable(evaluations);
        } catch (e) {
          print('❌ Error casting evaluations: $e');
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                'خطأ في تحميل البيانات',
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildEvaluationsTable(List<dynamic> evaluations) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              _buildTableHeader('الاسم', flex: 2),
              _buildTableHeader('التقييم', flex: 2),
              _buildTableHeader('الشهر', flex: 2),
              _buildTableHeader('ملاحظات', flex: 2),
            ],
          ),
        ),

        // Table Rows
        if (evaluations.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Text(
              'لا توجد تقييمات',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
            ),
          )
        else
          ...evaluations.map((evaluation) {
            try {
              // Try to access properties safely
              final notes = evaluation.notes?.toString() ?? '-';
              final rating = evaluation.rating?.toString() ?? '0';
              final evaluatorName =
                  evaluation.evaluatorName?.toString() ?? 'غير معروف';
              final month = evaluation.month?.toString() ?? '-';

              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    _buildTableCell(evaluatorName, flex: 2),
                    _buildTableCell('$rating/10', flex: 2),
                    _buildTableCell(month, flex: 2),
                    _buildTableCell(notes, flex: 2),
                  ],
                ),
              );
            } catch (e) {
              print('❌ Error rendering evaluation: $e');
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
    );
  }

  Widget _buildTableHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
