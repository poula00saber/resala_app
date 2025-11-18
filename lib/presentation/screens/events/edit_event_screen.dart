import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/event_model.dart';
import '../../../core/constants/firebase_constants.dart';
import '../volunteers/select_volunteer_screen.dart';
import '../volunteers/create_volunteer_screen.dart';

class EditEventScreen extends StatefulWidget {
  final EventModel event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _dateController;
  late List<String> _volunteerIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _dateController = TextEditingController(text: widget.event.date);
    _volunteerIds = List<String>.from(widget.event.volunteerIds);
  }

  bool _allowVolunteerManagement() {
    // اجتماع can select from database only
    // اداريات has no volunteer management
    return widget.event.type != FirebaseConstants.typeAdministrative;
  }

  bool _canCreateNewVolunteer() {
    return widget.event.type != FirebaseConstants.typeMeeting &&
        widget.event.type != FirebaseConstants.typeAdministrative;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(widget.event.date),
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

  void _addVolunteer() {
    if (!_allowVolunteerManagement()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إضافة متطوعين لهذا النوع')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'إضافة متطوع',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person_search, color: Colors.blue),
              title: const Text('اختيار متطوع من القائمة'),
              onTap: () {
                Navigator.pop(context);
                _selectExistingVolunteer();
              },
            ),
            if (_canCreateNewVolunteer()) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.green),
                title: const Text('إضافة متطوع جديد'),
                onTap: () {
                  Navigator.pop(context);
                  _createNewVolunteer();
                },
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _selectExistingVolunteer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectVolunteerScreen()),
    );
    if (result != null) {
      setState(() {
        if (!_volunteerIds.contains(result)) {
          _volunteerIds.add(result);
        }
      });
    }
  }

  void _createNewVolunteer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateVolunteerScreen()),
    );
    if (result != null) {
      setState(() {
        if (!_volunteerIds.contains(result)) {
          _volunteerIds.add(result);
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    final updatedEvent = EventModel(
      id: widget.event.id,
      title: _titleController.text,
      type: widget.event.type,
      date: _dateController.text,
      description: widget.event.description,
      location: widget.event.location,
      meetingPlace: widget.event.meetingPlace,
      administrativeType: widget.event.administrativeType,
      volunteerIds: _volunteerIds,
      createdAt: widget.event.createdAt,
      updatedAt: DateTime.now(),
    );

    final success = await eventProvider.updateEvent(
      widget.event.id,
      updatedEvent,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديث الحدث بنجاح')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل تحديث الحدث')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تعديل الحدث"),
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
                        'تعديل تفاصيل الحدث',
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

                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ الحدث',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'المتطوعون',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_allowVolunteerManagement())
                            ElevatedButton.icon(
                              onPressed: _addVolunteer,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('إضافة متطوع'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (!_allowVolunteerManagement())
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('لا يمكن إضافة متطوعين للإداريات'),
                              ),
                            ],
                          ),
                        ),

                      if (_allowVolunteerManagement())
                        FutureBuilder(
                          future: Provider.of<VolunteerProvider>(
                            context,
                            listen: false,
                          ).getVolunteersByIds(_volunteerIds),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            final volunteers = snapshot.data ?? [];

                            if (volunteers.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text('لا يوجد متطوعون'),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: volunteers.length,
                              itemBuilder: (context, index) {
                                final volunteer = volunteers[index];
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primary,
                                      child: Text(volunteer.name[0]),
                                    ),
                                    title: Text(volunteer.name),
                                    subtitle: Text(volunteer.phone),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _volunteerIds.remove(volunteer.id);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                      const SizedBox(height: 30),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveEvent,
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
                                  : const Text('حفظ التعديلات'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
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
    _dateController.dispose();
    super.dispose();
  }
}
