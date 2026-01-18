// ============================================
// FILE: lib/presentation/screens/events/create_event_screen.dart
// FIXED: Committee selection orElse error
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/committee_provider.dart';
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
  final TextEditingController _customEventTypeController =
      TextEditingController();

  String _selectedType = FirebaseConstants.typeQafela;
  String? _selectedMeetingPlace;
  String? _selectedAdministrativeType;
  String? _selectedCommitteeId;
  List<dynamic> _committees = [];

  final List<String> _eventTypes = [
    FirebaseConstants.typeQafela,
    FirebaseConstants.typeKarnafal,
    FirebaseConstants.typeFamilyDay,
    FirebaseConstants.typeMeeting,
    FirebaseConstants.typeAdministrative,
    'أخرى',
  ];

  final List<String> _meetingPlaces = [
    FirebaseConstants.meetingOnline,
    FirebaseConstants.meetingOfflineBranch,
    FirebaseConstants.meetingOfflineExternal,
  ];

  bool _isLoading = false;
  bool _showCustomEventTypeField = false;
  bool _showCommitteeSelection = false;

  @override
  void initState() {
    super.initState();
    _loadCommittees();
  }

  Future<void> _loadCommittees() async {
    final committeeProvider = Provider.of<CommitteeProvider>(
      context,
      listen: false,
    );
    setState(() {
      _committees = committeeProvider.committees;
    });
  }

  bool _needsLocation() {
    return true;
  }

  bool _needsMeetingPlace() {
    return _selectedType == FirebaseConstants.typeMeeting;
  }

  bool _needsAdministrativeType() {
    return _selectedType == FirebaseConstants.typeAdministrative;
  }

  bool _isCustomEventType() {
    return _selectedType == 'أخرى';
  }

  bool _isCommitteeMeeting() {
    return _selectedType == FirebaseConstants.typeAdministrative &&
        _selectedAdministrativeType == 'اجتماع لجنة';
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

    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال المكان'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    // Determine final event type
    final String finalEventType;
    if (_isCustomEventType()) {
      finalEventType = _customEventTypeController.text.trim();
      if (finalEventType.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى إدخال نوع الحدث'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      finalEventType = _selectedType;
    }

    // FIXED: Prepare committee data properly
    String? committeeId;
    String? committeeName;

    if (_isCommitteeMeeting() && _selectedCommitteeId != null) {
      try {
        final selectedCommittee = _committees.firstWhere(
          (committee) => committee.id == _selectedCommitteeId,
          orElse: () => null, // FIXED: Return null instead of throwing
        );

        if (selectedCommittee != null) {
          committeeId = selectedCommittee.id;
          committeeName = selectedCommittee.name;
        }
      } catch (e) {
        print('Error finding committee: $e');
      }
    }

    final eventId = await eventProvider.createEvent(
      title: _titleController.text,
      type: finalEventType,
      date: _dateController.text,
      description: _descriptionController.text,
      location: _locationController.text,
      meetingPlace: _needsMeetingPlace() ? _selectedMeetingPlace : null,
      administrativeType: _needsAdministrativeType()
          ? _selectedAdministrativeType
          : null,
      committeeId: committeeId,
      committeeName: committeeName,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (eventId != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الحدث بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إضافة الحدث'),
            backgroundColor: Colors.red,
          ),
        );
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
                            _selectedMeetingPlace = null;
                            _selectedAdministrativeType = null;
                            _selectedCommitteeId = null;
                            _customEventTypeController.clear();
                            _showCustomEventTypeField = _isCustomEventType();
                            _showCommitteeSelection = _isCommitteeMeeting();
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Custom Event Type Field
                      if (_showCustomEventTypeField) ...[
                        TextFormField(
                          controller: _customEventTypeController,
                          decoration: const InputDecoration(
                            labelText: 'اكتب نوع الحدث',
                            hintText: 'مثال: ندوة، معسكر، ...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.edit),
                          ),
                          validator: (value) => _isCustomEventType()
                              ? Validators.validateRequired(value, 'نوع الحدث')
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Location Field (ALWAYS VISIBLE)
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'المكان',
                          hintText: 'أدخل مكان الحدث',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) =>
                            Validators.validateRequired(value, 'المكان'),
                      ),
                      const SizedBox(height: 16),

                      // Meeting Place
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

                      // Administrative Type
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
                              _selectedCommitteeId = null;
                              _showCommitteeSelection = _isCommitteeMeeting();
                            });
                          },
                          validator: (value) => Validators.validateRequired(
                            value,
                            'نوع الإدارية',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Committee Selection
                        if (_showCommitteeSelection) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedCommitteeId,
                            decoration: const InputDecoration(
                              labelText: 'اختر اللجنة',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.groups),
                            ),
                            items: _committees.map((committee) {
                              return DropdownMenuItem<String>(
                                value: committee.id,
                                child: Text(committee.name ?? 'بدون اسم'),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCommitteeId = newValue;
                              });
                            },
                            validator: (value) => _isCommitteeMeeting()
                                ? Validators.validateRequired(value, 'اللجنة')
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],
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
    _customEventTypeController.dispose();
    super.dispose();
  }
}
