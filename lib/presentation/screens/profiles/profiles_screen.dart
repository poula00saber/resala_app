// ============================================
// FILE: lib/presentation/screens/home/profiles_screen.dart
// Matching your design from Image 2
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import 'profile_details_screen.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
          'البروفايلات',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary,
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileDetailsScreen(
                volunteer: volunteer,
              ), // inside constructor:
            ),
          );
        },
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Left - Edit Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
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

              // Profile Circle
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
