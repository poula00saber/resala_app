import 'package:flutter/material.dart';
import 'package:resala/presentation/themes/app_theme.dart';
import '../../../core/utils/validators.dart';

class AddVolunteerScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onVolunteerAdded;

  const AddVolunteerScreen({super.key, required this.onVolunteerAdded});

  @override
  State<AddVolunteerScreen> createState() => _AddVolunteerScreenState();
}

class _AddVolunteerScreenState extends State<AddVolunteerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _tribeController = TextEditingController();

  void _saveVolunteer() {
    if (_formKey.currentState!.validate()) {
      final newVolunteer = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text,
        'year': _yearController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'nationalId': _nationalIdController.text,
        'birthDate': _birthDateController.text,
        'tribe': _tribeController.text,
      };

      widget.onVolunteerAdded(newVolunteer);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إضافة المتطوع بنجاح!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة متطوع جديد"),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textLight,
      ),
      body: Container(
        color: AppTheme.primary,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'بيانات المتطوع الجديد',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // الاسم
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال الاسم';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // السنة
                      TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'السنة',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال السنة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // رقم التليفون
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم التليفون',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال رقم التليفون';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // العنوان
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'العنوان',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال العنوان';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // الرقم القومي
                      TextFormField(
                        controller: _nationalIdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الرقم القومي',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        validator: Validators.validateNationalId,
                        onChanged: (value) {
                          if (value.length == 14) {
                            final data = Validators.parseNationalId(value);
                            if (data != null) {
                              setState(() {
                                _birthDateController.text = data.birthDate;
                              });
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // تاريخ الميلاد
                      TextFormField(
                        controller: _birthDateController,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ الميلاد',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.cake),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال تاريخ الميلاد';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // القبيلة
                      TextFormField(
                        controller: _tribeController,
                        decoration: const InputDecoration(
                          labelText: 'القبيلة',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال القبيلة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveVolunteer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: AppTheme.textLight,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child: const Text('حفظ المتطوع'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child: const Text('إلغاء'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nationalIdController.dispose();
    _birthDateController.dispose();
    _tribeController.dispose();
    super.dispose();
  }
}
