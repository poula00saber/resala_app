// ============================================
// FILE: lib/presentation/screens/settings/committees_management_screen.dart
// UPDATED: Added navigation to committee volunteers screen
// UPDATED: Added permission checks for add/edit/delete
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/committee_provider.dart';
import '../../themes/app_theme.dart';
import 'committee_volunteers_screen.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/app_user_model.dart';

class CommitteesManagementScreen extends StatefulWidget {
  const CommitteesManagementScreen({super.key});

  @override
  State<CommitteesManagementScreen> createState() =>
      _CommitteesManagementScreenState();
}

class _CommitteesManagementScreenState
    extends State<CommitteesManagementScreen> {
  final AuthService _authService = AuthService();

  bool get _canAddDelete =>
      _authService.isAdmin ||
      _authService.canAddDeleteOnPage(AppPages.committees);

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
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    // Navigate to committee volunteers screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommitteeVolunteersScreen(
                          committeeId: committee.id,
                          committeeName: committee.name,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
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
                      ),
                    ),
                    title: Text(
                      committee.name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    subtitle: committee.description != null
                        ? Text(
                            committee.description!,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Toggle Active Status (only if can add/delete)
                        if (_canAddDelete)
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
                        // Edit Button (only if can add/delete)
                        if (_canAddDelete)
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppTheme.primary,
                            ),
                            onPressed: () {
                              _showEditDialog(context, committee);
                            },
                          ),
                        // Delete Button (only if can add/delete)
                        if (_canAddDelete)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteDialog(context, committee.id);
                            },
                          ),
                        // Show arrow icon for navigation when no permissions
                        if (!_canAddDelete)
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
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

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'إضافة لجنة جديدة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'اسم اللجنة',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'الوصف (اختياري)',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
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
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
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
    final descriptionController = TextEditingController(
      text: committee.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'تعديل اللجنة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'اسم اللجنة',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'الوصف (اختياري)',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
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
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
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
