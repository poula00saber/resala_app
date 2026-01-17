// ============================================
// FILE: lib/presentation/screens/contacts/contacts_screen.dart
// UPDATED VERSION: With long press options and WhatsApp working for all volunteers
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: _selectedVolunteers.isNotEmpty
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
            if (_selectedVolunteers.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.message, color: AppTheme.primary),
                onPressed: () => _openMessageComposer(context),
              ),
          ],
        ),
        body: Column(
          children: [
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
          _toggleSelection(volunteer.id);
        },
        onLongPress: () {
          _showContactOptions(volunteer);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volunteer.name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.start,
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
                        textAlign: TextAlign.start,
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
                        textAlign: TextAlign.start,
                      ),
                  ],
                ),
              ),
              // Checkbox always visible on LEFT
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(volunteer.id),
                activeColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
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
        child: Directionality(
          textDirection: TextDirection.rtl,
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
      ),
    );
  }

  void _openMessageComposer(BuildContext context) async {
    if (_selectedVolunteers.isEmpty) return;

    final allVolunteers = await Provider.of<VolunteerProvider>(
      context,
      listen: false,
    ).getVolunteers().first;

    final selectedVolunteers = allVolunteers
        .where((v) => _selectedVolunteers.contains(v.id))
        .toList();

    final validVolunteers = selectedVolunteers
        .where((v) => v.phone != null && v.phone!.isNotEmpty)
        .toList();

    if (validVolunteers.isEmpty) {
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageComposerScreen(
          volunteers: validVolunteers,
          onComplete: () {
            setState(() {
              _selectedVolunteers.clear();
            });
          },
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final message = 'مرحباً';
    final encodedMessage = Uri.encodeComponent(message);

    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    String whatsappUrl;

    if (cleanNumber.startsWith('+')) {
      whatsappUrl = 'https://wa.me/$cleanNumber?text=$encodedMessage';
    } else if (cleanNumber.startsWith('0')) {
      whatsappUrl =
          'https://wa.me/2${cleanNumber.substring(1)}?text=$encodedMessage';
    } else {
      whatsappUrl = 'https://wa.me/2$cleanNumber?text=$encodedMessage';
    }

    final url = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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

  String _formatPhoneNumber(String phone) {
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

// ===================================================
// MESSAGE COMPOSER SCREEN - WORKING WHATSAPP
// ===================================================

class MessageComposerScreen extends StatefulWidget {
  final List<dynamic> volunteers;
  final VoidCallback onComplete;

  const MessageComposerScreen({
    super.key,
    required this.volunteers,
    required this.onComplete,
  });

  @override
  State<MessageComposerScreen> createState() => _MessageComposerScreenState();
}

class _MessageComposerScreenState extends State<MessageComposerScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedMethod;
  int _currentIndex = 0;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController.text = 'مرحباً @name 👋\n\nنود إعلامك...';
  }

  String _getFirstName(String fullName) {
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts.first : fullName;
  }

  String _personalizeMessage(String template, String volunteerName) {
    final firstName = _getFirstName(volunteerName);
    return template.replaceAll('@name', firstName);
  }

  String _normalizePhoneForWhatsApp(String phone) {
    final cleanNumber = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanNumber.startsWith('+')) {
      return cleanNumber.substring(1);
    } else if (cleanNumber.startsWith('0')) {
      return '20${cleanNumber.substring(1)}';
    }
    return cleanNumber;
  }

  Future<void> _sendMessages() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى كتابة الرسالة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى اختيار طريقة الإرسال',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMethod == 'whatsapp') {
      _sendWhatsAppMessagesWithConfirmation();
    } else {
      _sendSMSMessages();
    }
  }

  Future<void> _sendSMSMessages() async {
    setState(() {
      _isSending = true;
      _currentIndex = 0;
    });

    try {
      for (int i = 0; i < widget.volunteers.length; i++) {
        final volunteer = widget.volunteers[i];

        setState(() {
          _currentIndex = i + 1;
        });

        final personalizedMessage = _personalizeMessage(
          _messageController.text,
          volunteer.name,
        );

        final encodedMessage = Uri.encodeComponent(personalizedMessage);
        final url = Uri.parse('sms:${volunteer.phone}?body=$encodedMessage');

        try {
          await launchUrl(url);
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('Failed to send SMS to ${volunteer.name}: $e');
        }
      }

      setState(() => _isSending = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال الرسالة إلى ${widget.volunteers.length} متطوع',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.green,
        ),
      );

      widget.onComplete();
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء الإرسال',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendWhatsAppMessagesWithConfirmation() async {
    setState(() {
      _isSending = true;
      _currentIndex = 0;
    });

    for (int i = 0; i < widget.volunteers.length; i++) {
      final volunteer = widget.volunteers[i];

      setState(() {
        _currentIndex = i + 1;
      });

      final personalizedMessage = _personalizeMessage(
        _messageController.text,
        volunteer.name,
      );

      // Open WhatsApp
      try {
        final encodedMessage = Uri.encodeComponent(personalizedMessage);
        final cleanNumber = _normalizePhoneForWhatsApp(volunteer.phone!);
        final url = Uri.parse(
          'https://wa.me/$cleanNumber?text=$encodedMessage',
        );

        // FIXED: Don't check canLaunchUrl, just try to launch
        try {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } catch (e) {
          print('Error launching WhatsApp: $e');
          // Continue anyway - the dialog will let user skip
        }

        // Small delay to let WhatsApp open
        await Future.delayed(const Duration(milliseconds: 800));
      } catch (e) {
        print('Failed to prepare WhatsApp for ${volunteer.name}: $e');
      }

      // Show confirmation dialog (only if not the last one)
      if (i < widget.volunteers.length - 1) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'هل أرسلت الرسالة؟',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بعد إرسال الرسالة إلى ${_getFirstName(volunteer.name)} في واتساب، اضغط "التالي"',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تم الإرسال:',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${i + 1} من ${widget.volunteers.length}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'المتبقي: ${widget.volunteers.length - i - 1} متطوع',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'التالي →',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (shouldContinue != true) {
          // User cancelled
          setState(() => _isSending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم إرسال الرسالة إلى ${i + 1} من ${widget.volunteers.length} متطوع',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.orange,
            ),
          );
          widget.onComplete();
          Navigator.pop(context);
          return;
        }
      }
    }

    // All messages sent
    setState(() => _isSending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم فتح واتساب لجميع الـ ${widget.volunteers.length} متطوع ✓',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: Colors.green,
      ),
    );

    widget.onComplete();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _isSending ? null : () => Navigator.pop(context),
          ),
          title: Text(
            'إرسال إلى ${widget.volunteers.length} متطوع',
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message composer
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'اكتب الرسالة:',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'استخدم @name لاستبدالها باسم كل متطوع',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _messageController,
                          maxLines: 6,
                          minLines: 4,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'اكتب رسالتك هنا...',
                            hintStyle: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppTheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        if (_messageController.text.contains('@name')) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'معاينة:',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _personalizeMessage(
                                    _messageController.text,
                                    widget.volunteers.first.name,
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
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

                const SizedBox(height: 16),

                // Send method selection
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'اختر طريقة الإرسال:',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'رسالة نصية',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14, // Reduced font size
                                      ),
                                    ),
                                    SizedBox(width: 4), // Reduced spacing

                                    FaIcon(
                                      FontAwesomeIcons.message,
                                      size: 16,
                                    ), // Reduced size
                                  ],
                                ),
                                selected: _selectedMethod == 'sms',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedMethod = selected ? 'sms' : null;
                                  });
                                },
                                selectedColor: AppTheme.primary,
                                labelStyle: TextStyle(
                                  color: _selectedMethod == 'sms'
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ), // Reduced spacing between chips
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'واتساب',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14, // Reduced font size
                                      ),
                                    ),
                                    SizedBox(width: 4), // Reduced spacing

                                    FaIcon(
                                      FontAwesomeIcons.whatsapp,
                                      size: 18, // Reduced size
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                                selected: _selectedMethod == 'whatsapp',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedMethod = selected
                                        ? 'whatsapp'
                                        : null;
                                  });
                                },
                                selectedColor: AppTheme.primary,
                                labelStyle: TextStyle(
                                  color: _selectedMethod == 'whatsapp'
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Send button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendMessages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: _isSending
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedMethod == 'whatsapp'
                                    ? 'جاري فتح واتساب ($_currentIndex/${widget.volunteers.length})'
                                    : 'جاري الإرسال ($_currentIndex/${widget.volunteers.length})',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'إرسال إلى ${widget.volunteers.length} متطوع',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
