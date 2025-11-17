// ============================================
// FILE: lib/screens/home/edit_event_screen.dart
// Copy this ENTIRE file
// ============================================

import 'package:flutter/material.dart';
import 'package:resala/screens/home/create_volunteer.dart';
import 'package:resala/screens/home/select_volunteer.dart';
import 'package:resala/screens/home/volunteer_details_sheet.dart';
import 'package:resala/screens/themes/app_theme.dart';

class EditEventScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _dateController;
  late List<Map<String, dynamic>> _selectedVolunteers;

  bool _allowVolunteerManagement() {
    return widget.event['type'] != 'اجتماع' &&
        widget.event['type'] != 'اداريات';
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event['title']);
    _dateController = TextEditingController(text: widget.event['date']);
    _selectedVolunteers = List<Map<String, dynamic>>.from(
      widget.event['volunteers'] ?? [],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(widget.event['date']),
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
        const SnackBar(
          content: Text('لا يمكن إضافة متطوعين لهذا النوع من الأحداث'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              subtitle: const Text('اختر من المتطوعين المسجلين'),
              onTap: () {
                Navigator.pop(context);
                _selectExistingVolunteer();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.green),
              title: const Text('إضافة متطوع جديد'),
              subtitle: const Text('تسجيل متطوع جديد في النظام'),
              onTap: () {
                Navigator.pop(context);
                _createNewVolunteer();
              },
            ),
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
      _showVolunteerDetailsSheet(result);
    }
  }

  void _createNewVolunteer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateVolunteerScreen()),
    );

    if (result != null) {
      _showVolunteerDetailsSheet(result);
    }
  }

  void _showVolunteerDetailsSheet(Map<String, dynamic> volunteer) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => VolunteerDetailsSheet(volunteer: volunteer),
    );

    if (result != null) {
      setState(() {
        if (!_selectedVolunteers.any((v) => v['id'] == result['id'])) {
          _selectedVolunteers.add(result);
        }
      });
    }
  }

  void _editVolunteerDetails(Map<String, dynamic> volunteer) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => VolunteerDetailsSheet(
        volunteer: volunteer,
        initialHasTshirt: volunteer['hasTshirt'] ?? false,
      ),
    );

    if (result != null) {
      setState(() {
        final index = _selectedVolunteers.indexWhere(
          (v) => v['id'] == result['id'],
        );
        if (index != -1) {
          _selectedVolunteers[index] = result;
        }
      });
    }
  }

  void _removeVolunteer(Map<String, dynamic> volunteer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف المتطوع "${volunteer['name']}" من الحدث؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedVolunteers.removeWhere(
                  (v) => v['id'] == volunteer['id'],
                );
              });
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      final updatedEvent = Map<String, dynamic>.from(widget.event);
      updatedEvent['title'] = _titleController.text;
      updatedEvent['date'] = _dateController.text;
      updatedEvent['volunteers'] = _selectedVolunteers;

      Navigator.pop(context, updatedEvent);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث الحدث بنجاح')));
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال تاريخ الحدث';
                          }
                          return null;
                        },
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
                                child: Text(
                                  'لا يمكن إضافة متطوعين لأحداث الاجتماعات والإداريات',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_allowVolunteerManagement())
                        _selectedVolunteers.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'لا يوجد متطوعون مضافون',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _selectedVolunteers.length,
                                itemBuilder: (context, index) {
                                  final volunteer = _selectedVolunteers[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primary,
                                        child: Text(
                                          volunteer['name'][0],
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      title: Text(volunteer['name']),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(volunteer['phone']),
                                          if (volunteer['hasTshirt'] == true)
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.checkroom,
                                                  size: 14,
                                                  color: Colors.green[700],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'لديه تيشيرت',
                                                  style: TextStyle(
                                                    color: Colors.green[700],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _editVolunteerDetails(
                                                  volunteer,
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _removeVolunteer(volunteer),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      const SizedBox(height: 30),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveEvent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child: const Text('حفظ التعديلات'),
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
