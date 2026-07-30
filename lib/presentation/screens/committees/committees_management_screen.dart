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
import '../../widgets/whale_loading.dart';
import '../profiles/profile_details_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/excel_export_helper.dart';
import '../../../data/models/app_user_model.dart';
import '../../../data/models/volunteer_model.dart';
import '../../../data/models/committee_model.dart';

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
  late Stream<List<CommitteeModel>> _committeesStream;

  @override
  void initState() {
    super.initState();
    _committeesStream = Provider.of<CommitteeProvider>(
      context,
      listen: false,
    ).getAllCommittees();
  }

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
          icon: const Icon(Icons.arrow_forward, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'إدارة اللجان',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: AppTheme.primary),
            tooltip: 'تصدير كل اللجان إلى Excel',
            onPressed: () async {
              try {
                final committees = await Provider.of<CommitteeProvider>(
                  context,
                  listen: false,
                ).getAllCommittees().first;
                await ExcelExportHelper.exportAllCommitteesToExcel(
                  committees: committees,
                  getVolunteersByCommittee: (committeeId) =>
                      Provider.of<VolunteerProvider>(
                        context,
                        listen: false,
                      ).getVolunteersByCommittee(committeeId),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم تصدير كل اللجان بنجاح',
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
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _committeesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: WhaleLoading());
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
                      color: AppTheme.secondary,
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
                        child: Column(
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
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
                                      size: 18,
                                    ),
                                  ),
                                  if (_canAddDelete) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: EdgeInsets.zero,
                                      tooltip: 'تعيين ليدر ونائب',
                                      onPressed: () {
                                        _showLeaderDialog(context, committee);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: AppTheme.primary,
                                        size: 20,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        _showEditDialog(context, committee);
                                      },
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Text(
                                    committee.name,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: committee.isActive,
                                    onChanged: (value) async {
                                      final provider =
                                          Provider.of<CommitteeProvider>(
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
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.25 : 0,
                                    duration: const Duration(milliseconds: 200),
                                    child: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: AppTheme.secondary,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (committee.leaderName != null ||
                                committee.coLeaderName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      if (committee.leaderName != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                size: 14,
                                                color: Colors.amber,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'الليدر: ${committee.leaderName}',
                                                style: const TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 11,
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (committee.coLeaderName != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.person,
                                                size: 14,
                                                color: Colors.blue,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'نائب: ${committee.coLeaderName}',
                                                style: const TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 11,
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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
              icon: const Icon(Icons.add, color: AppTheme.textLight),
              label: const Text(
                'إضافة لجنة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppTheme.cardBackground,
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
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(child: WhaleLoading(size: 24)),
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
                color: AppTheme.secondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${volunteers.length} متطوع',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppTheme.secondary,
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
                color: AppTheme.cardBackground,
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
                      color: AppTheme.cardBackground,
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
              style: TextStyle(fontFamily: 'Cairo', color: AppTheme.secondary),
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
              foregroundColor: AppTheme.textLight,
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
              style: TextStyle(fontFamily: 'Cairo', color: AppTheme.secondary),
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
              foregroundColor: AppTheme.textLight,
            ),
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _showLeaderDialog(BuildContext context, dynamic committee) {
    // Normalize empty strings to null so the dropdown "بدون ليدر" works
    String? selectedLeaderId =
        (committee.leaderId != null && committee.leaderId!.isNotEmpty)
        ? committee.leaderId
        : null;
    String? selectedCoLeaderId =
        (committee.coLeaderId != null && committee.coLeaderId!.isNotEmpty)
        ? committee.coLeaderId
        : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'تعيين ليدر ونائب اللجنة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: FutureBuilder<List<VolunteerModel>>(
                  future: Provider.of<VolunteerProvider>(
                    context,
                    listen: false,
                  ).getVolunteersByCommittee(committee.id),
                  builder: (context, snapshot) {
                    final volunteers = snapshot.data ?? [];

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'الليدر',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          value: selectedLeaderId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'اختر الليدر',
                            hintStyle: const TextStyle(fontFamily: 'Cairo'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: (() {
                            final items = <DropdownMenuItem<String?>>[];
                            items.add(
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'بدون ليدر',
                                  style: TextStyle(fontFamily: 'Cairo'),
                                ),
                              ),
                            );
                            items.addAll(
                              volunteers.map(
                                (v) => DropdownMenuItem<String?>(
                                  value: v.id,
                                  child: Text(
                                    v.name,
                                    style: const TextStyle(fontFamily: 'Cairo'),
                                  ),
                                ),
                              ),
                            );

                            if (selectedLeaderId != null &&
                                !volunteers.any(
                                  (v) => v.id == selectedLeaderId,
                                )) {
                              items.add(
                                DropdownMenuItem<String?>(
                                  value: selectedLeaderId,
                                  child: Text(
                                    committee.leaderName ?? 'Selected',
                                    style: const TextStyle(fontFamily: 'Cairo'),
                                  ),
                                ),
                              );
                            }

                            return items;
                          })(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedLeaderId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'نائب الليدر',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          value: selectedCoLeaderId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'اختر النائب',
                            hintStyle: const TextStyle(fontFamily: 'Cairo'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: (() {
                            final items = <DropdownMenuItem<String?>>[];
                            items.add(
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'بدون نائب',
                                  style: TextStyle(fontFamily: 'Cairo'),
                                ),
                              ),
                            );
                            items.addAll(
                              volunteers.map(
                                (v) => DropdownMenuItem<String?>(
                                  value: v.id,
                                  child: Text(
                                    v.name,
                                    style: const TextStyle(fontFamily: 'Cairo'),
                                  ),
                                ),
                              ),
                            );

                            if (selectedCoLeaderId != null &&
                                !volunteers.any(
                                  (v) => v.id == selectedCoLeaderId,
                                )) {
                              items.add(
                                DropdownMenuItem<String?>(
                                  value: selectedCoLeaderId,
                                  child: Text(
                                    committee.coLeaderName ?? 'Selected',
                                    style: const TextStyle(fontFamily: 'Cairo'),
                                  ),
                                ),
                              );
                            }

                            return items;
                          })(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCoLeaderId = value;
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final provider = Provider.of<CommitteeProvider>(
                      context,
                      listen: false,
                    );
                    final volunteers = await Provider.of<VolunteerProvider>(
                      context,
                      listen: false,
                    ).getVolunteersByCommittee(committee.id);

                    String? leaderName;
                    String? coLeaderName;
                    // Only look up names if IDs are non-null and non-empty
                    if (selectedLeaderId != null &&
                        selectedLeaderId!.isNotEmpty) {
                      try {
                        leaderName = volunteers
                            .firstWhere((v) => v.id == selectedLeaderId)
                            .name;
                      } catch (_) {}
                    }
                    if (selectedCoLeaderId != null &&
                        selectedCoLeaderId!.isNotEmpty) {
                      try {
                        coLeaderName = volunteers
                            .firstWhere((v) => v.id == selectedCoLeaderId)
                            .name;
                      } catch (_) {}
                    }

                    // Convert empty-string IDs to null before saving to Firestore
                    final normalizedLeaderId =
                        (selectedLeaderId == null || selectedLeaderId!.isEmpty)
                        ? null
                        : selectedLeaderId;
                    final normalizedCoLeaderId =
                        (selectedCoLeaderId == null ||
                            selectedCoLeaderId!.isEmpty)
                        ? null
                        : selectedCoLeaderId;

                    final updatedCommittee = committee.copyWith(
                      leaderId: normalizedLeaderId,
                      leaderName: leaderName,
                      coLeaderId: normalizedCoLeaderId,
                      coLeaderName: coLeaderName,
                    );

                    await provider.updateCommittee(
                      committee.id,
                      updatedCommittee,
                    );
                    Navigator.pop(dialogContext);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تعيين الليدر والنائب بنجاح'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textLight,
                  ),
                  child: const Text(
                    'حفظ',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            );
          },
        );
      },
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
              foregroundColor: AppTheme.textLight,
            ),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
