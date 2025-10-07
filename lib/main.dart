// lib/main.dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fasting_tracker/services/background_service.dart';
import 'package:fasting_tracker/auth_gate.dart';
import 'package:fasting_tracker/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (Platform.isAndroid || Platform.isIOS) {
    await Permission.notification.request();
  }

  configureLocalTimeZone();
  await initializeService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fasting Tracker',
      // We are back to a single, hardcoded dark theme
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFFE94560),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}