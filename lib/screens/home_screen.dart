// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fasting_tracker/models/fasting_plan.dart';
import 'package:fasting_tracker/models/fasting_stage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _timer;
  late FastingPlan _selectedPlan;
  bool _isFasting = false;
  int _current = 0;
  DateTime? _startTime;
  DateTime? _endTime;
  FastingStage? _currentStage;

  final List<FastingPlan> _plans = const [
    FastingPlan(name: '16:8 Leangains', fastingHours: 16),
    FastingPlan(name: '18:6 Warrior', fastingHours: 18),
    FastingPlan(name: '20:4 The Fast', fastingHours: 20),
  ];

  final List<FastingStage> _fastingStages = const [
    FastingStage(startHour: 0, title: 'Anabolic Stage', description: 'Body is digesting your last meal.', icon: Icons.restaurant),
    FastingStage(startHour: 4, title: 'Catabolic Stage', description: 'Using stored glycogen for energy.', icon: Icons.battery_charging_full),
    FastingStage(startHour: 12, title: 'Ketosis', description: 'Burning fat for fuel.', icon: Icons.local_fire_department),
    FastingStage(startHour: 16, title: 'Autophagy', description: 'Cellular cleanup begins.', icon: Icons.recycling),
  ];

  @override
  void initState() {
    super.initState();
    _selectedPlan = _plans.first;
    _listenToNotificationUpdates();
  }

  bool get isFasting => _isFasting;
  bool get isCompleted => _current <= 0;

  void _listenToNotificationUpdates() {
    FlutterBackgroundService().on('update').listen((event) {
      if (event != null && mounted) {
        final secondsLeft = event['seconds_left'] as int;
        final initialDuration = _selectedPlan.goalInSeconds; // This will update based on the plan
        flutterLocalNotificationsPlugin.show(
          888,
          'Fasting in Progress...',
          'Time Remaining: ${formatTime(secondsLeft)}',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'fasting_foreground_service',
              'Fasting Timer',
              channelDescription: 'Shows the live fasting timer.',
              icon: '@mipmap/ic_launcher',
              ongoing: true,
              playSound: false,
              showProgress: true,
              maxProgress: initialDuration,
              progress: initialDuration - secondsLeft,
            ),
          ),
        );
      }
    });
  }

  Future<void> handleFastButtonPress() async {
    if (_isFasting) {
      await stopFast();
    } else {
      startTimer(_selectedPlan.goalInSeconds);
    }
  }

  void startTimer(int seconds) {
    setState(() {
      _isFasting = true;
      _current = seconds;
      _startTime = DateTime.now().subtract(Duration(seconds: _selectedPlan.goalInSeconds - seconds));
      _currentStage = _fastingStages.first;
    });

    final service = FlutterBackgroundService();
    service.startService();
    service.invoke('setTimer', {'duration': seconds});

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_current > 0) {
        setState(() {
          _current--;
          double elapsedHours = (_selectedPlan.goalInSeconds - _current) / 3600.0;
          _currentStage = _fastingStages.lastWhere((stage) => elapsedHours >= stage.startHour, orElse: () => _fastingStages.first);
        });
      } else {
        stopFast();
      }
    });
  }

  Future<void> stopFast() async {
    try {
      final service = FlutterBackgroundService();
      var isRunning = await service.isRunning();
      if (isRunning) {
        service.invoke("stopService");
      }
      await flutterLocalNotificationsPlugin.cancel(888);

      _endTime = DateTime.now();
      if (_startTime != null) {
        await saveFastToFirestore();
      }

      // Check if user is in a program and clear it
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'activeProgramId': null,
          'activeProgramTitle': null,
          'currentProgramDay': null,
          'programStartDate': null,
          'activeFastStartTime': null,
          'activeFastHours': null,
        });
      }

      if (mounted) {
        setState(() {
          _isFasting = false;
          _timer?.cancel();
          _timer = null;
          _current = 0;
          _startTime = null;
          _endTime = null;
          _currentStage = null;
        });
      }
    } catch (e) {
      print("Error stopping fast: $e");
    }
  }

  void _showPlanSelector() {
    if (_isFasting) return; // Don't allow changing plan during a fast
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

  Future<void> saveFastToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final duration = _endTime!.difference(_startTime!);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('fasting_sessions').add({
      'startTime': _startTime,
      'endTime': _endTime,
      'durationInSeconds': duration.inSeconds,
      'goalInSeconds': _selectedPlan.goalInSeconds,
    });
  }

  String formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secsStr = secs.toString().padLeft(2, '0');
    return '$hoursStr:$minutesStr:$secsStr';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Not logged in."));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String? activeProgramId = userData['activeProgramId'];

        if (activeProgramId != null && !_isFasting) {
          final Timestamp startTime = userData['activeFastStartTime'] as Timestamp? ?? Timestamp.now();
          final int fastHours = userData['activeFastHours'] as int? ?? 16;
          final int secondsPassed = DateTime.now().difference(startTime.toDate()).inSeconds;
          final int secondsLeft = (fastHours * 3600) - secondsPassed;

          // Update the _selectedPlan to match the program's fast
          final programPlan = FastingPlan(name: 'Program Fast', fastingHours: fastHours);
          if (_selectedPlan.fastingHours != programPlan.fastingHours) {
            _selectedPlan = programPlan;
          }

          if (secondsLeft > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isFasting) {
                startTimer(secondsLeft);
              }
            });
          }
        }

        final double progress = _isFasting
            ? (_selectedPlan.goalInSeconds - _current) / _selectedPlan.goalInSeconds
            : 0.0;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (activeProgramId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Chip(
                    label: Text(userData['activeProgramTitle'] ?? 'Active Program', style: const TextStyle(color: Colors.white)),
                    avatar: const Icon(Icons.explore, color: Colors.white),
                    backgroundColor: Colors.white24,
                  ),
                )
              else
                TextButton(
                  onPressed: _showPlanSelector,
                  child: Column(
                    children: [
                      Text('Current Plan: ${_selectedPlan.name}', style: const TextStyle(color: Colors.white)),
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),

              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(width: 250, height: 250, child: CircularProgressIndicator(value: 1.0, strokeWidth: 12, color: Colors.grey.shade800)),
                  SizedBox(width: 250, height: 250, child: CircularProgressIndicator(value: progress, strokeWidth: 12, color: const Color(0xFFE94560), strokeCap: StrokeCap.round)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isFasting ? 'Fasting' : 'Ready to Start', style: const TextStyle(fontSize: 20, color: Colors.white)),
                      const SizedBox(height: 10),
                      Text(formatTime(_current), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 10),
                      Text('Goal: ${formatTime(_selectedPlan.goalInSeconds)}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 30),

              if (_currentStage != null && _isFasting)
                Card(
                  color: Colors.white10,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(_currentStage!.icon, color: Colors.white, size: 30),
                        const SizedBox(height: 8),
                        Text(_currentStage!.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(_currentStage!.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}