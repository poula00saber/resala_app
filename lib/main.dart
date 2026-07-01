// ============================================
// FILE: lib/main.dart
// UPDATED: Added missing providers
// ============================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:resala/presentation/providers/committee_provider.dart';
import 'package:resala/presentation/providers/evaluation_provider.dart';
import 'package:resala/presentation/providers/interview_provider.dart';
import 'package:resala/presentation/providers/inventory_provider.dart';
import 'package:resala/presentation/providers/promotion_provider.dart'; // ADD THIS
import 'package:resala/presentation/screens/splash_screen.dart';
import 'package:resala/services/auth_service.dart';
import 'firebase_options.dart';
import 'presentation/providers/event_provider.dart';
import 'presentation/providers/volunteer_provider.dart';
import 'presentation/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()..initEvents()),
        ChangeNotifierProvider(
          create: (_) => VolunteerProvider()..initVolunteers(),
        ),
        ChangeNotifierProvider(create: (_) => EvaluationProvider()),
        ChangeNotifierProvider(
          create: (_) => CommitteeProvider()..initCommittees(),
        ),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(
          create: (_) => InterviewProvider()..initInterviews(),
        ),
        // ADD THIS:
        ChangeNotifierProvider(create: (_) => PromotionProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()..initialize()),
      ],
      child: MaterialApp(
        title: 'Et3am Alex',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,

        // ✅ RTL Support
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // ✅ Force RTL
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },

        home: const SplashScreen(),
      ),
    );
  }
}

// ============================================
// HOW TO CHECK FIREBASE CONNECTIVITY
// ============================================

/*

1. CHECK FIREBASE CONSOLE:
   - Go to: https://console.firebase.google.com
   - Select your project
   - Go to Firestore Database
   - You should see "events" and "volunteers" collections after adding data

2. CHECK CONNECTIVITY IN APP:
   Add this test function to main.dart:

   Future<void> testFirebaseConnection() async {
     try {
       // Test write
       await FirebaseFirestore.instance
           .collection('test')
           .add({'timestamp': FieldValue.serverTimestamp()});
       
       print('✅ Firebase connected successfully!');
       
       // Test read
       final snapshot = await FirebaseFirestore.instance
           .collection('test')
           .limit(1)
           .get();
       
       print('✅ Read test: ${snapshot.docs.length} documents');
     } catch (e) {
       print('❌ Firebase error: $e');
     }
   }

   // Call it in main():
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     
     // Test connection
     await testFirebaseConnection();
     
     runApp(const MyApp());
   }

3. CHECK LOGS:
   Run app with: flutter run
   Watch for:
   - ✅ "Firebase connected successfully!"
   - ❌ Any error messages

4. VERIFY DATA IN FIRESTORE:
   After creating an event or volunteer:
   - Open Firebase Console
   - Go to Firestore Database
   - Check "events" or "volunteers" collection
   - You should see your data there

5. FIRESTORE RULES (IMPORTANT!):
   In Firebase Console > Firestore Database > Rules
   For testing, use:

   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true; // For testing only!
       }
     }
   }

   ⚠️ WARNING: This allows anyone to read/write.
   For production, use proper authentication!

   Better rules:
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /events/{eventId} {
         allow read: if true;
         allow write: if request.auth != null;
       }
       match /volunteers/{volunteerId} {
         allow read: if true;
         allow write: if request.auth != null;
       }
     }
   }

6. DEBUG TIPS:
   - Check internet connection
   - Verify firebase_options.dart exists
   - Check pubspec.yaml dependencies
   - Run: flutter clean && flutter pub get
   - Restart app after changes

*/
