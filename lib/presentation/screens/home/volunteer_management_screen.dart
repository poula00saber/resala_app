import 'package:flutter/material.dart';
import 'package:resala/presentation/screens/home/add_volunteer_screen.dart';
import 'package:resala/presentation/themes/app_theme.dart';
import 'package:resala/presentation/widgets/app_ui_widgets.dart';

class VolunteerManagementScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const VolunteerManagementScreen({super.key, required this.event});

  @override
  State<VolunteerManagementScreen> createState() =>
      _VolunteerManagementScreenState();
}

class _VolunteerManagementScreenState extends State<VolunteerManagementScreen> {
  final List<Map<String, dynamic>> _volunteers = [];
  final List<Map<String, dynamic>> _availableVolunteers = [
    {
      'id': '1',
      'name': 'محمد صحيح محمد',
      'phone': '0123456789',
      'year': '2024',
    },
    {
      'id': '2',
      'name': 'بسملة محمد علي',
      'phone': '0123456788',
      'year': '2024',
    },
    {
      'id': '3',
      'name': 'آية أشرف هريدي',
      'phone': '0123456787',
      'year': '2024',
    },
    {
      'id': '4',
      'name': 'مصطفى محمد صاحي',
      'phone': '0123456786',
      'year': '2024',
    },
    {
      'id': '5',
      'name': 'أحمد عصام عبداهلل',
      'phone': '0123456785',
      'year': '2024',
    },
    {
      'id': '6',
      'name': 'براء عبدالكريم محمود',
      'phone': '0123456784',
      'year': '2024',
    },
  ];

  void _navigateToAddVolunteer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVolunteerScreen(
          onVolunteerAdded: (newVolunteer) {
            setState(() {
              _volunteers.add(newVolunteer);
              _availableVolunteers.add(newVolunteer);
            });
          },
        ),
      ),
    );
  }

  void _addVolunteer(Map<String, dynamic> volunteer) {
    setState(() {
      if (!_volunteers.any((v) => v['id'] == volunteer['id'])) {
        _volunteers.add(volunteer);
      }
    });
  }

  void _removeVolunteer(Map<String, dynamic> volunteer) {
    setState(() {
      _volunteers.removeWhere((v) => v['id'] == volunteer['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("متطوعين ${widget.event['title']}"),
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.textLight,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'المتطوعين المضافين'),
              Tab(text: 'قاعدة البيانات'),
            ],
          ),
        ),
        body: Container(
          color: AppTheme.primary,
          child: TabBarView(
            children: [
              // Added Volunteers Tab
              _buildAddedVolunteersTab(),
              // Database Volunteers Tab
              _buildDatabaseVolunteersTab(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToAddVolunteer,
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.textLight,
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }

  Widget _buildAddedVolunteersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إجمالي المتطوعين:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_volunteers.length} متطوع',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _volunteers.isEmpty
                ? const Center(
                    child: Text(
                      'لا يوجد متطوعين مضافين',
                      style: TextStyle(
                        color: AppTheme.cardBackground,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _volunteers.length,
                    itemBuilder: (context, index) {
                      final volunteer = _volunteers[index];
                      return AppCardListTile(
                        margin: const EdgeInsets.only(bottom: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            volunteer['name'][0],
                            style: const TextStyle(color: AppTheme.textLight),
                          ),
                        ),
                        title: Text(volunteer['name']),
                        subtitle: Text(volunteer['phone']),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeVolunteer(volunteer),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseVolunteersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'اختر متطوعين من قاعدة البيانات لإضافتهم للحدث',
                      style: TextStyle(color: AppTheme.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _availableVolunteers.length,
              itemBuilder: (context, index) {
                final volunteer = _availableVolunteers[index];
                final isAdded = _volunteers.any(
                  (v) => v['id'] == volunteer['id'],
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        volunteer['name'][0],
                        style: const TextStyle(color: AppTheme.textLight),
                      ),
                    ),
                    title: Text(volunteer['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(volunteer['phone']),
                        Text('السنة: ${volunteer['year']}'),
                      ],
                    ),
                    trailing: isAdded
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: AppTheme.primary,
                            ),
                            onPressed: () => _addVolunteer(volunteer),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
