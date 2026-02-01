// ============================================
// FILE: lib/presentation/screens/users/user_management_screen.dart
// Screen for admin to manage users
// ============================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/app_user_model.dart';
import '../../../data/repositories/app_user_repository.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AppUserRepository _userRepository = AppUserRepository();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            'إدارة المستخدمين',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: AppTheme.primary,
            ),
          ),
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddUserDialog(context),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.person_add, color: Colors.white),
        ),
        body: StreamBuilder<List<AppUserModel>>(
          stream: _userRepository.getAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'خطأ في تحميل البيانات',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
                ),
              );
            }

            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return const Center(
                child: Text(
                  'لا يوجد مستخدمين',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserCard(user);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserCard(AppUserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: user.isAdmin ? AppTheme.primary : Colors.grey,
          child: Icon(
            user.isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          user.displayName ?? user.email,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              user.isAdmin ? 'مدير النظام' : 'مستخدم عادي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: user.isAdmin ? AppTheme.primary : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primary),
              onPressed: () => _showEditUserDialog(context, user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteUser(user),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddEditUserDialog(
        onSave: (email, password, displayName, isAdmin, permissions) async {
          await _createUser(email, password, displayName, isAdmin, permissions);
        },
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, AppUserModel user) {
    showDialog(
      context: context,
      builder: (context) => _AddEditUserDialog(
        user: user,
        onSave: (email, password, displayName, isAdmin, permissions) async {
          await _updateUser(user.id, isAdmin, permissions);
        },
      ),
    );
  }

  Future<void> _createUser(
    String email,
    String password,
    String? displayName,
    bool isAdmin,
    List<PagePermission> permissions,
  ) async {
    try {
      // Store current user credentials
      final currentUser = FirebaseAuth.instance.currentUser;

      // Create the new user
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final newUserId = userCredential.user!.uid;

      // Create user document
      final newUser = AppUserModel(
        id: newUserId,
        email: email,
        displayName: displayName,
        isAdmin: isAdmin,
        permissions: permissions,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('app_users')
          .doc(newUserId)
          .set(newUser.toFirestore());

      // Sign out the new user and sign back in as admin
      await FirebaseAuth.instance.signOut();

      // Note: In a production app, you would need to re-authenticate the admin
      // For now, the admin will need to sign in again

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إنشاء المستخدم بنجاح. يرجى تسجيل الدخول مرة أخرى.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateUser(
    String userId,
    bool isAdmin,
    List<PagePermission> permissions,
  ) async {
    try {
      await _userRepository.updateUserAdminStatus(userId, isAdmin);
      await _userRepository.updateUserPermissions(userId, permissions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث المستخدم بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDeleteUser(AppUserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'حذف المستخدم',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: Text(
          'هل أنت متأكد من حذف ${user.displayName ?? user.email}؟',
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
              await _userRepository.deleteUser(user.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف المستخدم'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'حذف',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEditUserDialog extends StatefulWidget {
  final AppUserModel? user;
  final Future<void> Function(
    String email,
    String password,
    String? displayName,
    bool isAdmin,
    List<PagePermission> permissions,
  )
  onSave;

  const _AddEditUserDialog({this.user, required this.onSave});

  @override
  State<_AddEditUserDialog> createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends State<_AddEditUserDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isAdmin = false;
  late List<PagePermission> _permissions;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _emailController.text = widget.user!.email;
      _displayNameController.text = widget.user!.displayName ?? '';
      _isAdmin = widget.user!.isAdmin;
      _permissions = List.from(widget.user!.permissions);
    } else {
      _permissions = AppPages.getAllPagesDefault();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? 'تعديل المستخدم' : 'إضافة مستخدم جديد',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email
                      TextField(
                        controller: _emailController,
                        enabled: !isEditing,
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          labelStyle: const TextStyle(fontFamily: 'Cairo'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Password (only for new users)
                      if (!isEditing) ...[
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            labelStyle: const TextStyle(fontFamily: 'Cairo'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Display Name
                      TextField(
                        controller: _displayNameController,
                        decoration: InputDecoration(
                          labelText: 'الاسم (اختياري)',
                          labelStyle: const TextStyle(fontFamily: 'Cairo'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Admin Switch
                      SwitchListTile(
                        title: const Text(
                          'مدير النظام',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                        subtitle: const Text(
                          'صلاحيات كاملة لجميع الصفحات',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                        ),
                        value: _isAdmin,
                        activeColor: AppTheme.primary,
                        onChanged: (value) {
                          setState(() => _isAdmin = value);
                        },
                      ),
                      const Divider(),

                      // Permissions
                      if (!_isAdmin) ...[
                        const Text(
                          'الصلاحيات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._permissions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final permission = entry.value;
                          return _buildPermissionTile(permission, index);
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEditing ? 'تحديث' : 'إضافة',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white,
                              ),
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

  Widget _buildPermissionTile(PagePermission permission, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  permission.pageName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Checkbox(
                value: permission.canAccess,
                activeColor: AppTheme.primary,
                onChanged: (value) {
                  setState(() {
                    _permissions[index] = permission.copyWith(
                      canAccess: value ?? false,
                      canAddDelete: value == false
                          ? false
                          : permission.canAddDelete,
                    );
                  });
                },
              ),
              const Text(
                'وصول',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
              ),
            ],
          ),
          if (permission.canAccess)
            Row(
              children: [
                const Spacer(),
                Checkbox(
                  value: permission.canAddDelete,
                  activeColor: AppTheme.primary,
                  onChanged: (value) {
                    setState(() {
                      _permissions[index] = permission.copyWith(
                        canAddDelete: value ?? false,
                      );
                    });
                  },
                ),
                const Text(
                  'إضافة/حذف',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال البريد الإلكتروني'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.user == null && password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.onSave(
        email,
        password,
        displayName.isNotEmpty ? displayName : null,
        _isAdmin,
        _permissions,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
