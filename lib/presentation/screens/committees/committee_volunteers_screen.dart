// ============================================
// FILE: lib/presentation/screens/settings/committee_volunteers_screen.dart
// UPDATED: Added Excel export functionality
// UPDATED: Added permission checks for profile access
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/presentation/screens/profiles/profile_details_screen.dart';
import 'package:resala/services/excel_export_helper.dart';
import '../../providers/volunteer_provider.dart';
import '../../providers/committee_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/whale_loading.dart';
import '../../../data/models/volunteer_model.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/app_user_model.dart';

class CommitteeVolunteersScreen extends StatefulWidget {
  final String committeeId;
  final String committeeName;

  const CommitteeVolunteersScreen({
    super.key,
    required this.committeeId,
    required this.committeeName,
  });

  @override
  State<CommitteeVolunteersScreen> createState() =>
      _CommitteeVolunteersScreenState();
}

class _CommitteeVolunteersScreenState extends State<CommitteeVolunteersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  String _searchQuery = '';
  bool _isExporting = false;

  bool get _canAccessProfiles =>
      _authService.isAdmin || _authService.canAccessPage(AppPages.profiles);

  Future<void> _exportToExcel(List<VolunteerModel> volunteers) async {
    setState(() => _isExporting = true);

    try {
      // Get committee details
      final committee = await Provider.of<CommitteeProvider>(
        context,
        listen: false,
      ).getCommitteeById(widget.committeeId);

      if (committee == null) {
        throw Exception('لم يتم العثور على اللجنة');
      }

      // Export to Excel
      await ExcelExportHelper.exportCommitteeToExcel(
        committee: committee,
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
        title: Text(
          widget.committeeName,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppTheme.textDark,
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
            ).getVolunteersByCommittee(widget.committeeId),
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
                    ? WhaleLoading(size: 20)
                    : const Icon(Icons.file_download, color: AppTheme.primary),
                tooltip: 'تصدير إلى Excel',
              );
            },
          ),
        ],
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
                hintText: 'بحث',
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

          // Volunteers List
          Expanded(
            child: FutureBuilder(
              future: Provider.of<VolunteerProvider>(
                context,
                listen: false,
              ).getVolunteersByCommittee(widget.committeeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: WhaleLoading());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'حدث خطأ: ${snapshot.error}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allVolunteers = snapshot.data ?? [];

                // Filter by search query
                final volunteers = _searchQuery.isEmpty
                    ? allVolunteers
                    : allVolunteers
                          .where(
                            (v) => v.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();

                if (volunteers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'لا يوجد متطوعون في هذه اللجنة'
                              : 'لا توجد نتائج',
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
                  itemCount: volunteers.length,
                  itemBuilder: (context, index) {
                    final volunteer = volunteers[index];
                    return _buildProfileCard(volunteer);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(dynamic volunteer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(30),
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
          if (_canAccessProfiles) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfileDetailsScreen(volunteer: volunteer),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'ليس لديك صلاحية للوصول إلى البروفايلات',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Left - Person Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppTheme.cardBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const Spacer(),

              // Right - Name
              Expanded(
                flex: 3,
                child: Text(
                  volunteer.name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppTheme.cardBackground,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 12),

              // Profile Circle - Edit Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppTheme.cardBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
            ],
          ),
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
