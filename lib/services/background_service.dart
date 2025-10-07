// lib/services/background_service.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

const notificationChannelId = 'fasting_foreground_service';
const mainNotificationId = 888; // For the main timer
const waterReminderNotificationIdStart = 1000; // Water reminders will have IDs 1000, 1001, etc.

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  configureLocalTimeZone();
  DartPluginRegistrant.ensureInitialized();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Timer? timer;
  int initialDuration = 0;

  service.on('setTimer').listen((event) {
    int currentDuration = event!['duration'];
    initialDuration = currentDuration;

    // --- NEW: Schedule water reminders when the fast starts ---
    _scheduleWaterReminders(flutterLocalNotificationsPlugin, currentDuration);

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentDuration > 0) {
        currentDuration--;
        // Update the main persistent notification
        flutterLocalNotificationsPlugin.show(
          mainNotificationId,
          'Fasting in Progress...',
          'Time Remaining: ${formatTime(currentDuration)}',
          NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'Fasting Timer',
              channelDescription: 'Shows the live fasting timer.',
              icon: '@drawable/notification_icon.png',
              ongoing: true,
              playSound: false,
              showProgress: true,
              maxProgress: initialDuration,
              progress: initialDuration - currentDuration,
            ),
          ),
        );
      } else {
        // When the fast finishes naturally
        timer.cancel();
        // We don't need to cancel water reminders here, as they've all fired.
        service.stopSelf();
      }
    });
  });

  service.on('stopService').listen((event) {
    timer?.cancel();
    flutterLocalNotificationsPlugin.cancel(mainNotificationId);
    // --- NEW: Cancel any pending water reminders ---
    _cancelAllWaterReminders(flutterLocalNotificationsPlugin);
    service.stopSelf();
  });
}

// --- NEW FUNCTION: Schedules water reminders every 2 hours ---

void _scheduleWaterReminders(
    FlutterLocalNotificationsPlugin plugin, int totalDurationInSeconds) {
  const reminderInterval = Duration(hours: 2);
  int reminderCount = totalDurationInSeconds ~/ reminderInterval.inSeconds;

  for (int i = 1; i <= reminderCount; i++) {
    final scheduledTime =
    tz.TZDateTime.now(tz.local).add(Duration(seconds: reminderInterval.inSeconds * i));

    plugin.zonedSchedule(
      waterReminderNotificationIdStart + i,
      "Hydration Reminder",
      "Don't forget to drink some water!",
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_reminder_channel',
          'Water Reminders',
          channelDescription: 'Reminders to stay hydrated during your fast.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@drawable/notification_icon.png',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      // --- ADD THIS REQUIRED PARAMETER BACK ---
    );
  }
}

// --- NEW FUNCTION: Cancels all scheduled water reminders ---
void _cancelAllWaterReminders(FlutterLocalNotificationsPlugin plugin) async {
  final pendingRequests = await plugin.pendingNotificationRequests();
  for (var request in pendingRequests) {
    // Cancel any notification whose ID is in our water reminder range
    if (request.id >= waterReminderNotificationIdStart) {
      plugin.cancel(request.id);
    }
  }
}


// --- The rest of the file is the same ---
String formatTime(int seconds) {
  int hours = seconds ~/ 3600;
  int minutes = (seconds % 3600) ~/ 60;
  int secs = seconds % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Create the notification channel for the main timer
  const AndroidNotificationChannel mainChannel = AndroidNotificationChannel(
    notificationChannelId,
    'Fasting Timer',
    description: 'Shows the live fasting timer.',
    importance: Importance.max,
  );

  // --- NEW: Create a separate channel for water reminders ---
  const AndroidNotificationChannel waterChannel = AndroidNotificationChannel(
    'water_reminder_channel',
    'Water Reminders',
    description: 'Reminders to stay hydrated during your fast.',
    importance: Importance.defaultImportance, // Use default importance for these
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(mainChannel);

  // --- NEW: Register the water reminder channel ---
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(waterChannel);


  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Fasting Service',
      initialNotificationContent: 'Preparing...',
      foregroundServiceNotificationId: mainNotificationId,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      autoStart: false,
    ),
  );
}

void configureLocalTimeZone() {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Bishkek'));
}