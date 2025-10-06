// lib/models/fasting_stage.dart

import 'package:flutter/material.dart';

class FastingStage {
  final int startHour;
  final String title;
  final String description;
  final IconData icon;

  const FastingStage({
    required this.startHour,
    required this.title,
    required this.description,
    required this.icon,
  });
}