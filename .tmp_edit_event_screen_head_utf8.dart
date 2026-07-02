// ============================================
// FILE: lib/presentation/screens/events/edit_event_screen.dart
// UPDATED: Added meeting export and fixed volunteer table header
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/services/excel_export_helper.dart';
import 'package:resala/services/word_export_helper.dart';
import '../../providers/event_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/whale_loading.dart';
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
  late TextEditingController _descriptionController;
  late TextEditingController _additionalDetailsController;
  late List<String> _volunteerIds;
  late Map<String, bool> _volunteerTshirtStatus;
  late Map<String, bool> _qaflaPreparation;
  late Map<String, bool> _qaflaFilling;
  late Map<String, bool> _qaflaDistribution;
  late List<String> _previousMeetingPoints;
  late List<String> _newMeetingPoints;
  late List<Map<String, String>> _votingItems;
  late List<String> _meetingDecisions;
  late List<String> _deferredPoints;

  bool _isLoading = false;
  bool _isExporting = false;

  bool get _isQafla => widget.event.type == 'قافلة';
  bool get _isOnline => widget.event.meetingPlace == 'أونلاين';
  bool get _isMeeting => widget.event.type == FirebaseConstants.typeMeeting;
  bool get _needsLocation => !_isMeeting || !_isOnline;

  double get _volunteerTableWidth {
    var width = 44 + 20 + 40 + 20 + 100 + 20 + 140 + 20;
    if (!_isOnline) {
      width += 60 + 20;
    }
    if (_isQafla) {
      width += 60 + 20 + 60 + 20 + 60;
    }
    return width.toDouble();
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _dateController = TextEditingController(text: widget.event.date);
    _locationController = TextEditingController(
      text: widget.event.location ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.event.description,
    );
    _additionalDetailsController = TextEditingController(
      text: widget.event.additionalDetails ?? '',
    );
    _volunteerIds = List<String>.from(widget.event.volunteerIds);
    _volunteerTshirtStatus = {};
    _qaflaPreparation = Map<String, bool>.from(widget.event.qaflaPreparation);
    _qaflaFilling = Map<String, bool>.from(widget.event.qaflaFilling);
    _qaflaDistribution = Map<String, bool>.from(widget.event.qaflaDistribution);
    _previousMeetingPoints = List<String>.from(
      widget.event.previousMeetingPoints,
    );
    _newMeetingPoints = List<String>.from(widget.event.newMeetingPoints);
    _votingItems = widget.event.votingItems
        .map((item) => Map<String, String>.from(item))
        .toList();
    _meetingDecisions = List<String>.from(widget.event.meetingDecisions);
    _deferredPoints = List<String>.from(widget.event.deferredPoints);
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
        eventDescription: _descriptionController.text,
        volunteers: volunteers,
        isOnline: _isOnline,
        isQafla: _isQafla,
        qaflaPreparation: _qaflaPreparation,
        qaflaFilling: _qaflaFilling,
        qaflaDistribution: _qaflaDistribution,
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

  Future<void> _exportToWord() async {
    setState(() => _isExporting = true);

    try {
      final updatedEvent = EventModel(
        id: widget.event.id,
        title: _titleController.text,
        type: widget.event.type,
        date: _dateController.text,
        description: _descriptionController.text,
        location: _locationController.text.isEmpty
            ? null
            : _locationController.text,
        meetingPlace: widget.event.meetingPlace,
        administrativeType: widget.event.administrativeType,
        committeeId: widget.event.committeeId,
        committeeName: widget.event.committeeName,
        volunteerIds: _volunteerIds,
        previousMeetingPoints: _previousMeetingPoints,
        newMeetingPoints: _newMeetingPoints,
        votingItems: _votingItems,
        meetingDecisions: _meetingDecisions,
        deferredPoints: _deferredPoints,
        additionalDetails: _additionalDetailsController.text.isEmpty
            ? null
            : _additionalDetailsController.text,
        meetingCategory: widget.event.meetingCategory,
        createdAt: widget.event.createdAt,
        updatedAt: DateTime.now(),
      );

      await WordExportHelper.exportMeetingToWord(event: updatedEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تصدير المحضر بنجاح',
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
              'فشل تصدير المحضر: $e',
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

  Future<String?> _showAddItemDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title, style: const TextStyle(fontFamily: 'Cairo')),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(fontFamily: 'Cairo'),
            decoration: InputDecoration(
              hintText: 'أدخل النص',
              hintStyle: const TextStyle(fontFamily: 'Cairo'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, controller.text.trim());
                }
              },
              child: const Text(
                'إضافة',
                style: TextStyle(fontFamily: 'Cairo', color: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addVotingItem() async {
    final topicController = TextEditingController();
    String? selectedResult;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'بند تصويت جديد',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: topicController,
                  style: const TextStyle(fontFamily: 'Cairo'),
                  decoration: InputDecoration(
                    hintText: 'موضوع التصويت',
                    hintStyle: const TextStyle(fontFamily: 'Cairo'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedResult,
                  decoration: InputDecoration(
                    hintText: 'النتيجة',
                    hintStyle: const TextStyle(fontFamily: 'Cairo'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: FirebaseConstants.votingResults
                      .map(
                        (result) => DropdownMenuItem(
                          value: result,
                          child: Text(
                            result,
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedResult = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (topicController.text.trim().isNotEmpty) {
                    Navigator.pop(ctx, {
                      'topic': topicController.text.trim(),
                      'result': selectedResult ?? '',
                    });
                  }
                },
                child: const Text(
                  'إضافة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() => _votingItems.add(result));
    }
  }

  Widget _buildMeetingSection({
    required String title,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(int) onRemove,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const Divider(),
            ...items.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => onRemove(entry.key)),
                      child: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, color: AppTheme.primary, size: 20),
              label: const Text(
                'إضافة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppTheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'بنود التصويت',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const Divider(),
            ..._votingItems.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () =>
                          setState(() => _votingItems.removeAt(entry.key)),
                      child: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            entry.value['topic'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'النتيجة: ${entry.value['result']?.isNotEmpty == true ? entry.value['result'] : '-'}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _addVotingItem,
              icon: const Icon(Icons.add, color: AppTheme.primary, size: 20),
              label: const Text(
                'إضافة بند',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppTheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMeetingSections() {
    return [
      const SizedBox(height: 8),
      _buildMeetingSection(
        title: 'نقاط الاجتماع السابق',
        items: _previousMeetingPoints,
        onAdd: () async {
          final text = await _showAddItemDialog('نقطة من الاجتماع السابق');
          if (text != null) {
            setState(() => _previousMeetingPoints.add(text));
          }
        },
        onRemove: (index) => _previousMeetingPoints.removeAt(index),
      ),
      _buildMeetingSection(
        title: 'نقاط جديدة للاجتماع',
        items: _newMeetingPoints,
        onAdd: () async {
          final text = await _showAddItemDialog('نقطة جديدة');
          if (text != null) {
            setState(() => _newMeetingPoints.add(text));
          }
        },
        onRemove: (index) => _newMeetingPoints.removeAt(index),
      ),
      _buildVotingSection(),
      _buildMeetingSection(
        title: 'قرارات الاجتماع',
        items: _meetingDecisions,
        onAdd: () async {
          final text = await _showAddItemDialog('قرار');
          if (text != null) {
            setState(() => _meetingDecisions.add(text));
          }
        },
        onRemove: (index) => _meetingDecisions.removeAt(index),
      ),
      _buildMeetingSection(
        title: 'نقاط مؤجلة للاجتماع القادم',
        items: _deferredPoints,
        onAdd: () async {
          final text = await _showAddItemDialog('نقطة مؤجلة');
          if (text != null) {
            setState(() => _deferredPoints.add(text));
          }
        },
        onRemove: (index) => _deferredPoints.removeAt(index),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
        child: _buildTextField(
          controller: _additionalDetailsController,
          label: 'تفاصيل أخرى',
          readOnly: false,
        ),
      ),
    ];
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
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _buildAddButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textLight,
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
        if (result is List) {
          for (final id in result) {
            if (!_volunteerIds.contains(id)) {
              _volunteerIds.add(id);
            }
          }
        } else if (result is String && !_volunteerIds.contains(result)) {
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final volunteerProvider = Provider.of<VolunteerProvider>(
      context,
      listen: false,
    );

    for (final entry in _volunteerTshirtStatus.entries) {
      final volunteer = await volunteerProvider.getVolunteerById(entry.key);
      if (volunteer != null) {
        final updatedVolunteer = volunteer.copyWith(hasTshirt: entry.value);
        await volunteerProvider.updateVolunteer(entry.key, updatedVolunteer);
      }
    }

    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final updatedEvent = EventModel(
      id: widget.event.id,
      title: _titleController.text,
      type: widget.event.type,
      date: _dateController.text,
      description: _descriptionController.text,
      location: _needsLocation && _locationController.text.isNotEmpty
          ? _locationController.text
          : null,
      meetingPlace: widget.event.meetingPlace,
      administrativeType: widget.event.administrativeType,
      committeeId: widget.event.committeeId,
      committeeName: widget.event.committeeName,
      volunteerIds: _volunteerIds,
      qaflaPreparation: _qaflaPreparation,
      qaflaFilling: _qaflaFilling,
      qaflaDistribution: _qaflaDistribution,
      previousMeetingPoints: _previousMeetingPoints,
      newMeetingPoints: _newMeetingPoints,
      votingItems: _votingItems,
      meetingDecisions: _meetingDecisions,
      deferredPoints: _deferredPoints,
      additionalDetails: _additionalDetailsController.text.isEmpty
          ? null
          : _additionalDetailsController.text,
      meetingCategory: widget.event.meetingCategory,
      createdAt: widget.event.createdAt,
      updatedAt: DateTime.now(),
    );

    final success = await eventProvider.updateEvent(
      widget.event.id,
      updatedEvent,
    );

    if (mounted) {
      setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_forward, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'تفاصيل الحدث',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: AppTheme.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isMeeting)
            IconButton(
              onPressed: _isExporting ? null : _exportToWord,
              icon: _isExporting
                  ? WhaleLoading(size: 20)
                  : const Icon(Icons.description, color: AppTheme.primary),
              tooltip: 'تصدير محضر (Word)',
            ),
          FutureBuilder<List<VolunteerModel>>(
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
                    : () => _exportToExcel(snapshot.data!),
                icon: _isExporting
                    ? WhaleLoading(size: 20)
                    : const Icon(Icons.file_download, color: AppTheme.primary),
                tooltip: 'تصدير إلى Excel',
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
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
                  if (_needsLocation) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _locationController,
                        label: 'المكان',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _buildTextField(
                controller: _descriptionController,
                label: 'وصف الحدث',
              ),
            ),
            if (_isMeeting) ..._buildMeetingSections(),
            const SizedBox(height: 8),
            if (_allowVolunteerManagement())
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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _volunteerTableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 44, child: _buildTableHeader('')),
                            const SizedBox(width: 20),
                            SizedBox(width: 40, child: _buildTableHeader('#')),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 100,
                              child: _buildTableHeader('الاسم'),
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 140,
                              child: _buildTableHeader('رقم التليفون'),
                            ),
                            const SizedBox(width: 20),
                            if (!_isOnline)
                              SizedBox(
                                width: 60,
                                child: _buildTableHeader('تيشيرت'),
                              ),
                            if (_isQafla) ...[
                              SizedBox(
                                width: 60,
                                child: _buildTableHeader('تجهيز'),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 60,
                                child: _buildTableHeader('تعبئة'),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 60,
                                child: _buildTableHeader('توزيع'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 320,
                        child: FutureBuilder<List<VolunteerModel>>(
                          future: Provider.of<VolunteerProvider>(
                            context,
                            listen: false,
                          ).getVolunteersByIds(_volunteerIds),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: WhaleLoading());
                            }

                            final volunteers = snapshot.data ?? [];
                            volunteers.sort(
                              (a, b) =>
                                  FirebaseConstants.compareByDegreeAndName(
                                    a.educationalLevel ?? '',
                                    a.name,
                                    b.educationalLevel ?? '',
                                    b.name,
                                  ),
                            );

                            for (final volunteer in volunteers) {
                              _volunteerTshirtStatus.putIfAbsent(
                                volunteer.id,
                                () => volunteer.hasTshirt,
                              );
                            }

                            if (volunteers.isEmpty) {
                              return const Center(
                                child: Text(
                                  'لا يوجد متطوعون',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              );
                            }

                            return ListView(
                              children: volunteers.asMap().entries.map((entry) {
                                final index = entry.key;
                                final volunteer = entry.value;

                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 44,
                                        child: Center(
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            tooltip: 'حذف المتطوع',
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (dialogContext) =>
                                                    Directionality(
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      child: AlertDialog(
                                                        title: const Text(
                                                          'حذف متطوع',
                                                          style: TextStyle(
                                                            fontFamily: 'Cairo',
                                                          ),
                                                        ),
                                                        content: Text(
                                                          'هل أنت متأكد من حذف ${volunteer.name} من هذا الحدث؟',
                                                          style:
                                                              const TextStyle(
                                                                fontFamily:
                                                                    'Cairo',
                                                              ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  dialogContext,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              'إلغاء',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Cairo',
                                                              ),
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  dialogContext,
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              'حذف',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Cairo',
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                              );

                                              if (confirm == true && mounted) {
                                                setState(() {
                                                  _volunteerIds.remove(
                                                    volunteer.id,
                                                  );
                                                  _volunteerTshirtStatus.remove(
                                                    volunteer.id,
                                                  );
                                                });
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'تم حذف ${volunteer.name} من الحدث',
                                                      style: const TextStyle(
                                                        fontFamily: 'Cairo',
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        Colors.orange,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: _buildTableCell(
                                          (index + 1).toString(),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      SizedBox(
                                        width: 100,
                                        child: _buildTableCell(volunteer.name),
                                      ),
                                      const SizedBox(width: 20),
                                      SizedBox(
                                        width: 140,
                                        child: _buildTableCell(volunteer.phone),
                                      ),
                                      const SizedBox(width: 20),
                                      if (!_isOnline)
                                        SizedBox(
                                          width: 60,
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
                                      if (_isQafla) ...[
                                        SizedBox(
                                          width: 60,
                                          child: Center(
                                            child: Checkbox(
                                              value:
                                                  _qaflaPreparation[volunteer
                                                      .id] ??
                                                  false,
                                              onChanged: (value) {
                                                setState(() {
                                                  _qaflaPreparation[volunteer
                                                          .id] =
                                                      value ?? false;
                                                });
                                              },
                                              activeColor: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        SizedBox(
                                          width: 60,
                                          child: Center(
                                            child: Checkbox(
                                              value:
                                                  _qaflaFilling[volunteer.id] ??
                                                  false,
                                              onChanged: (value) {
                                                setState(() {
                                                  _qaflaFilling[volunteer.id] =
                                                      value ?? false;
                                                });
                                              },
                                              activeColor: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        SizedBox(
                                          width: 60,
                                          child: Center(
                                            child: Checkbox(
                                              value:
                                                  _qaflaDistribution[volunteer
                                                      .id] ??
                                                  false,
                                              onChanged: (value) {
                                                setState(() {
                                                  _qaflaDistribution[volunteer
                                                          .id] =
                                                      value ?? false;
                                                });
                                              },
                                              activeColor: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
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
                  foregroundColor: AppTheme.textLight,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? WhaleLoading(size: 20, color: AppTheme.cardBackground)
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
        fillColor: AppTheme.cardBackground,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: AppTheme.textDark,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }
}
