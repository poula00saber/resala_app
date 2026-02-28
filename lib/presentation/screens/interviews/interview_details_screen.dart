// ============================================
// FILE: lib/presentation/screens/interviews/interview_details_screen.dart
// ENHANCED UI - SAME LOGIC (No changes to functionality)
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/core/constants/firebase_constants.dart';
import 'package:resala/data/models/interview_model.dart';
import 'package:resala/presentation/providers/interview_provider.dart';
import 'package:resala/presentation/providers/volunteer_provider.dart';
import 'package:resala/presentation/themes/app_theme.dart';

class InterviewDetailsScreen extends StatefulWidget {
  final InterviewModel interview;

  const InterviewDetailsScreen({super.key, required this.interview});

  @override
  State<InterviewDetailsScreen> createState() => _InterviewDetailsScreenState();
}

class _InterviewDetailsScreenState extends State<InterviewDetailsScreen> {
  final List<TextEditingController> _answerControllers = [];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  bool? _passed;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    print('\n📱 InterviewDetailsScreen opened');
    print('   Interview ID: ${widget.interview.id}');
    print('   Volunteer: ${widget.interview.volunteerName}');
    print('   Volunteer ID: ${widget.interview.volunteerId}');
    print('   Existing answers: ${widget.interview.answers.length}');

    // Initialize controllers with existing answers
    for (int i = 0; i < FirebaseConstants.interviewQuestions.length; i++) {
      final question = FirebaseConstants.interviewQuestions[i];
      final existingAnswer = widget.interview.answers[question] ?? '';
      _answerControllers.add(TextEditingController(text: existingAnswer));
    }

    // Initialize other fields
    _notesController.text = widget.interview.notes ?? '';
    _gradeController.text = widget.interview.totalGrade?.toString() ?? '';
    _passed = widget.interview.passed;

    print('   Initialized with passed status: $_passed');
  }

  @override
  void dispose() {
    for (final controller in _answerControllers) {
      controller.dispose();
    }
    _notesController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _saveInterview() async {
    print('\n💾 SAVING INTERVIEW');
    print('   Interview ID: ${widget.interview.id}');
    print('   Volunteer ID: ${widget.interview.volunteerId}');

    if (_passed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى تحديد نتيجة المقابلة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Collect all answers
    final Map<String, String> answers = {};
    for (int i = 0; i < FirebaseConstants.interviewQuestions.length; i++) {
      final question = FirebaseConstants.interviewQuestions[i];
      answers[question] = _answerControllers[i].text.trim();
    }

    print('   Collected ${answers.length} answers');

    // Parse grade
    final totalGrade = int.tryParse(_gradeController.text.trim()) ?? 0;
    print('   Total grade: $totalGrade');
    print('   Passed: $_passed');

    final interviewProvider = Provider.of<InterviewProvider>(
      context,
      listen: false,
    );

    // CRITICAL: We're UPDATING the existing interview, not creating a new one
    print(
      '   Calling updateInterviewAnswers for interview ID: ${widget.interview.id}',
    );

    final success = await interviewProvider.updateInterviewAnswers(
      interviewId: widget.interview.id, // THIS IS THE KEY - using existing ID
      answers: answers,
      passed: _passed,
      totalGrade: totalGrade,
      notes: _notesController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (success) {
      print('✅ Interview saved successfully');

      // Update volunteer's hasInterview status if passed
      if (_passed == true) {
        print('   Updating volunteer hasInterview status...');
        final volunteerProvider = Provider.of<VolunteerProvider>(
          context,
          listen: false,
        );
        await volunteerProvider.updateVolunteerData(
          widget.interview.volunteerId,
          {'hasInterview': true},
        );
        print('   ✅ Volunteer updated');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _passed! ? Icons.check_circle : Icons.info,
                color: AppTheme.cardBackground,
              ),
              const SizedBox(width: 8),
              Text(
                _passed! ? 'تم حفظ المقابلة بنجاح ✓' : 'تم حفظ المقابلة (راسب)',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ],
          ),
          backgroundColor: _passed! ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

      // Return true to indicate success
      Navigator.pop(context, true);
    } else {
      print('❌ Failed to save interview');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: AppTheme.textLight),
              SizedBox(width: 8),
              Text(
                'حدث خطأ أثناء حفظ المقابلة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
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
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.interview.volunteerName,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : const Icon(Icons.save, color: AppTheme.primary, size: 24),
              onPressed: _isSaving ? null : _saveInterview,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with interview info

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Interview Questions
                  _buildQuestionsSection(),

                  const SizedBox(height: 20),

                  // Notes
                  _buildNotesSection(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildSaveFAB(),
    );
  }

  Widget _buildResultSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                const Icon(
                  Icons.rate_review,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'تقييم المقابلة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Result Selection
            Text(
              'النتيجة النهائية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildResultChip(
                    label: 'ناجح',
                    selected: _passed == true,
                    color: Colors.green,
                    icon: Icons.check_circle,
                    onSelected: (selected) {
                      setState(() => _passed = selected ? true : null);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResultChip(
                    label: 'راسب',
                    selected: _passed == false,
                    color: Colors.red,
                    icon: Icons.cancel,
                    onSelected: (selected) {
                      setState(() => _passed = selected ? false : null);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Grade Input
            Text(
              'الدرجة الكلية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _gradeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'أدخل الدرجة',
                hintStyle: const TextStyle(color: AppTheme.secondary),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: const Icon(Icons.score, color: AppTheme.primary),
                suffix: const Text(
                  'من 100',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultChip({
    required String label,
    required bool selected,
    required Color color,
    required IconData icon,
    required Function(bool) onSelected,
  }) {
    return InkWell(
      onTap: () => onSelected(!selected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Icon(
              Icons.question_answer,
              color: AppTheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'أسئلة المقابلة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${FirebaseConstants.interviewQuestions.length} سؤال',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Questions List
        ...List.generate(FirebaseConstants.interviewQuestions.length, (index) {
          final question = FirebaseConstants.interviewQuestions[index];
          return _buildQuestionItem(
            index + 1,
            question,
            _answerControllers[index],
          );
        }).expand((widget) => [widget, const SizedBox(height: 12)]),
      ],
    );
  }

  Widget _buildQuestionItem(
    int number,
    String question,
    TextEditingController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Number
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary,
                        AppTheme.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: const TextStyle(
                        color: AppTheme.cardBackground,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Question Text
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Answer Input
            TextField(
              controller: controller,
              maxLines: 4,
              minLines: 2,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'أدخل إجابتك هنا...',
                hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppTheme.secondary,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Icon(Icons.note, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'ملاحظات إضافية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Notes Input
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'يمكنك إضافة أي ملاحظات إضافية عن المتطوع أو المقابلة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'اكتب ملاحظاتك هنا...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppTheme.secondary,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildResultSection(),
      ],
    );
  }

  Widget _buildSaveFAB() {
    return FloatingActionButton.extended(
      onPressed: _isSaving ? null : _saveInterview,
      backgroundColor: AppTheme.primary,
      foregroundColor: AppTheme.textLight,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.cardBackground,
              ),
            )
          : const Icon(Icons.save, size: 20),
      label: const Text(
        'حفظ المقابلة',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
