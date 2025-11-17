// ============================================
// FILE: lib/screens/home/volunteer_details_sheet.dart
// Copy this ENTIRE file
// ============================================

import 'package:flutter/material.dart';
import 'package:resala/screens/themes/app_theme.dart';

class VolunteerDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> volunteer;
  final bool initialHasTshirt;

  const VolunteerDetailsSheet({
    super.key,
    required this.volunteer,
    this.initialHasTshirt = false,
  });

  @override
  State<VolunteerDetailsSheet> createState() => _VolunteerDetailsSheetState();
}

class _VolunteerDetailsSheetState extends State<VolunteerDetailsSheet> {
  bool _hasTshirt = false;

  @override
  void initState() {
    super.initState();
    _hasTshirt = widget.initialHasTshirt;
  }

  void _confirm() {
    final updatedVolunteer = Map<String, dynamic>.from(widget.volunteer);
    updatedVolunteer['hasTshirt'] = _hasTshirt;
    Navigator.pop(context, updatedVolunteer);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'تفاصيل المتطوع',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 0,
              color: Colors.grey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          radius: 30,
                          child: Text(
                            widget.volunteer['name'][0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.volunteer['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'متطوع',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      icon: Icons.phone,
                      label: 'رقم الهاتف',
                      value: widget.volunteer['phone'],
                      iconColor: Colors.blue,
                    ),
                    const SizedBox(height: 12),

                    if (widget.volunteer['email'] != null)
                      _buildInfoRow(
                        icon: Icons.email,
                        label: 'البريد الإلكتروني',
                        value: widget.volunteer['email'],
                        iconColor: Colors.orange,
                      ),

                    if (widget.volunteer['address'] != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.location_on,
                        label: 'العنوان',
                        value: widget.volunteer['address'],
                        iconColor: Colors.red,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'معلومات إضافية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 0,
              color: Colors.grey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: CheckboxListTile(
                value: _hasTshirt,
                onChanged: (bool? value) {
                  setState(() {
                    _hasTshirt = value ?? false;
                  });
                },
                title: const Text(
                  'لديه تيشيرت',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _hasTshirt
                      ? 'المتطوع يمتلك تيشيرت الفعالية'
                      : 'المتطوع لا يمتلك تيشيرت',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _hasTshirt ? Colors.green[50] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.checkroom,
                    color: _hasTshirt ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
                activeColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'تأكيد الإضافة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
