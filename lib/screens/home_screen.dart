// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fasting_tracker/models/fasting_plan.dart';
// Import the necessary Firebase packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasting_tracker/models/fasting_stage.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:fasting_tracker/screens/progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {


  // Timer and state management variables
  FastingStage? _currentStage;
  final List<FastingStage> _fastingStages = const [
    FastingStage(
      startHour: 0,
      title: 'Anabolic Stage',
      description: 'Your body is digesting and absorbing nutrients from your last meal.',
      icon: Icons.restaurant,
    ),
    FastingStage(
      startHour: 4,
      title: 'Catabolic Stage',
      description: 'Your body has finished digesting and starts using stored glycogen for energy.',
      icon: Icons.battery_charging_full,
    ),
    FastingStage(
      startHour: 12,
      title: 'Ketosis',
      description: 'Glycogen stores are low. Your body starts producing ketones, burning fat for fuel.',
      icon: Icons.local_fire_department,
    ),
    FastingStage(
      startHour: 16,
      title: 'Autophagy',
      description: 'Your body begins cellular cleanup, removing old and damaged cells to regenerate newer, healthier cells.',
      icon: Icons.recycling,
    ),
  ];
  Timer? _timer;
  final List<FastingPlan> _plans = const [
    FastingPlan(name: '16:8 Leangains', fastingHours: 16),
    FastingPlan(name: '18:6 Warrior', fastingHours: 18),
    FastingPlan(name: '20:4 The Fast', fastingHours: 20),
    FastingPlan(name: 'Custom', fastingHours: 12), // Placeholder for custom
  ];

  // Keep track of the currently selected plan
  late FastingPlan _selectedPlan;

  @override
  void initState() {
    super.initState();
    // Set the default plan when the screen initializes
    _selectedPlan = _plans.first;
  }

  // Default goal: 16 hours in seconds
  int _current = 0;
  bool _isFasting = false;

  // Variables to track the start and end times of the fast
  DateTime? _startTime;
  DateTime? _endTime;

  bool get isFasting => _isFasting;

  Future<void> handleFastButtonPress() async {
    if (isFasting) {
      // Tell this function to WAIT for stopFast to complete
      await stopFast();
    } else {
      startTimer(_selectedPlan.goalInSeconds);
    }
  }

  void _showPlanSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _plans.length,
          itemBuilder: (context, index) {
            final plan = _plans[index];
            return ListTile(
              title: Text(plan.name),
              subtitle: Text('${plan.fastingHours} hours fasting'),
              onTap: () {
                setState(() {
                  _selectedPlan = plan;
                });
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }

  /// Starts the countdown timer for the fast.
  void startTimer(int seconds) {
    setState(() {
      _isFasting = true;
      _current = seconds;
      _startTime = DateTime.now(); // Record the start time
      _currentStage = _fastingStages.first;
    });
    final service = FlutterBackgroundService();
    service.startService();
    service.invoke('setTimer', {'duration': seconds});

    // Create a periodic timer that fires every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_current > 0) {
        setState(() {
          _current--;
          double elapsedHours = (_selectedPlan.goalInSeconds - _current) /
              3600.0;

          _currentStage = _fastingStages
              .where((stage) => elapsedHours >= stage.startHour)
              .last;
        });
      } else {
        // If the timer reaches zero, automatically stop the fast
        stopFast();
      }
    });
  }

  /// Stops the fast, saves the data, and resets the state.
  Future<void> stopFast() async {
    try {
      // 1. Check if the background service is running before trying to stop it.
      final service = FlutterBackgroundService();
      var isRunning = await service.isRunning();
      if (isRunning) {
        service.invoke("stopService");
      }

      _endTime = DateTime.now();

      // The rest of the logic is the same...
      if (_startTime != null) {
        await saveFastToFirestore();
      }

      setState(() {
        _isFasting = false;
        _timer?.cancel();
        _current = 0;
        _startTime = null;
        _endTime = null;
        _currentStage = null;
      });
    } catch (e) {
      // If any error occurs, print it for debugging instead of crashing.
      print("Error stopping fast: $e");
    }
  }
  /// Saves the completed fast session to the user's collection in Firestore.
  Future<void> saveFastToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Exit if no user is logged in

    // Calculate the actual duration of the fast
    final duration = _endTime!.difference(_startTime!);

    // Reference the user's sub-collection for fasting sessions and add a new document
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('fasting_sessions')
        .add({
      'startTime': _startTime,
      'endTime': _endTime,
      'durationInSeconds': duration.inSeconds,
      'goalInSeconds': _selectedPlan.goalInSeconds,
    });
  }

  /// Formats a duration in seconds into a HH:MM:SS string.
  String formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secsStr = secs.toString().padLeft(2, '0');

    return '$hoursStr:$minutesStr:$secsStr';
  }

  /// Clean up the timer when the widget is removed from the screen.
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = isFasting
        ? (_selectedPlan.goalInSeconds - _current) / _selectedPlan.goalInSeconds
        : 0.0;

    // 👇 ADD THIS Center WIDGET TO WRAP THE ENTIRE LAYOUT
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // WIDGET 1: The Plan Selector
          TextButton(
            onPressed: _showPlanSelector,
            child: Column(
              children: [
                Text(
                  'Current Plan: ${_selectedPlan.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // WIDGET 2: The Timer Stack
          Stack(
            alignment: Alignment.center,
            children: [
              // Layer 1: Background track
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  color: Colors.grey.shade800,
                ),
              ),
              // Layer 2: Progress bar
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  color: const Color(0xFFE94560),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Layer 3: The timer text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isFasting ? 'Fasting' : 'Ready to Start',
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatTime(_current),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Goal: ${formatTime(_selectedPlan.goalInSeconds)}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 30),

          // WIDGET 3: The Fasting Stage Card
          if (_currentStage != null && isFasting)
            Card(
              color: Colors.white10,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(_currentStage!.icon, color: Colors.white, size: 30),
                    const SizedBox(height: 8),
                    Text(
                      _currentStage!.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentStage!.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}