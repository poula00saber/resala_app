// ============================================
// FILE: lib/presentation/screens/promotions/promotions_screen.dart
// UPDATED: Supports new hierarchy
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/core/constants/firebase_constants.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/whale_loading.dart';
import 'volunteer_promotion_screen.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
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
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'الترقيات',
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
            child: StreamBuilder(
              stream: Provider.of<VolunteerProvider>(
                context,
                listen: false,
              ).searchVolunteers(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: WhaleLoading());
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
                      'لا يوجد متطوعين',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppTheme.secondary,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                // Sort volunteers by educational level
                final sortedVolunteers = _sortVolunteersByLevel(volunteers);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedVolunteers.length,
                  itemBuilder: (context, index) {
                    final volunteer = sortedVolunteers[index];
                    return _buildVolunteerCard(volunteer);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerCard(dynamic volunteer) {
    final String currentLevel = volunteer.educationalLevel ?? 'جدد';
    final nextLevel = FirebaseConstants.getNextLevel(
      currentLevel,
      age: volunteer.age,
    );
    final bool canBePromoted = nextLevel != null;

    // Determine color based on level
    Color levelColor;
    switch (currentLevel) {
      case 'مسئول':
        levelColor = const Color(0xFF4CAF50); // Green
        break;
      case 'مشروع مسئول':
        levelColor = const Color(0xFF2196F3); // Blue
        break;
      case 'تدريب':
        levelColor = const Color(0xFFFF9800); // Orange
        break;
      case 'شبل مميز':
        levelColor = const Color(0xFF9C27B0); // Purple
        break;
      case 'جدد':
        levelColor = const Color(0xFFF44336); // Red
        break;
      case 'شبل':
        levelColor = const Color(0xFFFFC107); // Amber
        break;
      default:
        levelColor = AppTheme.primary;
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
                  VolunteerPromotionScreen(volunteer: volunteer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Age indicator for شبل مميز
              if (currentLevel == 'شبل مميز')
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: volunteer.age >= 17
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${volunteer.age ?? 0}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: volunteer.age >= 17
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'سنة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppTheme.secondary,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),

              const SizedBox(width: 12),

              // Left - Level Indicator with level badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      currentLevel,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppTheme.cardBackground,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Level number indicator
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _getLevelNumber(currentLevel).toString(),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: levelColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Center - Volunteer Name
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Show next level hint
                    if (canBePromoted)
                      Text(
                        'التالي: $nextLevel',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.green,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right - Profile Image
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  image:
                      volunteer.profileImage != null &&
                          volunteer.profileImage!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(volunteer.profileImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child:
                    volunteer.profileImage == null ||
                        volunteer.profileImage!.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: AppTheme.primary,
                        size: 24,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get level number (for visual indicator)
  int _getLevelNumber(String level) {
    switch (level) {
      case 'مسئول':
        return 6;
      case 'مشروع مسئول':
        return 5;
      case 'تدريب':
      case 'شبل مميز':
        return 4;
      case 'جدد':
        return 3;
      case 'شبل':
        return 2;
      default:
        return 0;
    }
  }

  // Sort volunteers by educational level (higher first)
  List<dynamic> _sortVolunteersByLevel(List<dynamic> volunteers) {
    final Map<String, int> levelsOrder =
        FirebaseConstants.educationalLevelsOrder;

    final sortedVolunteers = List<dynamic>.from(volunteers);

    sortedVolunteers.sort((a, b) {
      final aLevel = a.educationalLevel ?? '';
      final bLevel = b.educationalLevel ?? '';

      final aOrder = levelsOrder[aLevel] ?? 0;
      final bOrder = levelsOrder[bLevel] ?? 0;

      if (bOrder != aOrder) {
        return bOrder.compareTo(aOrder);
      } else {
        return a.name.compareTo(b.name);
      }
    });

    return sortedVolunteers;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
