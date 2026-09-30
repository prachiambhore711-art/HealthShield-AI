import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:frontend/features/auth/data/auth_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  
  // Navigator key to trigger routing when app is running
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Tracks any pending route triggered by a notification tap when app is launch-cold.
  static String? pendingRoute;

  static bool _timezoneInitialized = false;

  /// Initialize local notifications plugin and timezone database
  static Future<void> initialize() async {
    _configureLocalTimeZone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == 'open_emergency_qr') {
          if (AuthService.token != null && AuthService.userRole == 'patient') {
            navigatorKey.currentState?.pushNamed('/patient/qr');
          } else {
            pendingRoute = '/patient/qr';
          }
        } else if (response.payload == 'open_reminders') {
          if (AuthService.token != null && AuthService.userRole == 'patient') {
            navigatorKey.currentState?.pushNamed('/patient/reminders');
          }
        }
      },
    );

    // Request permissions on startup
    await requestPermissions();
  }

  /// Configures the local timezone from the system database
  static void _configureLocalTimeZone() {
    if (_timezoneInitialized) return;
    try {
      tz_data.initializeTimeZones();
      final String timeZoneName = DateTime.now().timeZoneName;
      if (tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        _timezoneInitialized = true;
        return;
      }
      // Match by exact offset from UTC
      final Duration offset = DateTime.now().timeZoneOffset;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offset) {
          tz.setLocalLocation(loc);
          _timezoneInitialized = true;
          return;
        }
      }
      _timezoneInitialized = true;
    } catch (_) {}
  }

  /// Request permissions for local alerts
  static Future<void> requestPermissions() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (_) {}
  }

  /// Show standard lock-screen visibility indicator
  static Future<void> showEmergencyNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'emergency_channel_id',
      'Emergency Services',
      channelDescription: 'Emergency QR available',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true, // Remains visible as long as user is logged in
      visibility: NotificationVisibility.public, // Exposes basic summary on locked screens
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: 999,
      title: 'HealthShield AI',
      body: 'Emergency QR available',
      notificationDetails: platformDetails,
      payload: 'open_emergency_qr',
    );
  }

  /// Clears/cancels the active emergency notification
  static Future<void> clearNotification() async {
    try {
      await _plugin.cancel(id: 999);
    } catch (_) {}
    pendingRoute = null;
  }

  /// Schedules a future medication reminder at the configured time.
  /// Never calls .show() directly. Uses zonedSchedule with timezone support.
  static Future<void> scheduleMedicationAlert(
    int reminderId,
    String medicationName,
    String dosage,
    String times, {
    String frequency = "Once daily",
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _configureLocalTimeZone();

      // Cancel any previous schedule for this reminder
      await cancelMedicationAlert(reminderId);

      // Parse HH:mm from the time string
      int hour = 8;
      int minute = 0;
      try {
        final clean = times.trim();
        final parts = clean.split(':');
        if (parts.length >= 2) {
          hour = int.parse(parts[0].trim());
          final minPart = parts[1].trim().split(' ')[0];
          minute = int.parse(minPart);
          if (clean.toLowerCase().contains('pm') && hour < 12) {
            hour += 12;
          } else if (clean.toLowerCase().contains('am') && hour == 12) {
            hour = 0;
          }
        }
      } catch (_) {}

      // Calculate next valid occurrence in device local timezone
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If scheduled time today has already passed, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Respect start date: if future start date provided, advance to that day
      if (startDate != null) {
        final tz.TZDateTime startTz = tz.TZDateTime(
          tz.local,
          startDate.year,
          startDate.month,
          startDate.day,
          hour,
          minute,
        );
        if (startTz.isAfter(scheduledDate)) {
          scheduledDate = startTz;
        }
      }

      // Respect end date: if end date has already passed, do not schedule
      if (endDate != null) {
        final tz.TZDateTime endTz = tz.TZDateTime(
          tz.local,
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        if (scheduledDate.isAfter(endTz)) {
          return;
        }
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'medication_reminders_channel',
        'Medication Reminders',
        channelDescription: 'Scheduled reminders for prescribed medications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      // Unique notification id derived from reminder id (range 1000-8999)
      final int notifId = 1000 + (reminderId % 8000);

      final bool isDaily = frequency.toLowerCase().contains('daily') ||
          frequency.toLowerCase().contains('every') ||
          frequency.toLowerCase().contains('meals');

      await _plugin.zonedSchedule(
        id: notifId,
        title: 'Medication Reminder: $medicationName',
        body: 'Time to take $medicationName ($dosage). Scheduled at $times.',
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: isDaily ? DateTimeComponents.time : null,
        payload: 'open_reminders',
      );
    } catch (_) {
      // Scheduling errors must not crash the application
    }
  }

  /// Cancels an active scheduled medication reminder
  static Future<void> cancelMedicationAlert(int reminderId) async {
    try {
      final int notifId = 1000 + (reminderId % 8000);
      await _plugin.cancel(id: notifId);
    } catch (_) {}
  }
}
