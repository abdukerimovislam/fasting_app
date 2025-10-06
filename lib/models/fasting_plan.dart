

class FastingPlan {
  final String name; // e.g., "16:8 Leangains"
  final int fastingHours;

  const FastingPlan({required this.name, required this.fastingHours});

  // A helper to get the duration in seconds
  int get goalInSeconds => fastingHours * 3600;
}