// lib/screens/program_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgramDetailScreen extends StatefulWidget {
  final DocumentSnapshot programDoc;
  const ProgramDetailScreen({super.key, required this.programDoc});

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  late Future<QuerySnapshot> _dailyPlanFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the daily plan sub-collection
    _dailyPlanFuture = widget.programDoc.reference.collection('dailyPlan').orderBy('dayNumber').get();
  }

  void _startProgram() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) return;

    final programData = widget.programDoc.data() as Map<String, dynamic>? ?? {};

    // We will also fetch the details for Day 1 to start the first fast
    final day1Doc = await widget.programDoc.reference.collection('dailyPlan').doc('day1').get();
    final day1Data = day1Doc.data() as Map<String, dynamic>? ?? {};
    final day1FastHours = day1Data['fastingHours'] ?? 16;

    // Update the user's document in Firestore to track the active program
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'activeProgramId': widget.programDoc.id,
      'activeProgramTitle': programData['title'] ?? 'Unnamed Program',
      'currentProgramDay': 1,
      'programStartDate': Timestamp.now(),
      // Also save the start time of the first fast
      'activeFastStartTime': Timestamp.now(),
      'activeFastHours': day1FastHours,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Program started! Your first fast is set.')),
    );

    // Pop back to the main screen. The HomeScreen will now detect the active program.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // Safely get the data with a fallback to an empty map
    final programData = widget.programDoc.data() as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        // Add a fallback for the title
        title: Text(programData['title'] ?? 'Program Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add a fallback for the description
            Text(
                programData['description'] ?? 'No description available.',
                style: Theme.of(context).textTheme.titleMedium
            ),
            const SizedBox(height: 24),
            Text('Daily Schedule', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            FutureBuilder<QuerySnapshot>(
              future: _dailyPlanFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No daily plan found for this program.'));
                }

                final dailyDocs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dailyDocs.length,
                  itemBuilder: (context, index) {
                    final dayData = dailyDocs[index].data() as Map<String, dynamic>? ?? {};
                    return ListTile(
                      leading: CircleAvatar(child: Text('${dayData['dayNumber'] ?? '0'}')),
                      title: Text('${dayData['fastingHours'] ?? 0} Hour Fast'),
                      subtitle: Text(dayData['tip'] ?? 'No tip available.'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _startProgram,
          child: const Text('Start This Program'),
        ),
      ),
    );
  }
}