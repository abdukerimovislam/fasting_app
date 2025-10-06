// lib/screens/progress_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Please log in to see your progress.'));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('fasting_sessions')
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Complete a fast to see your stats!'));
          }

          final sessions = snapshot.data!.docs;

          // Perform calculations using the helper functions
          final longestFast = _calculateLongestFast(sessions);
          final averageFast = _calculateAverageFast(sessions);
          final currentStreak = _calculateCurrentStreak(sessions);

          return ListView(
            children: [
              // --- STATS CARDS SECTION ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatCard(title: 'Current Streak', value: '$currentStreak days'),
                    StatCard(title: 'Longest Fast', value: longestFast),
                    StatCard(title: 'Average Fast', value: averageFast),
                  ],
                ),
              ),

              // --- WEIGHT CHART SECTION ---
              SizedBox(
                height: 250,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildWeightChart(userId),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Fasting History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              // --- FASTING HISTORY LIST ---
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final data = session.data() as Map<String, dynamic>;
                  final startTime = (data['startTime'] as Timestamp).toDate();
                  final duration = data['durationInSeconds'] as int;
                  final goal = data['goalInSeconds'] as int;
                  final formattedDate = DateFormat.yMMMd().format(startTime);
                  final formattedDuration = _formatDuration(duration);
                  final formattedGoal = _formatDuration(goal);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                      title: Text('Fast Completed on $formattedDate'),
                      subtitle: Text('Duration: $formattedDuration / Goal: $formattedGoal'),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWeightDialog(context),
        tooltip: 'Add Weight Entry',
        child: const Icon(Icons.monitor_weight_outlined),
      ),
    );
  }
}

// --- REUSABLE STAT CARD WIDGET ---
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  const StatCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// --- TOP-LEVEL HELPER FUNCTIONS ---

Widget _buildWeightChart(String userId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('weightLog')
        .orderBy('timestamp', descending: false)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(
          child: Text(
            'No weight data yet. Add your first entry!',
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        );
      }
      final docs = snapshot.data!.docs;
      final List<FlSpot> spots = docs.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value.data() as Map<String, dynamic>;
        return FlSpot(index.toDouble(), data['weight'].toDouble());
      }).toList();
      return LineChart(LineChartData(/* ... Chart config ... */));
    },
  );
}

void _showAddWeightDialog(BuildContext context) {
  final TextEditingController weightController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Add Weight Entry'),
        content: TextField(
          controller: weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Weight'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final double? weight = double.tryParse(weightController.text);
              if (weight != null && user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('weightLog')
                    .add({'weight': weight, 'timestamp': Timestamp.now()});
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

String _calculateLongestFast(List<QueryDocumentSnapshot> sessions) {
  if (sessions.isEmpty) return "0h 0m";
  int longest = 0;
  for (var session in sessions) {
    final data = session.data() as Map<String, dynamic>;
    if (data['durationInSeconds'] > longest) {
      longest = data['durationInSeconds'];
    }
  }
  return _formatDuration(longest);
}

String _calculateAverageFast(List<QueryDocumentSnapshot> sessions) {
  if (sessions.isEmpty) return "0h 0m";
  int total = 0;
  for (var session in sessions) {
    final data = session.data() as Map<String, dynamic>;
    total += data['durationInSeconds'] as int;
  }
  return _formatDuration(total ~/ sessions.length);
}

int _calculateCurrentStreak(List<QueryDocumentSnapshot> sessions) {
  if (sessions.isEmpty) return 0;
  final endTimes = sessions
      .map((s) => (s.data() as Map<String, dynamic>)['endTime'] as Timestamp)
      .map((t) => t.toDate())
      .toList();

  int streak = 1;
  if (endTimes.length < 2) {
    final now = DateTime.now();
    final difference = now.difference(endTimes.first).inDays;
    return (difference <= 1) ? 1 : 0;
  }
  if (DateTime.now().difference(endTimes.first).inDays > 1) {
    return 0;
  }
  for (int i = 0; i < endTimes.length - 1; i++) {
    final date1 = endTimes[i];
    final date2 = endTimes[i + 1];
    final difference = date1.difference(date2).inHours;
    if (difference >= 12 && difference <= 36) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

String _formatDuration(int totalSeconds) {
  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '${hours}h ${minutes}m';
}