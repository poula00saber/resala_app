// ============================================
// FILE: lib/presentation/screens/settings/committees_management_screen.dart
// UPDATED: Collapse/expand with inline volunteers (#16)
// UPDATED: Removed description from committees (#17)
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/committee_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import '../profiles/profile_details_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/excel_export_helper.dart';
import '../../../data/models/app_user_model.dart';
import '../../../data/models/volunteer_model.dart';

class CommitteesManagementScreen extends StatefulWidget {
  const CommitteesManagementScreen({super.key});

  @override
  State<CommitteesManagementScreen> createState() =>
      _CommitteesManagementScreenState();
}

class _CommitteesManagementScreenState
    extends State<CommitteesManagementScreen> {
  final AuthService _authService = AuthService();
  final Set<String> _expandedCommittees = {};

  bool get _canAddDelete =>
      _authService.isAdmin ||
      _authService.canAddDeleteOnPage(AppPages.committees);

  bool get _canAccessProfiles =>
      _authService.isAdmin || _authService.canAccessPage(AppPages.profiles);

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
          'إدارة اللجان',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: Provider.of<CommitteeProvider>(
          context,
          listen: false,
        ).getAllCommittees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
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

          final committees = snapshot.data ?? [];

          if (committees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد لجان بعد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابدأ بإضافة لجان جديدة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: committees.length,
            itemBuilder: (context, index) {
              final committee = committees[index];
              final isExpanded = _expandedCommittees.contains(committee.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Committee header - tap to expand/collapse, long press to delete
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedCommittees.remove(committee.id);
                          } else {
                            _expandedCommittees.add(committee.id);
                          }
                        });
                      },
                      onLongPress: () {
                        if (_canAddDelete) {
                          _showDeleteDialog(context, committee.id);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: committee.isActive
                                    ? AppTheme.primary.withOpacity(0.1)
                                    : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.groups,
                                color: committee.isActive
                                    ? AppTheme.primary
                                    : Colors.grey,
                                size: 20,
                              ),
                            ),
                            // Action buttons (left side)
                            if (_canAddDelete) ...[
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                onPressed: () {
                                  _showEditDialog(context, committee);
                                },
                              ),
                            ],
                            const Spacer(),
                            // Right side: name and expand arrow
                            // Committee name
                            Text(
                              committee.name,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(width: 12),

                            // Committee icon
                            const SizedBox(width: 8),
                            Switch(
                              value: committee.isActive,
                              onChanged: (value) async {
                                final provider = Provider.of<CommitteeProvider>(
                                  context,
                                  listen: false,
                                );
                                await provider.toggleCommitteeStatus(
                                  committee.id,
                                  value,
                                );
                              },
                              activeColor: AppTheme.primary,
                            ),
                            // Expand/Collapse icon
                            AnimatedRotation(
                              turns: isExpanded ? 0.25 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Volunteers list (expanded)
                    if (isExpanded)
                      _buildVolunteersList(committee.id, committee.name),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _canAddDelete
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'إضافة لجنة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildVolunteersList(String committeeId, String committeeName) {
    return FutureBuilder<List<VolunteerModel>>(
      future: Provider.of<VolunteerProvider>(
        context,
        listen: false,
      ).getVolunteersByCommittee(committeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              ),
            ),
          );
        }

        final volunteers = snapshot.data ?? [];

        if (volunteers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'لا يوجد متطوعون في هذه اللجنة',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: [
            const Divider(height: 1),
            // Export and count row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${volunteers.length} متطوع',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.file_download,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    tooltip: 'تصدير إلى Excel',
                    onPressed: () async {
                      try {
                        final committee = await Provider.of<CommitteeProvider>(
                          context,
                          listen: false,
                        ).getCommitteeById(committeeId);

                        if (committee != null) {
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
                      }
                    },
                  ),
                ],
              ),
            ),
            // Volunteer cards
            ...volunteers.map((volunteer) => _buildVolunteerCard(volunteer)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildVolunteerCard(VolunteerModel volunteer) {
    return InkWell(
      onTap: () {
        if (_canAccessProfiles) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileDetailsScreen(volunteer: volunteer),
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            const Spacer(),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    volunteer.name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (volunteer.educationalLevel != null)
                    Text(
                      volunteer.educationalLevel!,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.right,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'إضافة لجنة جديدة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
          textAlign: TextAlign.right,
        ),
        content: TextField(
          controller: nameController,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Cairo'),
          decoration: InputDecoration(
            hintText: 'اسم اللجنة',
            hintStyle: const TextStyle(fontFamily: 'Cairo'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى إدخال اسم اللجنة'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final provider = Provider.of<CommitteeProvider>(
                context,
                listen: false,
              );

              final id = await provider.createCommittee(
                name: nameController.text.trim(),
              );

              Navigator.pop(context);

              if (id != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إضافة اللجنة بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, dynamic committee) {
    final nameController = TextEditingController(text: committee.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'تعديل اللجنة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
          textAlign: TextAlign.right,
        ),
        content: TextField(
          controller: nameController,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Cairo'),
          decoration: InputDecoration(
            hintText: 'اسم اللجنة',
            hintStyle: const TextStyle(fontFamily: 'Cairo'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى إدخال اسم اللجنة'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final provider = Provider.of<CommitteeProvider>(
                context,
                listen: false,
              );

              final updatedCommittee = committee.copyWith(
                name: nameController.text.trim(),
              );

              final success = await provider.updateCommittee(
                committee.id,
                updatedCommittee,
              );

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تحديث اللجنة بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String committeeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
          textAlign: TextAlign.right,
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه اللجنة؟',
          style: TextStyle(fontFamily: 'Cairo'),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<CommitteeProvider>(
                context,
                listen: false,
              );

              final success = await provider.deleteCommittee(committeeId);

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف اللجنة بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
