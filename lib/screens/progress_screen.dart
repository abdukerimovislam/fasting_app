// lib/screens/progress_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  // Helper function to format duration from seconds to a readable string
  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user's UID
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // If for some reason there is no user, show an empty screen
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Progress')),
        body: const Center(child: Text('Please log in to see your progress.')),
      );
    }

    return StreamBuilder<QuerySnapshot>(
        // Here's the magic: we listen to the user's fasting sessions collection,
        // ordered by the start time in descending order (newest first).
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('fasting_sessions')
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Handle the loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }

          // If there's no data, show a message
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No fasts completed yet.\nGo start one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // If we have data, display it in a list!
          final sessions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final data = session.data() as Map<String, dynamic>;

              // Safely get data from Firestore
              final startTime = (data['startTime'] as Timestamp).toDate();
              final duration = data['durationInSeconds'] as int;
              final goal = data['goalInSeconds'] as int;

              // Format the data for display
              final formattedDate = DateFormat.yMMMd().format(startTime); // e.g., Oct 3, 2025
              final formattedDuration = _formatDuration(duration);
              final formattedGoal = _formatDuration(goal);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                  title: Text('Fast Completed on $formattedDate'),
                  subtitle: Text('Duration: $formattedDuration / Goal: $formattedGoal'),
                ),
              );
            },
          );
        },
      );
  }
}