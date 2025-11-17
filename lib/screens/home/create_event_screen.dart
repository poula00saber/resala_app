// ============================================
// FILE: lib/screens/home/create_event_screen.dart
// Copy this ENTIRE file
// ============================================

import 'package:flutter/material.dart';
import 'package:resala/screens/themes/app_theme.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _selectedType = 'قافلة';
  String? _selectedMeetingPlace;
  String? _selectedAdministrativeType;

  final List<String> _eventTypes = [
    'قافلة',
    'كرنفال',
    'يوم عائلي',
    'اجتماع',
    'اداريات',
  ];

  final List<String> _meetingPlaces = [
    'أونلاين',
    'أوفلاين بالفرع',
    'أوفلاين بالخارج',
  ];

  final List<String> _administrativeTypes = [
    'اجتماع تخطيطي',
    'مراجعة مالية',
    'تقييم أداء',
    'اجتماع طوارئ',
    'اجتماع دوري',
    'مراجعة مشاريع',
    'تدريب إداري',
    'اجتماع فريق',
    'اجتماع مجلس إدارة',
    'اجتماع لجنة',
  ];

  bool _needsLocation() {
    return _selectedType == 'قافلة' ||
        _selectedType == 'كرنفال' ||
        _selectedType == 'يوم عائلي';
  }

  bool _needsMeetingPlace() {
    return _selectedType == 'اجتماع';
  }

  bool _needsAdministrativeType() {
    return _selectedType == 'اداريات';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة حدث جديد"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
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
                        'إضافة حدث جديد',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

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
                            _locationController.clear();
                            _selectedMeetingPlace = null;
                            _selectedAdministrativeType = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      if (_needsLocation()) ...[
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'المكان',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال المكان';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_needsMeetingPlace()) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedMeetingPlace,
                          decoration: const InputDecoration(
                            labelText: 'مكان الاجتماع',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.meeting_room),
                          ),
                          items: _meetingPlaces.map((String place) {
                            return DropdownMenuItem<String>(
                              value: place,
                              child: Text(place),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedMeetingPlace = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى اختيار مكان الاجتماع';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_needsAdministrativeType()) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedAdministrativeType,
                          decoration: const InputDecoration(
                            labelText: 'نوع الإدارية',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.admin_panel_settings),
                          ),
                          items: _administrativeTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedAdministrativeType = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى اختيار نوع الإدارية';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

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

                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ الحدث',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: _selectDate,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال تاريخ الحدث';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _createEvent();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child: const Text('حفظ الحدث'),
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

  void _createEvent() {
    final newEvent = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': _titleController.text,
      'type': _selectedType,
      'description': _descriptionController.text,
      'date': _dateController.text,
      'volunteers': [],
    };

    if (_needsLocation()) {
      newEvent['location'] = _locationController.text;
    }

    if (_needsMeetingPlace()) {
      newEvent['meetingPlace'] = _selectedMeetingPlace;
    }

    if (_needsAdministrativeType()) {
      newEvent['administrativeType'] = _selectedAdministrativeType;
    }

    Navigator.pop(context, newEvent);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم إضافة الحدث بنجاح')));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
