// ============================================
// FILE: lib/screens/home/events_screen.dart
// Copy this ENTIRE file
// ============================================

import 'package:flutter/material.dart';
import 'package:resala/screens/home/create_event_screen.dart';
import 'package:resala/screens/home/edit_event_screen.dart';
import 'package:resala/screens/themes/app_theme.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedFilter = '7days';
  final List<Map<String, dynamic>> _events = [];
  final List<Map<String, dynamic>> _allEvents = [
    {
      'id': '1',
      'title': 'اجتماع فريق العمل',
      'date': '2024-11-15',
      'type': 'اجتماع',
      'description': 'اجتماع تخطيطي لفريق المتطوعين',
      'meetingPlace': 'أوفلاين بالفرع',
      'volunteers': [],
    },
    {
      'id': '2',
      'title': 'قافلة خيرية',
      'date': '2024-11-15',
      'type': 'قافلة',
      'location': 'منطقة أبو سليمان',
      'description': 'قافلة خيرية للمنطقة',
      'volunteers': [],
    },
    {
      'id': '3',
      'title': 'كرنفال ترفيهي',
      'date': '2024-11-14',
      'type': 'كرنفال',
      'location': 'حديقة المدينة',
      'description': 'كرنفال ترفيهي للأطفال',
      'volunteers': [],
    },
    {
      'id': '4',
      'title': 'اجتماع إداري',
      'date': '2024-11-12',
      'type': 'اداريات',
      'administrativeType': 'اجتماع تخطيطي',
      'description': 'اجتماع إداري شهري',
      'volunteers': [],
    },
  ];

  Map<String, List<Map<String, dynamic>>> _groupedEvents = {};

  @override
  void initState() {
    super.initState();
    _filterEvents();
  }

  void _filterEvents() {
    final now = DateTime.now();
    setState(() {
      _events.clear();

      if (_selectedFilter == '7days') {
        for (var event in _allEvents) {
          final eventDate = DateTime.parse(event['date']);
          final difference = now.difference(eventDate).inDays;
          if (difference <= 7 && difference >= 0) {
            _events.add(event);
          }
        }
      } else if (_selectedFilter == 'month') {
        for (var event in _allEvents) {
          final eventDate = DateTime.parse(event['date']);
          final difference = now.difference(eventDate).inDays;
          if (difference <= 30 && difference >= 0) {
            _events.add(event);
          }
        }
      } else if (_selectedFilter == 'all') {
        _events.addAll(_allEvents);
      }

      _events.sort((a, b) => b['date'].compareTo(a['date']));
      _groupEventsByDate();
    });
  }

  void _groupEventsByDate() {
    _groupedEvents = {};
    for (var event in _events) {
      final date = event['date'];
      if (!_groupedEvents.containsKey(date)) {
        _groupedEvents[date] = [];
      }
      _groupedEvents[date]!.add(event);
    }
  }

  void _navigateToCreateEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventScreen()),
    );
    if (result != null) {
      setState(() {
        _allEvents.add(result);
        _filterEvents();
      });
    }
  }

  void _navigateToEditEvent(Map<String, dynamic> event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditEventScreen(event: event)),
    );
    if (result != null) {
      setState(() {
        final index = _allEvents.indexWhere((e) => e['id'] == result['id']);
        if (index != -1) {
          _allEvents[index] = result;
          _filterEvents();
        }
      });
    }
  }

  void _deleteEvent(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف الحدث "${event['title']}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _allEvents.removeWhere((e) => e['id'] == event['id']);
                _filterEvents();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف الحدث بنجاح')),
              );
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
            onPressed: _navigateToCreateEvent,
            tooltip: 'إضافة حدث جديد',
          ),
        ],
      ),
      body: Container(
        color: AppTheme.primary,
        child: Column(
          children: [
            Padding(
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
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: '7days',
                              child: Text('آخر 7 أيام'),
                            ),
                            DropdownMenuItem(
                              value: 'month',
                              child: Text('آخر شهر'),
                            ),
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('جميع الأحداث'),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedFilter = newValue!;
                              _filterEvents();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: _groupedEvents.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد أحداث',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _groupedEvents.length,
                      itemBuilder: (context, index) {
                        final date = _groupedEvents.keys.elementAt(index);
                        final dayEvents = _groupedEvents[date]!;
                        return _buildDayExpansionTile(date, dayEvents);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateEvent,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDayExpansionTile(
    String date,
    List<Map<String, dynamic>> events,
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
        children: events.map((event) => _buildEventCard(event)).toList(),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToEditEvent(event),
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
                      event['title'],
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
                      color: _getEventTypeColor(event['type']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event['type'],
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
                event['description'],
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _buildEventDetails(event),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToEditEvent(event),
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
                      onPressed: () => _deleteEvent(event),
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

  Widget _buildEventDetails(Map<String, dynamic> event) {
    List<Widget> details = [];

    details.add(
      Row(
        children: [
          Icon(Icons.people, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '${event['volunteers']?.length ?? 0} متطوع',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );

    if (event['type'] == 'قافلة' ||
        event['type'] == 'كرنفال' ||
        event['type'] == 'يوم عائلي') {
      details.add(const SizedBox(width: 16));
      details.add(
        Row(
          children: [
            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                event['location'] ?? '',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (event['type'] == 'اجتماع' && event['meetingPlace'] != null) {
      details.add(const SizedBox(width: 16));
      details.add(
        Row(
          children: [
            Icon(Icons.meeting_room, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              event['meetingPlace'],
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (event['type'] == 'اداريات' && event['administrativeType'] != null) {
      details.add(const SizedBox(width: 16));
      details.add(
        Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                event['administrativeType'],
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: details);
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
}
