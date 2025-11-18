// ============================================
// FILE: lib/presentation/screens/events/events_screen.dart
// FIXED: Separate day cards + exact design match
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../themes/app_theme.dart';
import 'edit_event_screen.dart';
import 'create_event_screen.dart';

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

  void _showFilterMenu(BuildContext context, EventProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                "في خلال ٧ أيام",
                style: TextStyle(fontFamily: 'Cairo'),
                textAlign: TextAlign.right,
              ),
              onTap: () {
                provider.setFilter(EventFilter.last7Days);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(
                "في خلال شهر",
                style: TextStyle(fontFamily: 'Cairo'),
                textAlign: TextAlign.right,
              ),
              onTap: () {
                provider.setFilter(EventFilter.lastMonth);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(
                "جميع الأحداث",
                style: TextStyle(fontFamily: 'Cairo'),
                textAlign: TextAlign.right,
              ),
              onTap: () {
                provider.setFilter(EventFilter.all);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
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
          'الأحداث',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Consumer<EventProvider>(
              builder: (context, eventProvider, _) {
                String filterText = '';
                switch (eventProvider.currentFilter) {
                  case EventFilter.last7Days:
                    filterText = 'الاسبوع القادم';
                    break;
                  case EventFilter.lastMonth:
                    filterText = 'الشهر القادم';
                    break;
                  case EventFilter.all:
                    filterText = 'جميع الأحداث';
                    break;
                }

                return InkWell(
                  onTap: () => _showFilterMenu(context, eventProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primary),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          filterText,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppTheme.primary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Add Event Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateEventScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_circle_outline, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'إضافة حدث',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Events Container
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Consumer<EventProvider>(
                  builder: (context, eventProvider, _) {
                    if (eventProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final groupedEvents = eventProvider.getGroupedEvents();

                    if (groupedEvents.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد أحداث',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedEvents.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final date = groupedEvents.keys.elementAt(index);
                        final dayEvents = groupedEvents[date]!;
                        return _DayCard(
                          date: date,
                          events: dayEvents,
                          dayName: _getArabicDayName(date),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Separate Day Card Widget with its own state
class _DayCard extends StatefulWidget {
  final String date;
  final List<dynamic> events;
  final String dayName;

  const _DayCard({
    required this.date,
    required this.events,
    required this.dayName,
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime.parse(widget.date);
    final day = dateTime.day.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Day Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Right side - Day info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.dayName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'منذ أسبوع',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Center - Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'عدد الأحداث',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.events.length.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Left side - Dropdown arrow
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),

          // Events List (Expandable)
          if (_isExpanded)
            ...widget.events.map((event) => _EventTile(event: event)).toList(),
        ],
      ),
    );
  }
}

// Event Tile Widget
class _EventTile extends StatelessWidget {
  final dynamic event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditEventScreen(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Dropdown icon
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),

              const SizedBox(width: 12),

              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Event title
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Location or meeting place
                        if (event.location != null ||
                            event.meetingPlace != null)
                          Flexible(
                            child: Text(
                              event.location ?? event.meetingPlace ?? '',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        if (event.location != null ||
                            event.meetingPlace != null)
                          const SizedBox(width: 12),

                        // Volunteer count
                        Text(
                          event.volunteerIds.length.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'عدد المتطوعين',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          'إحصائية',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'المكان',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
