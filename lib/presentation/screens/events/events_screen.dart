// ============================================
// FILE: lib/presentation/screens/events/events_screen.dart
// UPDATED: Calculates shirt count from volunteers' hasTshirt field
// UPDATED: Shows committee name for meetings (type: 'اجتماع')
// UPDATED: Added long press delete functionality
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import 'edit_event_screen.dart';
import 'create_event_screen.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/app_user_model.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final AuthService _authService = AuthService();
  bool _isDeleteMode = false;
  Set<String> _selectedForDelete = {};

  bool get _canAddDelete =>
      _authService.isAdmin || _authService.canAddDeleteOnPage(AppPages.events);

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

  String _getMonthName(int month) {
    const arabicMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return arabicMonths[month - 1];
  }

  Future<String> _getEventTypeDetails(
    BuildContext context,
    dynamic event,
  ) async {
    // Check if it's a meeting event
    if (event.type == 'اجتماع') {
      // Show committee name or meeting type
      if (event.committeeName != null && event.committeeName!.isNotEmpty) {
        return 'لجنة: ${event.committeeName}';
      } else if (event.administrativeType == 'اجتماع ليدرات') {
        return 'اجتماع ليدرات';
      } else if (event.administrativeType == 'اجتماع للكل') {
        return 'اجتماع للكل';
      } else {
        return 'اجتماع';
      }
    }
    // Check if it's an administrative event
    else if (event.type == 'اداريات' && event.administrativeType != null) {
      return 'نوع: ${event.administrativeType}';
    }
    // Check if it's a carnival
    else if (event.type == 'كرنفال') {
      final shirtCount = await _calculateShirtCountFromVolunteers(
        context,
        event,
      );
      return 'كرنفال - التيشيرتات: $shirtCount';
    }
    // Check if it's a family day
    else if (event.type == 'يوم عائلي') {
      final shirtCount = await _calculateShirtCountFromVolunteers(
        context,
        event,
      );
      return 'يوم عائلي - التيشيرتات: $shirtCount';
    }
    // For other event types
    return event.type;
  }

  // Calculate shirt count from volunteers' hasTshirt field
  Future<int> _calculateShirtCountFromVolunteers(
    BuildContext context,
    dynamic event,
  ) async {
    if (event.volunteerIds.isEmpty) return 0;

    try {
      final volunteerProvider = Provider.of<VolunteerProvider>(
        context,
        listen: false,
      );
      final volunteers = await volunteerProvider.getVolunteersByIds(
        event.volunteerIds,
      );

      int shirtCount = 0;
      for (var volunteer in volunteers) {
        if (volunteer.hasTshirt) {
          shirtCount++;
        }
      }
      return shirtCount;
    } catch (e) {
      print('Error calculating shirt count: $e');
      return 0;
    }
  }

  IconData _getEventTypeIcon(dynamic event) {
    switch (event.type) {
      case 'اداريات':
        return Icons.admin_panel_settings;
      case 'اجتماع':
        return Icons.groups;
      case 'كرنفال':
        return Icons.celebration;
      case 'يوم عائلي':
        return Icons.family_restroom;
      case 'قافلة':
        return Icons.directions_bus;
      default:
        return Icons.event;
    }
  }

  void _showFilterMenu(BuildContext context, EventProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'فلترة الأحداث',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildFilterOption(
                  context,
                  'في خلال ٧ أيام',
                  Icons.calendar_today,
                  () {
                    provider.setFilter(EventFilter.last7Days);
                    Navigator.pop(context);
                  },
                ),
                _buildDivider(),
                _buildFilterOption(
                  context,
                  'في خلال شهر',
                  Icons.calendar_month,
                  () {
                    provider.setFilter(EventFilter.lastMonth);
                    Navigator.pop(context);
                  },
                ),
                _buildDivider(),
                _buildFilterOption(context, 'جميع الأحداث', Icons.event, () {
                  provider.setFilter(EventFilter.all);
                  Navigator.pop(context);
                }),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_left, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            // Static Header Section - Always visible at top
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                children: [
                  // Title and Filter Row
                  Row(
                    children: [
                      // Back Button or Cancel Delete Mode
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isDeleteMode ? Icons.close : Icons.arrow_back,
                            color: Colors.black87,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (_isDeleteMode) {
                              setState(() {
                                _isDeleteMode = false;
                                _selectedForDelete.clear();
                              });
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Title
                      Expanded(
                        child: Text(
                          _isDeleteMode
                              ? 'حذف (${_selectedForDelete.length})'
                              : 'الأحداث',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.black87,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Delete button when in delete mode
                      if (_isDeleteMode && _selectedForDelete.isNotEmpty)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            padding: EdgeInsets.zero,
                            onPressed: _confirmDeleteSelected,
                          ),
                        )
                      else
                        // Filter Button
                        Consumer<EventProvider>(
                          builder: (context, eventProvider, _) {
                            String filterText = '';
                            IconData filterIcon = Icons.filter_list;

                            switch (eventProvider.currentFilter) {
                              case EventFilter.last7Days:
                                filterText = 'منذ ٧ أيام';
                                filterIcon = Icons.calendar_today;
                                break;
                              case EventFilter.lastMonth:
                                filterText = 'منذ شهر';
                                filterIcon = Icons.calendar_month;
                                break;
                              case EventFilter.all:
                                filterText = 'الكل';
                                filterIcon = Icons.event;
                                break;
                            }

                            return InkWell(
                              onTap: () =>
                                  _showFilterMenu(context, eventProvider),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.05),
                                  border: Border.all(
                                    color: AppTheme.primary.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      filterIcon,
                                      color: AppTheme.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      filterText,
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        color: AppTheme.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Add Event Button - Only show if user can add
                  if (!_isDeleteMode && _canAddDelete)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'إضافة حدث جديد',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Events List Container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primary.withOpacity(0.95),
                      AppTheme.primary,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Consumer<EventProvider>(
                  builder: (context, eventProvider, _) {
                    if (eventProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      );
                    }

                    final groupedEvents = eventProvider.getGroupedEvents();

                    if (groupedEvents.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_available,
                                size: 64,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'لا توجد أحداث حالياً',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: Text(
                                'اضغط على زر "إضافة حدث جديد" لبدء إدارة الأحداث',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                      itemCount: groupedEvents.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final date = groupedEvents.keys.elementAt(index);
                        final dayEvents = groupedEvents[date]!;
                        final dateTime = DateTime.parse(date);

                        return _DayCard(
                          date: date,
                          events: dayEvents,
                          dayName: _getArabicDayName(date),
                          day: dateTime.day,
                          month: _getMonthName(dateTime.month),
                          getEventTypeIcon: _getEventTypeIcon,
                          isDeleteMode: _isDeleteMode,
                          selectedForDelete: _selectedForDelete,
                          canDelete: _canAddDelete,
                          onDeleteModeChanged: (isDelete, eventId) {
                            setState(() {
                              _isDeleteMode = isDelete;
                              if (eventId != null) {
                                _selectedForDelete.add(eventId);
                              }
                            });
                          },
                          onSelectionChanged: (eventId, isSelected) {
                            setState(() {
                              if (isSelected) {
                                _selectedForDelete.add(eventId);
                              } else {
                                _selectedForDelete.remove(eventId);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSelected() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'حذف الأحداث',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          content: Text(
            'هل أنت متأكد من حذف ${_selectedForDelete.length} حدث؟',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteSelected();
              },
              child: const Text(
                'حذف',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final provider = Provider.of<EventProvider>(context, listen: false);

    for (final id in _selectedForDelete) {
      await provider.deleteEvent(id);
    }

    if (mounted) {
      setState(() {
        _isDeleteMode = false;
        _selectedForDelete.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الحذف بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Day Card Widget
class _DayCard extends StatefulWidget {
  final String date;
  final List<dynamic> events;
  final String dayName;
  final int day;
  final String month;
  final IconData Function(dynamic) getEventTypeIcon;
  final bool isDeleteMode;
  final Set<String> selectedForDelete;
  final bool canDelete;
  final Function(bool isDelete, String? eventId) onDeleteModeChanged;
  final Function(String eventId, bool isSelected) onSelectionChanged;

  const _DayCard({
    required this.date,
    required this.events,
    required this.dayName,
    required this.day,
    required this.month,
    required this.getEventTypeIcon,
    required this.isDeleteMode,
    required this.selectedForDelete,
    required this.canDelete,
    required this.onDeleteModeChanged,
    required this.onSelectionChanged,
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Day Header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Day Number Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.day.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${widget.events.length} حدث',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Day Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dayName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.month,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: AppTheme.primary,
                                size: 28,
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

          // Events List (Animated)
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                Container(height: 1, color: Colors.grey[200]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    children: widget.events
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _EventTile(
                              event: event,
                              getEventTypeIcon: widget.getEventTypeIcon,
                              isDeleteMode: widget.isDeleteMode,
                              isSelected: widget.selectedForDelete.contains(
                                event.id,
                              ),
                              canDelete: widget.canDelete,
                              onLongPress: () =>
                                  widget.onDeleteModeChanged(true, event.id),
                              onSelectionChanged: () {
                                final isSelected = widget.selectedForDelete
                                    .contains(event.id);
                                widget.onSelectionChanged(
                                  event.id,
                                  !isSelected,
                                );
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Event Tile Widget
class _EventTile extends StatefulWidget {
  final dynamic event;
  final IconData Function(dynamic) getEventTypeIcon;
  final bool isDeleteMode;
  final bool isSelected;
  final bool canDelete;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionChanged;

  const _EventTile({
    required this.event,
    required this.getEventTypeIcon,
    this.isDeleteMode = false,
    this.isSelected = false,
    this.canDelete = false,
    this.onLongPress,
    this.onSelectionChanged,
  });

  @override
  State<_EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<_EventTile> {
  int _shirtCount = 0;
  bool _isLoadingShirtCount = false;
  String _eventTypeDetails = '';

  @override
  void initState() {
    super.initState();
    // Load appropriate details based on event type
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    // Check if it's a carnival or family day to load shirt count
    if (widget.event.type == 'كرنفال' || widget.event.type == 'يوم عائلي') {
      await _loadShirtCountAndDetails();
    } else {
      await _loadEventTypeDetails();
    }
  }

  Future<void> _loadShirtCountAndDetails() async {
    setState(() => _isLoadingShirtCount = true);

    try {
      // Get shirt count from volunteers
      final volunteerProvider = Provider.of<VolunteerProvider>(
        context,
        listen: false,
      );

      if (widget.event.volunteerIds.isNotEmpty) {
        final volunteers = await volunteerProvider.getVolunteersByIds(
          widget.event.volunteerIds,
        );

        int count = 0;
        for (var volunteer in volunteers) {
          if (volunteer.hasTshirt) {
            count++;
          }
        }

        _shirtCount = count;
      }

      // Set event type details with shirt count
      _eventTypeDetails = '${widget.event.type} - التيشيرتات: $_shirtCount';

      setState(() => _isLoadingShirtCount = false);
    } catch (e) {
      print('Error loading shirt count: $e');
      _eventTypeDetails = widget.event.type;
      setState(() => _isLoadingShirtCount = false);
    }
  }

  Future<void> _loadEventTypeDetails() async {
    // For meeting events
    if (widget.event.type == 'اجتماع') {
      // Show committee name or meeting type
      if (widget.event.committeeName != null &&
          widget.event.committeeName!.isNotEmpty) {
        _eventTypeDetails = 'لجنة: ${widget.event.committeeName}';
      } else if (widget.event.administrativeType == 'اجتماع ليدرات') {
        _eventTypeDetails = 'اجتماع ليدرات';
      } else if (widget.event.administrativeType == 'اجتماع للكل') {
        _eventTypeDetails = 'اجتماع للكل';
      } else {
        _eventTypeDetails = 'اجتماع';
      }
    }
    // For administrative events
    else if (widget.event.type == 'اداريات' &&
        widget.event.administrativeType != null) {
      _eventTypeDetails = 'نوع: ${widget.event.administrativeType}';
    }
    // For other event types
    else {
      _eventTypeDetails = widget.event.type;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeIcon = widget.getEventTypeIcon(widget.event);
    final volunteerCount = widget.event.volunteerIds.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (widget.isDeleteMode) {
                  widget.onSelectionChanged?.call();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditEventScreen(event: widget.event),
                    ),
                  );
                }
              },
              onLongPress: widget.canDelete ? widget.onLongPress : null,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Title and Arrow
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.event.title,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Event Type Details
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Flexible(
                            child:
                                _isLoadingShirtCount &&
                                    (widget.event.type == 'كرنفال' ||
                                        widget.event.type == 'يوم عائلي')
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _eventTypeDetails,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Event Stats
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // Volunteers Count
                        _buildStatItem(
                          Icons.people,
                          'المتطوعين',
                          volunteerCount.toString().padLeft(2, '0'),
                          Colors.white,
                        ),

                        // Shirt Count (for specific event types)
                        if (widget.event.type == 'كرنفال' ||
                            widget.event.type == 'يوم عائلي')
                          _isLoadingShirtCount
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _buildStatItem(
                                  Icons.checkroom,
                                  'التيشيرتات',
                                  _shirtCount.toString().padLeft(2, '0'),
                                  Colors.white,
                                ),

                        if (widget.event.location != null ||
                            widget.event.meetingPlace != null)
                          _buildStatItem(
                            Icons.location_on,
                            'المكان',
                            widget.event.location ??
                                widget.event.meetingPlace ??
                                '',
                            Colors.white,
                          ),
                      ],
                    ),

                    // Comparison Section - Shows if we have enough shirts
                    if ((widget.event.type == 'كرنفال' ||
                            widget.event.type == 'يوم عائلي') &&
                        volunteerCount > 0 &&
                        !_isLoadingShirtCount)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildComparisonBadge(
                          volunteerCount,
                          _shirtCount,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Selection indicator for delete mode
          if (widget.isDeleteMode)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.isSelected ? Colors.red : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected ? Colors.red : Colors.grey,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: color.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBadge(int volunteerCount, int shirtCount) {
    String message;
    Color badgeColor;
    IconData icon;

    if (shirtCount == 0) {
      message = 'لا توجد قمصان مطلوبة';
      badgeColor = Colors.grey;
      icon = Icons.info;
    } else if (shirtCount >= volunteerCount) {
      message = 'عدد التيشيرتات كافي';
      badgeColor = Colors.green;
      icon = Icons.check_circle;
    } else if (shirtCount >= volunteerCount * 0.5) {
      message = 'عدد التيشيرتات متوسط';
      badgeColor = Colors.orange;
      icon = Icons.warning;
    } else {
      message = 'عدد التيشيرتات غير كافي';
      badgeColor = Colors.red;
      icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: badgeColor, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: badgeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
