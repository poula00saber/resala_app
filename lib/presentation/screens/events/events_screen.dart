// ============================================
// FILE: lib/presentation/screens/events/events_screen.dart
// REDESIGNED to match your UI
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

  // ==============================
  // 🔽 FILTER MENU (WORKING FIX)
  // ==============================
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
              title: const Text("آخر ٧ أيام"),
              onTap: () {
                provider.setFilter(EventFilter.last7Days);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("آخر شهر"),
              onTap: () {
                provider.setFilter(EventFilter.lastMonth);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("جميع الأحداث"),
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
      backgroundColor: const Color(0xFFE8DDD3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8DDD3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'الأحداث',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // =======================================
          // 🔽 FILTER CHOOSER (DROPDOWN CHIP)
          // =======================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Consumer<EventProvider>(
              builder: (context, eventProvider, _) {
                String filterText = '';

                switch (eventProvider.currentFilter) {
                  case EventFilter.last7Days:
                    filterText = 'آخر ٧ أيام';
                    break;
                  case EventFilter.lastMonth:
                    filterText = 'آخر شهر';
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
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          filterText,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // =======================================
          // ADD EVENT BUTTON
          // =======================================
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // =======================================
          // EVENTS CONTAINER
          // =======================================
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
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
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
            ),
          ),
        ],
      ),
    );
  }

  // =======================================
  // DAY TILE (EXPANDABLE)
  // =======================================
  Widget _buildDayExpansionTile(
    BuildContext context,
    String date,
    List<dynamic> events,
  ) {
    final dayName = _getArabicDayName(date);
    final dateTime = DateTime.parse(date);
    final day = dateTime.day.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, color: AppTheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                day,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'منذ أسبوع',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_drop_down, color: Color(0xFF8B6B7C)),
          children: events
              .map((event) => _buildEventItem(context, event))
              .toList(),
        ),
      ),
    );
  }

  // =======================================
  // EVENT ITEM (INSIDE EXPANSION TILE)
  // =======================================
  Widget _buildEventItem(BuildContext context, dynamic event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 28),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (event.location != null) ...[
                          Text(
                            event.location,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (event.meetingPlace != null) ...[
                          Text(
                            event.meetingPlace,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Text(
                          'عدد المتطوعين',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.volunteerIds.length.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          'المكان',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'إحصائية',
                          style: TextStyle(color: Colors.white, fontSize: 12),
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
