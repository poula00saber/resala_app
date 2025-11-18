// ============================================
// FILE: lib/presentation/screens/events/create_event_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/utils/validators.dart';

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

  String _selectedType = FirebaseConstants.typeQafela;
  String? _selectedMeetingPlace;
  String? _selectedAdministrativeType;

  final List<String> _eventTypes = [
    FirebaseConstants.typeQafela,
    FirebaseConstants.typeKarnafal,
    FirebaseConstants.typeFamilyDay,
    FirebaseConstants.typeMeeting,
    FirebaseConstants.typeAdministrative,
  ];

  final List<String> _meetingPlaces = [
    FirebaseConstants.meetingOnline,
    FirebaseConstants.meetingOfflineBranch,
    FirebaseConstants.meetingOfflineExternal,
  ];

  bool _isLoading = false;

  bool _needsLocation() {
    return _selectedType == FirebaseConstants.typeQafela ||
        _selectedType == FirebaseConstants.typeKarnafal ||
        _selectedType == FirebaseConstants.typeFamilyDay;
  }

  bool _needsMeetingPlace() {
    return _selectedType == FirebaseConstants.typeMeeting;
  }

  bool _needsAdministrativeType() {
    return _selectedType == FirebaseConstants.typeAdministrative;
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

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    final eventId = await eventProvider.createEvent(
      title: _titleController.text,
      type: _selectedType,
      date: _dateController.text,
      description: _descriptionController.text,
      location: _needsLocation() ? _locationController.text : null,
      meetingPlace: _needsMeetingPlace() ? _selectedMeetingPlace : null,
      administrativeType: _needsAdministrativeType()
          ? _selectedAdministrativeType
          : null,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (eventId != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إضافة الحدث بنجاح')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل إضافة الحدث')));
      }
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

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'عنوان الحدث',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        validator: (value) =>
                            Validators.validateRequired(value, 'عنوان الحدث'),
                      ),
                      const SizedBox(height: 16),

                      // Event Type
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

                      // Conditional: Location
                      if (_needsLocation()) ...[
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'المكان',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (value) =>
                              Validators.validateRequired(value, 'المكان'),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Conditional: Meeting Place
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
                          validator: (value) => Validators.validateRequired(
                            value,
                            'مكان الاجتماع',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Conditional: Administrative Type
                      if (_needsAdministrativeType()) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedAdministrativeType,
                          decoration: const InputDecoration(
                            labelText: 'نوع الإدارية',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.admin_panel_settings),
                          ),
                          items: FirebaseConstants.administrativeTypes.map((
                            String type,
                          ) {
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
                          validator: (value) => Validators.validateRequired(
                            value,
                            'نوع الإدارية',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'وصف الحدث',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            Validators.validateRequired(value, 'وصف الحدث'),
                      ),
                      const SizedBox(height: 16),

                      // Date
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ الحدث',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: _selectDate,
                        validator: (value) =>
                            Validators.validateRequired(value, 'تاريخ الحدث'),
                      ),
                      const SizedBox(height: 30),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _createEvent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('حفظ الحدث'),
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
    _dateController.dispose();
    super.dispose();
  }
}
