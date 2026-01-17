// ============================================
// FILE: lib/presentation/screens/interviews/interview_details_screen.dart
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

  // In InterviewDetailsScreen _saveInterview method:
  Future<void> _saveInterview() async {
    if (_passed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد نتيجة المقابلة'),
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

    // Parse grade
    final totalGrade = int.tryParse(_gradeController.text.trim()) ?? 0;

    final interviewProvider = Provider.of<InterviewProvider>(
      context,
      listen: false,
    );

    final success = await interviewProvider.updateInterviewAnswers(
      interviewId: widget.interview.id,
      answers: answers,
      passed: _passed,
      totalGrade: totalGrade,
      notes: _notesController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (success) {
      // Update volunteer's hasInterview status if passed
      if (_passed == true) {
        final volunteerProvider = Provider.of<VolunteerProvider>(
          context,
          listen: false,
        );
        await volunteerProvider.updateVolunteerData(
          widget.interview.volunteerId,
          {'hasInterview': true},
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _passed! ? 'تم حفظ المقابلة بنجاح ✓' : 'تم حفظ المقابلة (راسب)',
          ),
          backgroundColor: _passed! ? Colors.green : Colors.orange,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء حفظ المقابلة'),
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.interview.volunteerName,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.primary),
            onPressed: _isSaving ? null : _saveInterview,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Interview Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'معلومات المقابلة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تاريخ المقابلة: ${_formatDate(widget.interview.interviewDate)}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.interview.totalGrade != null)
                      Row(
                        children: [
                          Icon(
                            widget.interview.passed == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 18,
                            color: widget.interview.passed == true
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'النتيجة: ${widget.interview.passed == true ? 'ناجح' : 'راسب'}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.interview.passed == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.score, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'الدرجة: ${widget.interview.totalGrade}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Result Selection
            const Text(
              'نتيجة المقابلة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text(
                      'ناجح',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    selected: _passed == true,
                    onSelected: (selected) {
                      setState(() {
                        _passed = selected ? true : null;
                      });
                    },
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: _passed == true ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text(
                      'راسب',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    selected: _passed == false,
                    onSelected: (selected) {
                      setState(() {
                        _passed = selected ? false : null;
                      });
                    },
                    selectedColor: Colors.red,
                    labelStyle: TextStyle(
                      color: _passed == false ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Total Grade
            TextField(
              controller: _gradeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'الدرجة الكلية',
                hintText: 'أدخل الدرجة الكلية',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.score),
              ),
            ),

            const SizedBox(height: 24),

            // Interview Questions
            const Text(
              'أسئلة المقابلة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'أجب على جميع الأسئلة بالتفصيل',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // Questions List
            ...List.generate(FirebaseConstants.interviewQuestions.length, (
              index,
            ) {
              final question = FirebaseConstants.interviewQuestions[index];
              return _buildQuestionCard(
                index + 1,
                question,
                _answerControllers[index],
              );
            }).expand((widget) => [widget, const SizedBox(height: 16)]),

            // Notes
            const Text(
              'ملاحظات إضافية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'أدخل أي ملاحظات إضافية عن المقابلة...',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveInterview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'حفظ المقابلة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    int number,
    String question,
    TextEditingController controller,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'اكتب إجابتك هنا...',
                hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
