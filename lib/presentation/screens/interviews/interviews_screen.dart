// ============================================
// FILE: lib/presentation/screens/interviews/interviews_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/core/constants/firebase_constants.dart';
import 'package:resala/data/models/interview_model.dart';
import 'package:resala/presentation/providers/interview_provider.dart';
import 'package:resala/presentation/providers/volunteer_provider.dart';
import 'package:resala/presentation/screens/interviews/interview_details_screen.dart';
import 'package:resala/presentation/themes/app_theme.dart';

class InterviewsScreen extends StatefulWidget {
  const InterviewsScreen({super.key});

  @override
  State<InterviewsScreen> createState() => _InterviewsScreenState();
}

class _InterviewsScreenState extends State<InterviewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyWithoutInterviews = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'المقابلات الشخصية',
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'بحث باسم المتطوع',
                hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Toggle for showing volunteers without interviews
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showOnlyWithoutInterviews =
                            !_showOnlyWithoutInterviews;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _showOnlyWithoutInterviews
                            ? AppTheme.primary.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _showOnlyWithoutInterviews
                              ? AppTheme.primary
                              : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showOnlyWithoutInterviews
                                ? Icons.filter_alt
                                : Icons.filter_alt_outlined,
                            color: _showOnlyWithoutInterviews
                                ? AppTheme.primary
                                : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showOnlyWithoutInterviews
                                ? 'من لم يتم مقابلتهم'
                                : 'عرض الكل',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _showOnlyWithoutInterviews
                                  ? AppTheme.primary
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Interview Status Filter
                // In InterviewsScreen, update the filter section:
                // Interview Status Filter
                Expanded(
                  child: Consumer<InterviewProvider>(
                    builder: (context, interviewProvider, child) {
                      return PopupMenuButton<String>(
                        onSelected: (value) {
                          interviewProvider.setFilterStatus(value);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'all',
                            child: Text('الكل'),
                          ),
                          const PopupMenuItem(
                            value: 'pending',
                            child: Text('قيد الانتظار'),
                          ),
                          const PopupMenuItem(
                            value: 'passed',
                            child: Text('ناجح'),
                          ),
                          const PopupMenuItem(
                            value: 'failed',
                            child: Text('راسب'),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getFilterText(interviewProvider.filterStatus),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Volunteers/Interviews List
          Expanded(
            child: _showOnlyWithoutInterviews
                ? _buildVolunteersWithoutInterviews()
                : _buildInterviewsList(),
          ),
        ],
      ),
      floatingActionButton: _showOnlyWithoutInterviews
          ? FloatingActionButton(
              onPressed: () {
                // Add logic to schedule new interview
                _showScheduleInterviewDialog(context);
              },
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.calendar_today, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildVolunteersWithoutInterviews() {
    return StreamBuilder(
      stream: Provider.of<VolunteerProvider>(
        context,
        listen: false,
      ).searchVolunteers(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ: ${snapshot.error}',
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.red),
            ),
          );
        }

        final volunteers = snapshot.data ?? [];

        if (volunteers.isEmpty) {
          return const Center(
            child: Text(
              'لا يوجد متطوعين',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          );
        }

        return FutureBuilder(
          future: Provider.of<InterviewProvider>(
            context,
            listen: false,
          ).getVolunteersWithoutInterviews(volunteers),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            final volunteersWithoutInterviews = asyncSnapshot.data ?? [];

            if (volunteersWithoutInterviews.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'تمت مقابلة جميع المتطوعين',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: volunteersWithoutInterviews.length,
              itemBuilder: (context, index) {
                final volunteer = volunteersWithoutInterviews[index];
                return _buildVolunteerCard(volunteer);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInterviewsList() {
    return Consumer<InterviewProvider>(
      builder: (context, interviewProvider, child) {
        final filteredInterviews = interviewProvider.filteredInterviews.where((
          interview,
        ) {
          if (_searchQuery.isEmpty) return true;
          return interview.volunteerName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
        }).toList();

        if (filteredInterviews.isEmpty) {
          return const Center(
            child: Text(
              'لا يوجد مقابلات',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredInterviews.length,
          itemBuilder: (context, index) {
            final interview = filteredInterviews[index];
            return _buildInterviewCard(interview);
          },
        );
      },
    );
  }

  Widget _buildVolunteerCard(dynamic volunteer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _showScheduleInterviewDialog(context, volunteer);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Interview Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // Volunteer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      volunteer.name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (volunteer.committeeName != null &&
                        volunteer.committeeName!.isNotEmpty)
                      Text(
                        volunteer.committeeName!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (volunteer.age != null)
                      Text(
                        'العمر: ${volunteer.age}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Schedule Button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'جدولة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterviewCard(InterviewModel interview) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (interview.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'قيد الانتظار';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        statusText = 'مكتمل';
        break;
      case 'passed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'ناجح';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'راسب';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'غير معروف';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  InterviewDetailsScreen(interview: interview),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Status Indicator
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 16),

              // Interview Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      interview.volunteerName,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'تاريخ المقابلة: ${_formatDate(interview.interviewDate)}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    if (interview.totalGrade != null)
                      Text(
                        'الدرجة: ${interview.totalGrade}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: interview.passed == true
                              ? Colors.green
                              : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFilterText(String status) {
    switch (status) {
      case 'all':
        return 'الكل';
      case 'pending':
        return 'قيد الانتظار';
      case 'completed':
        return 'مكتمل';
      case 'passed':
        return 'ناجح';
      case 'failed':
        return 'راسب';
      default:
        return 'الكل';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showScheduleInterviewDialog(BuildContext context, [dynamic volunteer]) {
    final nameController = TextEditingController();
    final dateController = TextEditingController();
    DateTime? selectedDate;

    if (volunteer != null) {
      nameController.text = volunteer.name;
    }

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'جدولة مقابلة جديدة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (volunteer == null)
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المتطوع',
                      hintText: 'أدخل اسم المتطوع',
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'تاريخ المقابلة',
                    hintText: 'اختر التاريخ',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                          dateController.text =
                              '${picked.day}/${picked.month}/${picked.year}';
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى ملء جميع الحقول'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final interviewProvider = Provider.of<InterviewProvider>(
                  context,
                  listen: false,
                );

                final volunteerProvider = Provider.of<VolunteerProvider>(
                  context,
                  listen: false,
                );

                String volunteerId;
                if (volunteer != null) {
                  volunteerId = volunteer.id;
                } else {
                  // Find volunteer by name
                  final allVolunteers = await volunteerProvider
                      .getVolunteers()
                      .first;
                  final foundVolunteer = allVolunteers.firstWhere(
                    (v) => v.name == nameController.text,
                  );

                  volunteerId = foundVolunteer.id;
                }

                final interviewId = await interviewProvider.createInterview(
                  volunteerId: volunteerId,
                  volunteerName: nameController.text,
                  interviewDate: selectedDate!,
                );

                if (interviewId != null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم جدولة المقابلة بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
