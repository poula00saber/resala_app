import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:resala/screens/lgoin/login_screen.dart';
import 'package:resala/screens/themes/app_theme.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ResalaApp());
}

class ResalaApp extends StatelessWidget {
  const ResalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Resala",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}
