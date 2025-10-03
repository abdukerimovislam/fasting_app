// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';

// Import the necessary Firebase packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fasting_tracker/screens/progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // Timer and state management variables
  Timer? _timer;
  int _start = 16 * 3600; // Default goal: 16 hours in seconds
  int _current = 0;
  bool _isFasting = false;

  // Variables to track the start and end times of the fast
  DateTime? _startTime;
  DateTime? _endTime;
  bool get isFasting => _isFasting;

  void handleFastButtonPress() {
    if (_isFasting) {
      stopFast();
    } else {
      startTimer(_start);
    }
  }

  /// Starts the countdown timer for the fast.
  void startTimer(int seconds) {
    setState(() {
      _isFasting = true;
      _current = seconds;
      _startTime = DateTime.now(); // Record the start time
    });

    // Create a periodic timer that fires every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_current > 0) {
        setState(() {
          _current--;
        });
      } else {
        // If the timer reaches zero, automatically stop the fast
        stopFast();
      }
    });
  }

  /// Stops the fast, saves the data, and resets the state.
  void stopFast() async {
    _endTime = DateTime.now(); // Record the end time

    // Save the fast session to Firestore if it was started
    if (_startTime != null) {
      await saveFastToFirestore();
    }

    // Reset all state variables and cancel the timer
    setState(() {
      _isFasting = false;
      _timer?.cancel();
      _current = 0;
      _startTime = null;
      _endTime = null;
    });
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
      'goalInSeconds': _start,
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
    // Look how simple this is now!
    // No Scaffold, no AppBar, no FloatingActionButton.
    // It just returns the UI it's responsible for.
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer gray circle
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              shape: BoxShape.circle,
            ),
          ),
          // Inner background circle
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .scaffoldBackgroundColor,
              shape: BoxShape.circle,
            ),
          ),
          // The content (text) inside the timer circle
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isFasting ? 'Fasting' : 'Ready to Start',
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
                'Goal: ${formatTime(_start)}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          )
        ],
      ),
    );
  }
}
