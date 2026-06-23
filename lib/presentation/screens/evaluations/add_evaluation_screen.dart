import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/evaluation_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/whale_loading.dart';
import '../../../data/models/evaluation_model.dart';

class AddEvaluationScreen extends StatefulWidget {
  final dynamic volunteer;

  const AddEvaluationScreen({super.key, required this.volunteer});

  @override
  State<AddEvaluationScreen> createState() => _AddEvaluationScreenState();
}

class _AddEvaluationScreenState extends State<AddEvaluationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _evaluationNameController =
      TextEditingController();
  final TextEditingController _evaluatorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int _rating = 5; // Out of 10
  bool _isLoading = false;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        _monthController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveEvaluation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final evaluationProvider = Provider.of<EvaluationProvider>(
      context,
      listen:
          false, // chhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhheccccccccccccccccccccckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
    );

    final evaluation = EvaluationModel(
      id: '',
      volunteerId: widget.volunteer.id,
      volunteerName: widget.volunteer.name,
      evaluationName: _evaluationNameController.text.trim(),
      evaluatorName: _evaluatorController.text,
      month: _monthController.text,
      year: DateTime.now().year,
      rating: _rating,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
    );

    final success = await evaluationProvider.createEvaluation(evaluation);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إضافة التقييم بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'فشل إضافة التقييم',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 400,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textLight),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'إضافة تقييم',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cardBackground,
                      ),
                    ),
                    const SizedBox(width: 48), // For balance
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Volunteer Info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          'المتطوع: ${widget.volunteer.name}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Evaluation Name
                      _buildTextField(
                        controller: _evaluationNameController,
                        label: 'اسم التقييم',
                        validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                      ),

                      const SizedBox(height: 16),

                      // Evaluator Name
                      _buildTextField(
                        controller: _evaluatorController,
                        label: 'اسم القائم بالتقييم',
                        validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                      ),

                      const SizedBox(height: 16),

                      // Date
                      _buildTextField(
                        controller: _dateController,
                        label: 'تاريخ التقييم',
                        readOnly: true,
                        onTap: _selectDate,
                        validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                      ),

                      const SizedBox(height: 16),

                      // Month
                      _buildTextField(
                        controller: _monthController,
                        label: 'الشهر التقييم',
                        readOnly: true,
                        validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                      ),

                      const SizedBox(height: 16),

                      // Rating Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'التقييم',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Star Rating (10 stars) - FIXED OVERFLOW
                            Container(
                              constraints: const BoxConstraints(
                                maxWidth: 350, // Limit the width
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 2, // Reduced spacing
                                runSpacing: 2,
                                children: List.generate(10, (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _rating = index + 1;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ), // Reduced margin
                                      child: Icon(
                                        index < _rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: const Color(0xFFFFB800),
                                        size: 28, // Slightly smaller size
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Text(
                              '$_rating / 10',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notes
                      _buildTextField(
                        controller: _notesController,
                        label: 'الملاحظات',
                        maxLines: 4,
                      ),

                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveEvaluation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.textLight,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  'حفظ التقييم',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        color: AppTheme.textDark,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          fontFamily: 'Cairo',
          color: Colors.grey[500],
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppTheme.cardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    _evaluationNameController.dispose();
    _evaluatorController.dispose();
    _dateController.dispose();
    _monthController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
