import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../themes/app_theme.dart';
import '../../widgets/app_ui_widgets.dart';
import '../../widgets/whale_loading.dart';
import '../../providers/event_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../../data/models/event_model.dart';
import '../events/create_event_screen.dart';

class QaflaScreen extends StatefulWidget {
  const QaflaScreen({super.key});

  @override
  State<QaflaScreen> createState() => _QaflaScreenState();
}

class _QaflaScreenState extends State<QaflaScreen> {
  int _currentPage = 0;
  final int _pageSize = 6;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          title: const Text(
            'قوافل',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 30.0),
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateEventScreen(),
                ),
              );
            },
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.textLight,
            icon: const Icon(Icons.add),
            label: const Text(
              'إضافة قافلة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ),
        body: Consumer<EventProvider>(
          builder: (context, eventProvider, _) {
            final qaflaEvents = eventProvider.getQaflaEvents();

            if (eventProvider.isLoading && qaflaEvents.isEmpty) {
              return const Center(child: WhaleLoading());
            }

            if (qaflaEvents.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد قوافل بعد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppTheme.secondary,
                  ),
                ),
              );
            }

            final totalPages = (qaflaEvents.length / _pageSize).ceil();
            final currentPage = totalPages == 0
                ? 0
                : _currentPage.clamp(0, totalPages - 1);
            final pageItems = qaflaEvents
                .skip(currentPage * _pageSize)
                .take(_pageSize)
                .toList();

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: pageItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final event = pageItems[index];
                      return _QaflaEventCard(event: event);
                    },
                  ),
                ),
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: currentPage == 0
                              ? null
                              : () => setState(
                                  () => _currentPage = currentPage - 1,
                                ),
                          child: const Text('السابق'),
                        ),
                        Text(
                          'صفحة ${currentPage + 1} من $totalPages',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        TextButton(
                          onPressed: currentPage + 1 >= totalPages
                              ? null
                              : () => setState(
                                  () => _currentPage = currentPage + 1,
                                ),
                          child: const Text('التالي'),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QaflaEventCard extends StatelessWidget {
  final EventModel event;

  const _QaflaEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final volunteerProvider = Provider.of<VolunteerProvider>(
      context,
      listen: false,
    );

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note, color: AppTheme.primary),
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _QaflaDetailsSheet(event: event),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'التاريخ', value: event.date),
            _InfoRow(label: 'المكان', value: event.location ?? 'غير محدد'),
            FutureBuilder<int>(
              future: _countTshirts(volunteerProvider, event),
              builder: (context, snapshot) {
                final shirtCount = snapshot.data ?? 0;
                return Column(
                  children: [
                    _InfoRow(
                      label: 'عدد المتطوعين',
                      value: _countDistributedVolunteers(event).toString(),
                    ),
                    _InfoRow(label: 'التيشرتات', value: shirtCount.toString()),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              _buildDetailsSummary(event.additionalDetails),
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppPrimaryActionButton(
                label: 'إكمال التفاصيل',
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _QaflaDetailsSheet(event: event),
                  );
                },
                textStyle: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countDistributedVolunteers(EventModel event) {
    return event.qaflaDistribution.values.where((value) => value).length;
  }

  Future<int> _countTshirts(
    VolunteerProvider provider,
    EventModel event,
  ) async {
    if (event.volunteerIds.isEmpty) return 0;
    final volunteers = await provider.getVolunteersByIds(event.volunteerIds);
    return volunteers.where((volunteer) => volunteer.hasTshirt).length;
  }

  String _buildDetailsSummary(String? additionalDetails) {
    if (additionalDetails == null || additionalDetails.isEmpty) {
      return 'لم يتم إدخال تفاصيل القافلة بعد';
    }

    try {
      final decoded = jsonDecode(additionalDetails) as Map<String, dynamic>;
      final mealDetails = decoded['mealDetails']?.toString().trim() ?? '';
      final carCount = decoded['carCount'];
      final summaryParts = <String>[];

      if (mealDetails.isNotEmpty) {
        summaryParts.add('الوجبات: $mealDetails');
      }

      if (carCount != null) {
        summaryParts.add('عدد العربيات: $carCount');
      }

      return summaryParts.isEmpty
          ? 'تم حفظ تفاصيل القافلة'
          : summaryParts.join(' • ');
    } catch (_) {
      return 'تم حفظ تفاصيل القافلة';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppTheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QaflaDetailsSheet extends StatefulWidget {
  final EventModel event;

  const _QaflaDetailsSheet({required this.event});

  @override
  State<_QaflaDetailsSheet> createState() => _QaflaDetailsSheetState();
}

class _QaflaDetailsSheetState extends State<_QaflaDetailsSheet> {
  final TextEditingController _mealDetailsController = TextEditingController();
  final List<_CarFormData> _cars = [];
  int _carCount = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  @override
  void dispose() {
    _mealDetailsController.dispose();
    for (final car in _cars) {
      car.dispose();
    }
    super.dispose();
  }

  void _increaseCars() {
    setState(() {
      _carCount++;
      _cars.add(_CarFormData());
    });
  }

  void _decreaseCars() {
    if (_carCount <= 1) return;
    setState(() {
      _carCount--;
      final removed = _cars.removeLast();
      removed.dispose();
    });
  }

  void _loadExistingDetails() {
    _cars.clear();

    final additionalDetails = widget.event.additionalDetails;
    if (additionalDetails == null || additionalDetails.isEmpty) {
      _cars.add(_CarFormData());
      return;
    }

    try {
      final decoded = jsonDecode(additionalDetails) as Map<String, dynamic>;
      _mealDetailsController.text = decoded['mealDetails']?.toString() ?? '';

      final storedCars = decoded['cars'];
      if (decoded['carCount'] is num) {
        _carCount = (decoded['carCount'] as num).toInt().clamp(1, 99);
      }

      final parsedCars = storedCars is List ? storedCars : const [];
      final totalCars = parsedCars.isNotEmpty ? parsedCars.length : _carCount;
      _carCount = totalCars.clamp(1, 99);

      for (var index = 0; index < _carCount; index++) {
        final car = _CarFormData();
        if (index < parsedCars.length && parsedCars[index] is Map) {
          final carData = Map<String, dynamic>.from(parsedCars[index] as Map);
          car.vehicleTypeController.text =
              carData['vehicleType']?.toString() ?? '';
          car.driverNameController.text =
              carData['driverName']?.toString() ?? '';
          car.carNumberController.text = carData['carNumber']?.toString() ?? '';
          car.arrivalTimeController.text =
              carData['arrivalTime']?.toString() ?? '';
          car.departureTimeController.text =
              carData['departureTime']?.toString() ?? '';
          car.returnTimeController.text =
              carData['returnTime']?.toString() ?? '';
        }
        _cars.add(car);
      }
    } catch (_) {
      _mealDetailsController.text = additionalDetails;
      _cars.add(_CarFormData());
      _carCount = 1;
    }
  }

  Future<void> _saveDetails() async {
    setState(() => _isSaving = true);

    final details = {
      'mealDetails': _mealDetailsController.text.trim(),
      'carCount': _carCount,
      'cars': _cars
          .map(
            (car) => {
              'vehicleType': car.vehicleTypeController.text.trim(),
              'driverName': car.driverNameController.text.trim(),
              'carNumber': car.carNumberController.text.trim(),
              'arrivalTime': car.arrivalTimeController.text.trim(),
              'departureTime': car.departureTimeController.text.trim(),
              'returnTime': car.returnTimeController.text.trim(),
            },
          )
          .toList(),
    };

    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final success = await eventProvider.updateEvent(
      widget.event.id,
      _copyWithDetails(jsonEncode(details)),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'تم حفظ تفاصيل القافلة' : 'فشل حفظ تفاصيل القافلة',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  EventModel _copyWithDetails(String details) {
    return EventModel(
      id: widget.event.id,
      title: widget.event.title,
      type: widget.event.type,
      date: widget.event.date,
      description: widget.event.description,
      location: widget.event.location,
      meetingPlace: widget.event.meetingPlace,
      administrativeType: widget.event.administrativeType,
      committeeId: widget.event.committeeId,
      committeeName: widget.event.committeeName,
      volunteerIds: widget.event.volunteerIds,
      qaflaPreparation: widget.event.qaflaPreparation,
      qaflaFilling: widget.event.qaflaFilling,
      qaflaDistribution: widget.event.qaflaDistribution,
      createdAt: widget.event.createdAt,
      updatedAt: DateTime.now(),
      meetingCategory: widget.event.meetingCategory,
      previousMeetingPoints: widget.event.previousMeetingPoints,
      newMeetingPoints: widget.event.newMeetingPoints,
      votingItems: widget.event.votingItems,
      meetingDecisions: widget.event.meetingDecisions,
      deferredPoints: widget.event.deferredPoints,
      additionalDetails: details,
    );
  }

  int _countDistributedVolunteers(EventModel event) {
    return event.qaflaDistribution.values.where((value) => value).length;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'التاريخ', value: widget.event.date),
                  _InfoRow(
                    label: 'المكان',
                    value: widget.event.location ?? 'غير محدد',
                  ),
                  _InfoRow(
                    label: 'عدد المتطوعين',
                    value: _countDistributedVolunteers(widget.event).toString(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mealDetailsController,
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'تفاصيل الوجبات',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'عدد العربيات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _increaseCars,
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                      ),
                      Text(
                        '$_carCount',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _decreaseCars,
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_carCount, (index) {
                    final car = _cars[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              'العربية ${index + 1}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: car.vehicleTypeController,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                labelText: 'نوع المركبة',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: car.driverNameController,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                labelText: 'اسم السواق',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: car.carNumberController,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                labelText: 'رقم العربية',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: car.arrivalTimeController,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                labelText: 'ميعاد الوصول',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: car.departureTimeController,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                labelText: 'ميعاد التحرك',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: car.returnTimeController,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                labelText: 'ميعاد الرجوع',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryActionButton(
                      label: _isSaving ? 'جاري الحفظ...' : 'حفظ التفاصيل',
                      onPressed: _isSaving ? null : _saveDetails,
                      textStyle: const TextStyle(fontFamily: 'Cairo'),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CarFormData {
  final TextEditingController vehicleTypeController = TextEditingController();
  final TextEditingController driverNameController = TextEditingController();
  final TextEditingController carNumberController = TextEditingController();
  final TextEditingController arrivalTimeController = TextEditingController();
  final TextEditingController departureTimeController = TextEditingController();
  final TextEditingController returnTimeController = TextEditingController();

  void dispose() {
    vehicleTypeController.dispose();
    driverNameController.dispose();
    carNumberController.dispose();
    arrivalTimeController.dispose();
    departureTimeController.dispose();
    returnTimeController.dispose();
  }
}
