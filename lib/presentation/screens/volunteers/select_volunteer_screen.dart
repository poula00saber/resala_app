// ============================================
// FILE: lib/presentation/screens/volunteers/select_volunteer_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../themes/app_theme.dart';

class SelectVolunteerScreen extends StatefulWidget {
  const SelectVolunteerScreen({super.key});

  @override
  State<SelectVolunteerScreen> createState() => _SelectVolunteerScreenState();
}

class _SelectVolunteerScreenState extends State<SelectVolunteerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
            // Search Bar
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
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),

            // Volunteers List
            Expanded(
              child: StreamBuilder(
                stream: Provider.of<VolunteerProvider>(context, listen: false)
                    .searchVolunteers(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'حدث خطأ: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final volunteers = snapshot.data ?? [];

                  if (volunteers.isEmpty) {
                    return Center(
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
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: volunteers.length,
                    itemBuilder: (context, index) {
                      final volunteer = volunteers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary,
                            radius: 28,
                            child: Text(
                              volunteer.name[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                volunteer.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (!volunteer.hasInterview) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'لم يتم عمل مقابلة',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 14),
                                  const SizedBox(width: 4),
                                  Text(volunteer.phone),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(volunteer.address)),
                                ],
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, volunteer.id);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('اختيار'),
                          ),
                        ),
                      );
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ============================================
// 🔥 FIREBASE CONNECTIVITY TEST
// Add this to main.dart temporarily to test
// ============================================

/*
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> testFirebaseConnection() async {
  try {
    print('🔄 Testing Firebase connection...');
    
    // Test Write
    await FirebaseFirestore.instance
        .collection('test')
        .add({
      'timestamp': FieldValue.serverTimestamp(),
      'message': 'Test from app',
    });
    
    print('✅ Firebase WRITE successful!');
    
    // Test Read
    final snapshot = await FirebaseFirestore.instance
        .collection('test')
        .limit(1)
        .get();
    
    print('✅ Firebase READ successful! Found ${snapshot.docs.length} documents');
    print('✅ Firebase is working perfectly!');
    
  } catch (e) {
    print('❌ Firebase Error: $e');
  }
}

// In main() function:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Test Firebase
  await testFirebaseConnection();
  
  runApp(const MyApp());
}
*/

// ============================================
// 📋 COMPLETE TESTING CHECKLIST
// ============================================

/*

✅ STEP 1: Run the app
   flutter run

✅ STEP 2: Check logs for Firebase connection
   Look for: "✅ Firebase is working perfectly!"

✅ STEP 3: Create a volunteer
   - Tap "إضافة حدث جديد"
   - Create any event
   - Check Firestore Console → events collection

✅ STEP 4: Create a volunteer
   - Inside event, tap "إضافة متطوع"
   - Tap "إضافة متطوع جديد"
   - Fill form and save
   - Check Firestore Console → volunteers collection
   - Verify hasInterview = false

✅ STEP 5: Check اجتماع restrictions
   - Create event with type "اجتماع"
   - Edit event
   - Try to add volunteer
   - Should show "اختيار من القائمة" only (no create new)

✅ STEP 6: Check اداريات restrictions
   - Create event with type "اداريات"
   - Edit event
   - Should show: "لا يمكن إضافة متطوعين للإداريات"

✅ STEP 7: Verify real-time updates
   - Open app
   - Go to Firebase Console
   - Manually add/edit event
   - App should update automatically

✅ STEP 8: Check volunteer interview status
   - Create new volunteer from app
   - Go to Select Volunteer screen
   - Should see "لم يتم عمل مقابلة" badge

// ============================================
// 🎯 FIREBASE CONSOLE URLs
// ============================================

Firebase Console: https://console.firebase.google.com
Your Project → Firestore Database

You should see 2 collections:
1. events
2. volunteers

Click on any document to see its data!

*/