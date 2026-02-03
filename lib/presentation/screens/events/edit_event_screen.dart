// ============================================
// FILE: lib/presentation/screens/events/edit_event_screen.dart
// UPDATED: Added Excel export functionality
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/services/excel_export_helper.dart';
import '../../providers/event_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/volunteer_model.dart';
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
  late TextEditingController _locationController;
  late List<String> _volunteerIds;
  late Map<String, bool> _volunteerTshirtStatus;
  bool _isLoading = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _dateController = TextEditingController(text: widget.event.date);
    _locationController = TextEditingController(
      text: widget.event.location ?? '',
    );
    _volunteerIds = List<String>.from(widget.event.volunteerIds);
    _volunteerTshirtStatus = {};
  }

  bool _allowVolunteerManagement() {
    return true;
  }

  bool _canCreateNewVolunteer() {
    return widget.event.type != FirebaseConstants.typeMeeting &&
        widget.event.type != FirebaseConstants.typeAdministrative;
  }

  Future<void> _exportToExcel(List<VolunteerModel> volunteers) async {
    setState(() => _isExporting = true);

    try {
      await ExcelExportHelper.exportEventToExcel(
        eventTitle: widget.event.title,
        eventType: widget.event.type,
        eventDate: widget.event.date,
        eventLocation: widget.event.location,
        volunteers: volunteers,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تصدير البيانات بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل تصدير البيانات: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(widget.event.date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
      });
    }
  }

  void _addVolunteer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAddButton('إضافة متطوع', Icons.add_circle_outline, () {
              Navigator.pop(context);
              _selectExistingVolunteer();
            }),
            if (_canCreateNewVolunteer()) ...[
              const SizedBox(height: 12),
              _buildAddButton('متطوع جديد', Icons.add, () {
                Navigator.pop(context);
                _createNewVolunteer();
              }),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
          _volunteerTshirtStatus[result] = false;
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final volunteerProvider = Provider.of<VolunteerProvider>(
      context,
      listen: false,
    );
    for (var entry in _volunteerTshirtStatus.entries) {
      final volunteerId = entry.key;
      final hasTshirt = entry.value;

      final volunteer = await volunteerProvider.getVolunteerById(volunteerId);
      if (volunteer != null) {
        final updatedVolunteer = (volunteer as VolunteerModel).copyWith(
          hasTshirt: hasTshirt,
        );
        await volunteerProvider.updateVolunteer(volunteerId, updatedVolunteer);
      }
    }

    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    final updatedEvent = EventModel(
      id: widget.event.id,
      title: _titleController.text,
      type: widget.event.type,
      date: _dateController.text,
      description: widget.event.description,
      location: _locationController.text.isEmpty
          ? null
          : _locationController.text,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تحديث الحدث بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'فشل تحديث الحدث',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
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
          icon: const Icon(Icons.arrow_forward, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'تفاصيل الحدث',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Export to Excel Button
          FutureBuilder(
            future: Provider.of<VolunteerProvider>(
              context,
              listen: false,
            ).getVolunteersByIds(_volunteerIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData ||
                  (snapshot.data?.isEmpty ?? true)) {
                return const SizedBox.shrink();
              }

              return IconButton(
                onPressed: _isExporting
                    ? null
                    : () =>
                          _exportToExcel(snapshot.data as List<VolunteerModel>),
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      )
                    : const Icon(Icons.file_download, color: AppTheme.primary),
                tooltip: 'تصدير إلى Excel',
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _dateController,
                      label: 'التاريخ',
                      readOnly: true,
                      onTap: _selectDate,
                      suffixIcon: Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _locationController,
                      label: 'المكان',
                      readOnly: false,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildAddButton(
                    'إضافة متطوع',
                    Icons.add_circle_outline,
                    _selectExistingVolunteer,
                  ),
                  if (_canCreateNewVolunteer()) ...[
                    const SizedBox(height: 12),
                    _buildAddButton(
                      'متطوع جديد',
                      Icons.add,
                      _createNewVolunteer,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: _buildTableHeader('#')),
                          Expanded(flex: 3, child: _buildTableHeader('الاسم')),
                          Expanded(
                            flex: 3,
                            child: _buildTableHeader('رقم التليفون'),
                          ),
                          Expanded(flex: 2, child: _buildTableHeader('تيشيرت')),
                        ],
                      ),
                    ),

                    Expanded(
                      child: FutureBuilder(
                        future: Provider.of<VolunteerProvider>(
                          context,
                          listen: false,
                        ).getVolunteersByIds(_volunteerIds),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primary,
                              ),
                            );
                          }

                          final volunteers = snapshot.data ?? [];

                          for (var volunteer in volunteers) {
                            if (!_volunteerTshirtStatus.containsKey(
                              volunteer.id,
                            )) {
                              _volunteerTshirtStatus[volunteer.id] =
                                  (volunteer as VolunteerModel).hasTshirt;
                            }
                          }

                          if (volunteers.isEmpty) {
                            return const Center(
                              child: Text(
                                'لا يوجد متطوعون',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: volunteers.length,
                            itemBuilder: (context, index) {
                              final volunteer = volunteers[index];
                              return Dismissible(
                                key: Key(volunteer.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  color: Colors.red,
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (context) => Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: AlertDialog(
                                        title: const Text(
                                          'حذف متطوع',
                                          style: TextStyle(fontFamily: 'Cairo'),
                                        ),
                                        content: Text(
                                          'هل أنت متأكد من حذف ${volunteer.name} من هذا الحدث؟',
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text(
                                              'إلغاء',
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'حذف',
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                onDismissed: (direction) {
                                  setState(() {
                                    _volunteerIds.remove(volunteer.id);
                                    _volunteerTshirtStatus.remove(volunteer.id);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'تم حذف ${volunteer.name} من الحدث',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      backgroundColor: Colors.orange,
                                      action: SnackBarAction(
                                        label: 'تراجع',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          setState(() {
                                            _volunteerIds.add(volunteer.id);
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: _buildTableCell(
                                          (index + 1).toString(),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: _buildTableCell(volunteer.name),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: _buildTableCell(volunteer.phone),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Checkbox(
                                            value:
                                                _volunteerTshirtStatus[volunteer
                                                    .id] ??
                                                false,
                                            onChanged: (value) {
                                              setState(() {
                                                _volunteerTshirtStatus[volunteer
                                                        .id] =
                                                    value ?? false;
                                              });
                                            },
                                            activeColor: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
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
                    : const Text(
                        'حفظ',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      textAlign: TextAlign.center,
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          fontFamily: 'Cairo',
          color: Colors.grey[400],
          fontSize: 12,
        ),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 18, color: AppTheme.primary)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
