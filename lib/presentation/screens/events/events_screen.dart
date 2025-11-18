// ============================================
// FILE: lib/presentation/screens/events/events_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import 'create_event_screen.dart';
import 'edit_event_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  String _getArabicDayName(String date) {
    final dateTime = DateTime.parse(date);
    final weekday = dateTime.weekday;
    const arabicDays = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return arabicDays[weekday - 1];
  }

  String _formatDate(String date) {
    final dateTime = DateTime.parse(date);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'قافلة':
        return Colors.green;
      case 'كرنفال':
        return Colors.orange;
      case 'يوم عائلي':
        return Colors.purple;
      case 'اجتماع':
        return Colors.blue;
      case 'اداريات':
        return Colors.teal;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الأحداث"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateEventScreen(),
                ),
              );
            },
            tooltip: 'إضافة حدث جديد',
          ),
        ],
      ),
      body: Container(
        color: AppTheme.primary,
        child: Column(
          children: [
            // Filter Dropdown
            Consumer<EventProvider>(
              builder: (context, eventProvider, _) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Text(
                            'عرض الأحداث:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButton<EventFilter>(
                              value: eventProvider.currentFilter,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: EventFilter.last7Days,
                                  child: Text('آخر 7 أيام'),
                                ),
                                DropdownMenuItem(
                                  value: EventFilter.lastMonth,
                                  child: Text('آخر شهر'),
                                ),
                                DropdownMenuItem(
                                  value: EventFilter.all,
                                  child: Text('جميع الأحداث'),
                                ),
                              ],
                              onChanged: (EventFilter? newValue) {
                                if (newValue != null) {
                                  eventProvider.setFilter(newValue);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Events List
            Expanded(
              child: Consumer<EventProvider>(
                builder: (context, eventProvider, _) {
                  if (eventProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (eventProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ: ${eventProvider.error}',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final groupedEvents = eventProvider.getGroupedEvents();

                  if (groupedEvents.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد أحداث',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: groupedEvents.length,
                    itemBuilder: (context, index) {
                      final date = groupedEvents.keys.elementAt(index);
                      final dayEvents = groupedEvents[date]!;
                      return _buildDayExpansionTile(context, date, dayEvents);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEventScreen()),
          );
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDayExpansionTile(
    BuildContext context,
    String date,
    List<dynamic> events,
  ) {
    final dayName = _getArabicDayName(date);
    final formattedDate = _formatDate(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.calendar_today, color: AppTheme.primary),
        ),
        title: Text(
          dayName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(formattedDate),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${events.length} حدث',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: events
            .map((event) => _buildEventCard(context, event))
            .toList(),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, dynamic event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditEventScreen(event: event),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _buildEventDetails(event),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditEventScreen(event: event),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('تعديل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteEvent(context, event.id),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('حذف'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetails(dynamic event) {
    List<Widget> details = [];

    details.add(
      Row(
        children: [
          Icon(Icons.people, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '${event.volunteerIds.length} متطوع',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );

    if (event.location != null) {
      details.add(const SizedBox(width: 16));
      details.add(
        Row(
          children: [
            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                event.location,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (event.meetingPlace != null) {
      details.add(const SizedBox(width: 16));
      details.add(
        Row(
          children: [
            Icon(Icons.meeting_room, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              event.meetingPlace,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (event.administrativeType != null) {
      details.add(const SizedBox(width: 16));
      details.add(
        Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                event.administrativeType,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: details);
  }

  void _deleteEvent(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا الحدث؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              final eventProvider = Provider.of<EventProvider>(
                context,
                listen: false,
              );
              final success = await eventProvider.deleteEvent(eventId);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'تم حذف الحدث بنجاح' : 'فشل حذف الحدث',
                    ),
                  ),
                );
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
