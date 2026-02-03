// ============================================
// FILE: lib/presentation/screens/home/profiles_screen.dart
// Matching your design from Image 2
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import 'profile_details_screen.dart';
import 'add_existing_volunteer_screen.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/app_user_model.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  String _searchQuery = '';
  bool _isDeleteMode = false;
  Set<String> _selectedForDelete = {};

  bool get _canDelete =>
      _authService.isAdmin ||
      _authService.canAddDeleteOnPage(AppPages.profiles);

  bool get _canAdd =>
      _authService.isAdmin ||
      _authService.canAddDeleteOnPage(AppPages.profiles);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: _isDeleteMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _isDeleteMode = false;
                    _selectedForDelete.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          _isDeleteMode ? 'حذف (${_selectedForDelete.length})' : 'البروفايلات',
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: _isDeleteMode && _selectedForDelete.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _confirmDeleteSelected,
                ),
              ]
            : _canAdd
            ? [
                IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AddExistingVolunteerScreen(),
                      ),
                    );
                  },
                ),
              ]
            : null,
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

          // Volunteers List
          Expanded(
            child: StreamBuilder(
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
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.red,
                      ),
                    ),
                  );
                }

                final volunteers = snapshot.data ?? [];

                if (volunteers.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد بروفايلات',
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
    final isSelected = _selectedForDelete.contains(volunteer.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.shade400 : AppTheme.primary,
        borderRadius: BorderRadius.circular(30),
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
          if (_isDeleteMode) {
            setState(() {
              if (isSelected) {
                _selectedForDelete.remove(volunteer.id);
              } else {
                _selectedForDelete.add(volunteer.id);
              }
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfileDetailsScreen(volunteer: volunteer),
              ),
            );
          }
        },
        onLongPress: _canDelete
            ? () {
                setState(() {
                  _isDeleteMode = true;
                  _selectedForDelete.add(volunteer.id);
                });
              }
            : null,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Left - Profile Image or Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  image:
                      volunteer.profileImage != null &&
                          volunteer.profileImage.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(volunteer.profileImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child:
                    volunteer.profileImage == null ||
                        volunteer.profileImage.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: AppTheme.primary,
                        size: 24,
                      )
                    : null,
              ),
              const Spacer(),

              // Right - Name
              Expanded(
                flex: 3,
                child: Text(
                  volunteer.name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 12),

              // Selection indicator or Edit icon
              if (_isDeleteMode)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.check : Icons.circle_outlined,
                    color: isSelected ? Colors.red : Colors.white,
                    size: 20,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
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

  void _confirmDeleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'حذف المتطوعين',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: Text(
          'هل أنت متأكد من حذف ${_selectedForDelete.length} متطوع؟',
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
    );
  }

  Future<void> _deleteSelected() async {
    final provider = Provider.of<VolunteerProvider>(context, listen: false);

    for (final id in _selectedForDelete) {
      await provider.deleteVolunteer(id);
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
