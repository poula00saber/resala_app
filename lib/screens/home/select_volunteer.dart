// ============================================
// FILE: lib/screens/home/select_volunteer_screen.dart
// Copy this ENTIRE file
// ============================================

import 'package:flutter/material.dart';
import 'package:resala/screens/themes/app_theme.dart';

class SelectVolunteerScreen extends StatefulWidget {
  const SelectVolunteerScreen({super.key});

  @override
  State<SelectVolunteerScreen> createState() => _SelectVolunteerScreenState();
}

class _SelectVolunteerScreenState extends State<SelectVolunteerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredVolunteers = [];

  // Mock data - Replace with Firebase query
  final List<Map<String, dynamic>> _allVolunteers = [
    {
      'id': 'v1',
      'name': 'أحمد محمد علي',
      'phone': '01012345678',
      'email': 'ahmed@example.com',
      'address': 'القاهرة - مدينة نصر',
    },
    {
      'id': 'v2',
      'name': 'فاطمة علي حسن',
      'phone': '01098765432',
      'email': 'fatma@example.com',
      'address': 'الجيزة - الدقي',
    },
    {
      'id': 'v3',
      'name': 'محمود حسن إبراهيم',
      'phone': '01123456789',
      'email': 'mahmoud@example.com',
      'address': 'الإسكندرية - سموحة',
    },
    {
      'id': 'v4',
      'name': 'سارة خالد محمود',
      'phone': '01156789012',
      'email': 'sara@example.com',
      'address': 'القاهرة - المعادي',
    },
    {
      'id': 'v5',
      'name': 'عمر يوسف أحمد',
      'phone': '01234567890',
      'email': 'omar@example.com',
      'address': 'المنصورة',
    },
    {
      'id': 'v6',
      'name': 'نور الدين سعيد',
      'phone': '01145678901',
      'email': 'nour@example.com',
      'address': 'القاهرة - الزمالك',
    },
    {
      'id': 'v7',
      'name': 'مريم عبد الله',
      'phone': '01187654321',
      'email': 'mariam@example.com',
      'address': 'الجيزة - المهندسين',
    },
    {
      'id': 'v8',
      'name': 'يوسف كمال',
      'phone': '01223456789',
      'email': 'youssef@example.com',
      'address': 'القاهرة - مصر الجديدة',
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredVolunteers = _allVolunteers;
  }

  void _filterVolunteers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVolunteers = _allVolunteers;
      } else {
        _filteredVolunteers = _allVolunteers.where((volunteer) {
          return volunteer['name'].toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              volunteer['phone'].contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("اختيار متطوع"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: AppTheme.primary,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'البحث بالاسم أو رقم الهاتف',
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterVolunteers('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _filterVolunteers,
                ),
              ),
            ),

            if (_searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تم العثور على ${_filteredVolunteers.length} متطوع',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            Expanded(
              child: _filteredVolunteers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'لا توجد نتائج',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _filteredVolunteers.length,
                      itemBuilder: (context, index) {
                        final volunteer = _filteredVolunteers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context, volunteer);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.primary,
                                    radius: 28,
                                    child: Text(
                                      volunteer['name'][0],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          volunteer['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              volunteer['phone'],
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                volunteer['address'],
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context, volunteer);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('اختيار'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
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
