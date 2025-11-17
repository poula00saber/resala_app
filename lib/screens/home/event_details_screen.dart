import 'package:flutter/material.dart';
import 'package:resala/screens/home/volunteer_management_screen.dart';
import 'package:resala/screens/themes/app_theme.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _volunteersController;
  late TextEditingController _dateController;

  late String _selectedType;
  final List<String> _eventTypes = [
    'اجتماع',
    'توزيع',
    'توعية',
    'بيئة',
    'تدريب',
    'معرض',
    'مخيم',
    'آخر',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event['title']);
    _descriptionController = TextEditingController(
      text: widget.event['description'],
    );
    _locationController = TextEditingController(text: widget.event['location']);
    _volunteersController = TextEditingController(
      text: widget.event['volunteersCount'].toString(),
    );
    _dateController = TextEditingController(text: widget.event['date']);
    _selectedType = widget.event['type'];
  }

  void _navigateToVolunteerManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VolunteerManagementScreen(event: widget.event),
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // TODO: Update event in Firebase
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث الحدث بنجاح!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تفاصيل الحدث"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'حفظ التغييرات',
          ),
        ],
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
                        'تعديل بيانات الحدث',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // عنوان الحدث
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'عنوان الحدث',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال عنوان الحدث';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // نوع الحدث
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'نوع الحدث',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _eventTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedType = newValue!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى اختيار نوع الحدث';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // وصف الحدث
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'وصف الحدث',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال وصف الحدث';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // الموقع
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'موقع الحدث',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال موقع الحدث';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // عدد المتطوعين
                      TextFormField(
                        controller: _volunteersController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'عدد المتطوعين',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال عدد المتطوعين';
                          }
                          if (int.tryParse(value) == null) {
                            return 'يرجى إدخال رقم صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // تاريخ الحدث
                      TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ الحدث (YYYY-MM-DD)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال تاريخ الحدث';
                          }
                          final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                          if (!dateRegex.hasMatch(value)) {
                            return 'صيغة التاريخ يجب أن تكون YYYY-MM-DD';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Volunteer Management Section
                      Card(
                        color: AppTheme.primary.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إدارة المتطوعين',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'يمكنك إضافة متطوعين جدد أو اختيار من قاعدة البيانات',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _navigateToVolunteerManagement,
                                      icon: const Icon(Icons.people_alt),
                                      label: const Text('إدارة المتطوعين'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child: const Text('حفظ التغييرات'),
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
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _volunteersController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
