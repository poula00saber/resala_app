// ============================================
// FILE: lib/presentation/screens/promotions/promotions_screen.dart
// UPDATED: Sorts volunteers by higher degrees first
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resala/core/constants/firebase_constants.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';
import 'volunteer_promotion_screen.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Define educational levels hierarchy (highest to lowest)
  final Map<String, int> _educationalLevelsOrder =
      FirebaseConstants.educationalLevelsOrder;

  // Sort volunteers by educational level (higher first)
  List<dynamic> _sortVolunteersByLevel(List<dynamic> volunteers) {
    // Create a copy to avoid modifying the original list
    final sortedVolunteers = List<dynamic>.from(volunteers);

    sortedVolunteers.sort((a, b) {
      final aLevel = a.educationalLevel ?? '';
      final bLevel = b.educationalLevel ?? '';

      // Get level order (higher number = higher level)
      final aOrder = _educationalLevelsOrder[aLevel] ?? 0;
      final bOrder = _educationalLevelsOrder[bLevel] ?? 0;

      // Sort by level (higher first), then by name
      if (bOrder != aOrder) {
        return bOrder.compareTo(aOrder); // Descending order
      } else {
        // If same level, sort alphabetically by name
        return a.name.compareTo(b.name);
      }
    });

    return sortedVolunteers;
  }

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
          'الترقيات',
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
                      'لا يوجد متطوعين',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.grey,
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
    final bool canBePromoted = currentLevel != 'مسئول';

    // Determine color based on level
    // In _buildVolunteerCard method
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
      case 'داخل متابعة':
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
                  VolunteerPromotionScreen(volunteer: volunteer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
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
                        color: Colors.white,
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
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right - Promotion Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: canBePromoted
                      ? AppTheme.primary.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  canBePromoted ? Icons.arrow_upward : Icons.check_circle,
                  color: canBePromoted ? AppTheme.primary : Colors.grey,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get level number (for visual indicator)
  // Update the helper method in PromotionsScreen
  int _getLevelNumber(String level) {
    switch (level) {
      case 'مسئول':
        return 6;
      case 'مشروع مسئول':
        return 5;
      case 'تدريب':
        return 4;
      case 'داخل متابعة':
        return 3;
      case 'جدد':
      case 'شبل': // BOTH SAME LEVEL
        return 2;
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
