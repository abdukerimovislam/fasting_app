// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // We will create this file next

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp is the root widget of our app
    return MaterialApp(
      title: 'Fasting Tracker',
      theme: ThemeData.dark().copyWith(
        // Let's use a dark theme. It looks sleek!
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        primaryColor: const Color(0xFFE94560),
      ),
      home: const AuthGate(), // This sets our starting screen
    );
  }
}