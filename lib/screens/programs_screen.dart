// lib/screens/programs_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fasting_tracker/screens/program_detail_screen.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      // First, we listen to the user's document to know if they are a Pro user
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        // Safely get the isPro status, default to false if not present
        final isUserPro = (userSnapshot.data?.data() as Map<String, dynamic>?)?['isPro'] ?? false;

        // Now, we build the list of programs
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('programs').snapshots(),
          builder: (context, programSnapshot) {
            if (!programSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final programs = programSnapshot.data!.docs;

            return ListView.builder(
              itemCount: programs.length,
              itemBuilder: (context, index) {
                final program = programs[index];
                final data = program.data() as Map<String, dynamic>;
                final bool isProProgram = data['isPro'] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(data['title'] ?? 'No Title'),
                    subtitle: Text(data['description'] ?? 'No Description'),
                    trailing: isProProgram
                        ? Chip(
                      label: const Text('PRO'),
                      backgroundColor: Colors.amber.shade700,
                    )
                        : null,
                    onTap: () {
                      if (isProProgram && !isUserPro) {
                        // If the program is Pro and the user is not, show the paywall
                        // For now, we'll just show a simple dialog
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Pro Feature'),
                            content: const Text('This is a Pro feature. Please upgrade to access all programs.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
                            ],
                          ),
                        );
                      } else {
                        // If the program is free or the user is Pro, show the details
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProgramDetailScreen(programDoc: program),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}