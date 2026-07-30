// ============================================
// FILE: lib/presentation/screens/interviews/interviews_screen.dart
// FIXED: Prevents duplicate interviews - always checks existing first
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/data/models/interview_model.dart';
import 'package:resala/data/models/volunteer_model.dart';
import 'package:resala/presentation/providers/interview_provider.dart';
import 'package:resala/presentation/providers/volunteer_provider.dart';
import 'package:resala/presentation/screens/interviews/interview_details_screen.dart';
import 'package:resala/presentation/themes/app_theme.dart';
import '../../widgets/whale_loading.dart';

class InterviewsScreen extends StatefulWidget {
  const InterviewsScreen({super.key});

  @override
  State<InterviewsScreen> createState() => _InterviewsScreenState();
}

class _InterviewsScreenState extends State<InterviewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Stream<List<VolunteerModel>> _volunteerStream;
  String _searchQuery = '';
  List<String> _selectedFilters = ['لم تتم مقابلتهم'];

  @override
  void initState() {
    super.initState();
    _volunteerStream = Provider.of<VolunteerProvider>(
      context,
      listen: false,
    ).searchVolunteers(_searchQuery);
  }

  final List<String> _filterOptions = ['لم تتم مقابلتهم', 'مقبولين', 'مرفوضين'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'المقابلات الشخصية',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: AppTheme.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
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
                  color: AppTheme.secondary,
                ),
                prefixIcon: const Icon(Icons.search, color: AppTheme.secondary),
                filled: true,
                fillColor: AppTheme.cardBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _volunteerStream = Provider.of<VolunteerProvider>(
                    context,
                    listen: false,
                  ).searchVolunteers(_searchQuery);
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "الكل" button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedFilters.length ==
                              _filterOptions.length) {
                            _selectedFilters = ['لم تتم مقابلتهم'];
                          } else {
                            _selectedFilters = List.from(_filterOptions);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _selectedFilters.length == _filterOptions.length
                              ? AppTheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'الكل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                _selectedFilters.length == _filterOptions.length
                                ? Colors.white
                                : AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Individual filter chips
                  ..._filterOptions.map((option) {
                    final isSelected = _selectedFilters.contains(option);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedFilters.remove(option);
                              if (_selectedFilters.isEmpty) {
                                _selectedFilters.add(option);
                              }
                            } else {
                              _selectedFilters.add(option);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildListByFilter()),
        ],
      ),
    );
  }

  Widget _buildListByFilter() {
    // If all filters selected or "الكل" equivalent
    if (_selectedFilters.length == _filterOptions.length) {
      return _buildAllVolunteers();
    }

    // Build a combined list based on selected filters
    return _buildCombinedFilteredList();
  }

  Widget _buildCombinedFilteredList() {
    final showNotInterviewed = _selectedFilters.contains('لم تتم مقابلتهم');
    final showPassed = _selectedFilters.contains('مقبولين');
    final showFailed = _selectedFilters.contains('مرفوضين');

    // If only one filter, use the dedicated method
    if (_selectedFilters.length == 1) {
      if (showNotInterviewed) return _buildVolunteersWithoutInterviews();
      if (showPassed) return _buildPassedInterviews();
      if (showFailed) return _buildFailedInterviews();
    }

    // Multiple filters: combine results
    return StreamBuilder(
      stream: _volunteerStream,
      builder: (context, volunteerSnapshot) {
        if (volunteerSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: WhaleLoading());
        }

        final volunteers = volunteerSnapshot.data ?? [];

        return Consumer<InterviewProvider>(
          builder: (context, interviewProvider, child) {
            return FutureBuilder(
              future: _buildCombinedList(
                volunteers,
                interviewProvider,
                showNotInterviewed,
                showPassed,
                showFailed,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: WhaleLoading());
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا يوجد نتائج',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppTheme.secondary,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is InterviewModel) {
                      return _buildInterviewCard(item);
                    } else {
                      return _buildVolunteerCard(item);
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _buildCombinedList(
    List<dynamic> volunteers,
    InterviewProvider interviewProvider,
    bool showNotInterviewed,
    bool showPassed,
    bool showFailed,
  ) async {
    List<dynamic> results = [];

    if (showPassed) {
      final passedInterviews = interviewProvider.interviews
          .where((interview) => interview.passed == true)
          .where((interview) {
            if (_searchQuery.isEmpty) return true;
            return interview.volunteerName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
          })
          .toList();
      results.addAll(passedInterviews);
    }

    if (showFailed) {
      final failedInterviews = interviewProvider.interviews
          .where((interview) => interview.passed == false)
          .where((interview) {
            if (_searchQuery.isEmpty) return true;
            return interview.volunteerName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
          })
          .toList();
      results.addAll(failedInterviews);
    }

    if (showNotInterviewed) {
      final volunteersWithout = await interviewProvider
          .getVolunteersWithoutInterviews(volunteers);
      results.addAll(volunteersWithout);
    }

    return results;
  }

  Widget _buildAllVolunteers() {
    return StreamBuilder(
      stream: _volunteerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: WhaleLoading());
        }

        final volunteers = snapshot.data ?? [];

        if (volunteers.isEmpty) {
          return const Center(
            child: Text(
              'لا يوجد متطوعين',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppTheme.secondary,
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: volunteers.length,
          itemBuilder: (context, index) {
            final volunteer = volunteers[index];
            return _buildVolunteerCard(volunteer);
          },
        );
      },
    );
  }

  Widget _buildPassedInterviews() {
    return Consumer<InterviewProvider>(
      builder: (context, interviewProvider, child) {
        final passedInterviews = interviewProvider.interviews
            .where((interview) => interview.passed == true)
            .where((interview) {
              if (_searchQuery.isEmpty) return true;
              return interview.volunteerName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
            })
            .toList();

        if (passedInterviews.isEmpty) {
          return const Center(
            child: Text(
              'لا يوجد متطوعين مقبولين',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppTheme.secondary,
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: passedInterviews.length,
          itemBuilder: (context, index) {
            final interview = passedInterviews[index];
            return _buildInterviewCard(interview);
          },
        );
      },
    );
  }

  Widget _buildFailedInterviews() {
    return Consumer<InterviewProvider>(
      builder: (context, interviewProvider, child) {
        final failedInterviews = interviewProvider.interviews
            .where((interview) => interview.passed == false)
            .where((interview) {
              if (_searchQuery.isEmpty) return true;
              return interview.volunteerName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
            })
            .toList();

        if (failedInterviews.isEmpty) {
          return const Center(
            child: Text(
              'لا يوجد متطوعين مرفوضين',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppTheme.secondary,
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: failedInterviews.length,
          itemBuilder: (context, index) {
            final interview = failedInterviews[index];
            return _buildInterviewCard(interview);
          },
        );
      },
    );
  }

  Widget _buildVolunteersWithoutInterviews() {
    return StreamBuilder(
      stream: _volunteerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: WhaleLoading());
        }

        final volunteers = snapshot.data ?? [];

        if (volunteers.isEmpty) {
          return const Center(
            child: Text(
              'لا يوجد متطوعين',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppTheme.secondary,
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
              return Center(child: WhaleLoading());
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
                        color: AppTheme.secondary,
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

  Widget _buildVolunteerCard(dynamic volunteer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          // FIXED: Always check for existing interview first
          await _openInterviewForVolunteer(context, volunteer);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Interview Icon
              FutureBuilder<List<InterviewModel>>(
                future: Provider.of<InterviewProvider>(
                  context,
                  listen: false,
                ).getInterviewsByVolunteerId(volunteer.id),
                builder: (context, snapshot) {
                  final hasInterview =
                      snapshot.hasData && snapshot.data!.isNotEmpty;

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasInterview
                          ? Colors.green.withOpacity(0.1)
                          : AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasInterview ? Icons.edit : Icons.person_add,
                      color: hasInterview ? Colors.green : AppTheme.primary,
                      size: 20,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),

              // Volunteer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            volunteer.name,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppTheme.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Interview status badge
                        FutureBuilder<List<InterviewModel>>(
                          future: Provider.of<InterviewProvider>(
                            context,
                            listen: false,
                          ).getInterviewsByVolunteerId(volunteer.id),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const SizedBox();
                            }

                            final interview = snapshot.data!.first;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: interview.passed == true
                                    ? Colors.green.withOpacity(0.1)
                                    : interview.passed == false
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: interview.passed == true
                                      ? Colors.green
                                      : interview.passed == false
                                      ? Colors.red
                                      : Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                interview.passed == true
                                    ? 'مقبول'
                                    : interview.passed == false
                                    ? 'مرفوض'
                                    : 'قيد المراجعة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 8,
                                  color: interview.passed == true
                                      ? Colors.green
                                      : interview.passed == false
                                      ? Colors.red
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    if (volunteer.committeeName != null &&
                        volunteer.committeeName!.isNotEmpty)
                      Text(
                        volunteer.committeeName!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: AppTheme.secondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    if (volunteer.age != null)
                      Text(
                        'العمر: ${volunteer.age}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: AppTheme.secondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Action Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.cardBackground,
                  size: 16,
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

    if (interview.passed == true) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'ناجح';
    } else if (interview.passed == false) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'راسب';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = 'قيد الانتظار';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      interview.volunteerName,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppTheme.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    Text(
                      'تاريخ المقابلة: ${_formatDate(interview.interviewDate)}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppTheme.secondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    if (interview.totalGrade != null)
                      Text(
                        'الدرجة: ${interview.totalGrade}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
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

  // FIXED: This method now ALWAYS checks for existing interview first
  // and NEVER creates duplicates
  Future<void> _openInterviewForVolunteer(
    BuildContext context,
    dynamic volunteer,
  ) async {
    print('\n==========================================');
    print('🔍 Opening interview for: ${volunteer.name}');
    print('   Volunteer ID: ${volunteer.id}');
    print('==========================================');

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: WhaleLoading()),
    );

    final interviewProvider = Provider.of<InterviewProvider>(
      context,
      listen: false,
    );

    try {
      // STEP 1: Check if volunteer already has an interview
      print('📋 Step 1: Checking for existing interviews...');
      final existingInterviews = await interviewProvider
          .getInterviewsByVolunteerId(volunteer.id);

      print('   Found ${existingInterviews.length} existing interview(s)');

      InterviewModel? interview;

      if (existingInterviews.isNotEmpty) {
        // ✅ Volunteer HAS interview - use existing one
        interview = existingInterviews.first;
        print('✅ USING EXISTING INTERVIEW');
        print('   Interview ID: ${interview.id}');
        print('   Status: ${interview.status}');
        print('   Passed: ${interview.passed}');
        print('   Answers count: ${interview.answers.length}');
      } else {
        // ✅ Volunteer DOESN'T have interview - create new one
        print('📝 NO EXISTING INTERVIEW - Creating new one...');

        final interviewId = await interviewProvider.createInterview(
          volunteerId: volunteer.id,
          volunteerName: volunteer.name,
          interviewDate: DateTime.now(),
        );

        print('   Created interview ID: $interviewId');

        if (interviewId != null) {
          // Fetch the newly created interview
          interview = await interviewProvider.getInterviewById(interviewId);
          print('   Fetched new interview successfully');
        } else {
          print('❌ Failed to create interview');
        }
      }

      // Close loading dialog
      Navigator.pop(context);

      if (interview != null) {
        print('✅ Navigating to interview details screen');
        print('==========================================\n');

        // Navigate to interview details
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InterviewDetailsScreen(interview: interview!),
          ),
        );

        // Keep the current screen state and let the providers update in place.
        if (result == true || result == null) {
          // no-op
        }
      } else {
        print('❌ Interview is null - cannot navigate');
        print('==========================================\n');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'حدث خطأ أثناء فتح المقابلة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ EXCEPTION in _openInterviewForVolunteer: $e');
      print('==========================================\n');

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: ${e.toString()}',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
