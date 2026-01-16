// ============================================
// FILE: lib/presentation/screens/contacts/contacts_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedVolunteers = {};
  bool _selectionMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _selectionMode ? Icons.close : Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            if (_selectionMode) {
              setState(() {
                _selectionMode = false;
                _selectedVolunteers.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: _selectionMode
            ? Text(
                '${_selectedVolunteers.length} مختار',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              )
            : const Text(
                'جهات الاتصال',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
        centerTitle: true,
        actions: [
          if (_selectionMode && _selectedVolunteers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.message, color: AppTheme.primary),
              onPressed: () => _sendBulkMessage(context),
            ),
        ],
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
                hintText: 'بحث باسم المتطوع أو رقم الهاتف',
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
                      'لا توجد جهات اتصال',
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
                    final isSelected = _selectedVolunteers.contains(
                      volunteer.id,
                    );
                    return _buildContactCard(volunteer, isSelected);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(dynamic volunteer, bool isSelected) {
    final hasValidPhone =
        volunteer.phone != null && volunteer.phone!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (_selectionMode) {
            _toggleSelection(volunteer.id);
          } else {
            _showContactOptions(volunteer);
          }
        },
        onLongPress: () {
          setState(() {
            _selectionMode = true;
            _toggleSelection(volunteer.id);
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Selection checkbox (visible only in selection mode)
              if (_selectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(volunteer.id),
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Contact info
              Expanded(
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
                    if (hasValidPhone)
                      Text(
                        _formatPhoneNumber(volunteer.phone!),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
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
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Contact icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasValidPhone
                      ? AppTheme.primary.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasValidPhone ? Icons.phone : Icons.phone_disabled,
                  color: hasValidPhone ? AppTheme.primary : Colors.grey,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSelection(String volunteerId) {
    setState(() {
      if (_selectedVolunteers.contains(volunteerId)) {
        _selectedVolunteers.remove(volunteerId);
      } else {
        _selectedVolunteers.add(volunteerId);
      }

      if (_selectedVolunteers.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _showContactOptions(dynamic volunteer) async {
    final hasValidPhone =
        volunteer.phone != null && volunteer.phone!.isNotEmpty;

    if (!hasValidPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يوجد رقم هاتف لهذا المتطوع',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.call, color: AppTheme.primary),
              title: const Text(
                'الاتصال',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                _makePhoneCall(volunteer.phone!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.green),
              title: const Text(
                'رسالة نصية',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                _sendSMS(volunteer.phone!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.wechat_sharp, color: Colors.green),
              title: const Text(
                'واتساب',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                _openWhatsApp(volunteer.phone!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text(
                'نسخ الرقم',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                _copyPhoneNumber(volunteer.phone!);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يمكن فتح تطبيق الهاتف',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final url = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يمكن فتح تطبيق الرسائل',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // Clean phone number (remove any non-digit characters)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Format for WhatsApp
    String whatsappUrl;
    if (cleanNumber.startsWith('+')) {
      whatsappUrl = 'https://wa.me/$cleanNumber';
    } else if (cleanNumber.startsWith('0')) {
      whatsappUrl = 'https://wa.me/2${cleanNumber.substring(1)}';
    } else {
      whatsappUrl = 'https://wa.me/2$cleanNumber';
    }

    final url = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يمكن فتح تطبيق واتساب',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyPhoneNumber(String phoneNumber) async {
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم نسخ الرقم',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _sendBulkMessage(BuildContext context) async {
    if (_selectedVolunteers.isEmpty) return;

    // Get selected volunteers' phone numbers
    final allVolunteers = await Provider.of<VolunteerProvider>(
      context,
      listen: false,
    ).getVolunteers().first;

    final selectedVolunteers = allVolunteers
        .where((v) => _selectedVolunteers.contains(v.id))
        .toList();

    final validPhones = selectedVolunteers
        .where((v) => v.phone != null && v.phone!.isNotEmpty)
        .map((v) => v.phone!)
        .toList();

    if (validPhones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا توجد أرقام هاتف صالحة للمتطوعين المختارين',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _BulkMessageDialog(
        phoneNumbers: validPhones,
        volunteerNames: selectedVolunteers.map((v) => v.name).toList(),
        onComplete: () {
          setState(() {
            _selectionMode = false;
            _selectedVolunteers.clear();
          });
        },
      ),
    );
  }

  String _formatPhoneNumber(String phone) {
    // Format Egyptian numbers
    if (phone.startsWith('+20')) {
      return phone.replaceFirst('+20', '0');
    } else if (phone.startsWith('20')) {
      return '0${phone.substring(2)}';
    }
    return phone;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _BulkMessageDialog extends StatefulWidget {
  final List<String> phoneNumbers;
  final List<String> volunteerNames;
  final VoidCallback onComplete;

  const _BulkMessageDialog({
    required this.phoneNumbers,
    required this.volunteerNames,
    required this.onComplete,
  });

  @override
  State<_BulkMessageDialog> createState() => __BulkMessageDialogState();
}

class __BulkMessageDialogState extends State<_BulkMessageDialog> {
  String? _selectedMethod;
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'إرسال رسالة جماعية',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.phoneNumbers.length} متطوع',
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            'اختر طريقة الإرسال:',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
          ),
          RadioListTile<String>(
            title: const Text('واتساب', style: TextStyle(fontFamily: 'Cairo')),
            value: 'whatsapp',
            groupValue: _selectedMethod,
            onChanged: (value) {
              setState(() {
                _selectedMethod = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text(
              'رسالة نصية',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            value: 'sms',
            groupValue: _selectedMethod,
            onChanged: (value) {
              setState(() {
                _selectedMethod = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onComplete();
          },
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
        ),
        ElevatedButton(
          onPressed: _selectedMethod != null && !_isSending
              ? () => _sendBulkMessages(context)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('إرسال', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    );
  }

  Future<void> _sendBulkMessages(BuildContext context) async {
    setState(() => _isSending = true);

    try {
      int successCount = 0;

      for (final phone in widget.phoneNumbers) {
        try {
          if (_selectedMethod == 'whatsapp') {
            await _openWhatsAppForBulk(phone);
          } else if (_selectedMethod == 'sms') {
            await _sendSMSForBulk(phone);
          }
          successCount++;
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          // Continue with next number
        }
      }

      setState(() => _isSending = false);

      Navigator.pop(context);
      widget.onComplete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال الرسالة إلى $successCount متطوع',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'حدث خطأ أثناء الإرسال',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openWhatsAppForBulk(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    String whatsappUrl;

    if (cleanNumber.startsWith('+')) {
      whatsappUrl = 'https://wa.me/$cleanNumber';
    } else if (cleanNumber.startsWith('0')) {
      whatsappUrl = 'https://wa.me/2${cleanNumber.substring(1)}';
    } else {
      whatsappUrl = 'https://wa.me/2$cleanNumber';
    }

    final url = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _sendSMSForBulk(String phoneNumber) async {
    final url = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
