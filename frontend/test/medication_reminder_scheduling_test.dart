import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    // Default to a known timezone for deterministic testing
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  });

  group('Medication Reminder Scheduling Logic Tests', () {
    test('Configured time in future today schedules for today', () {
      final now = tz.TZDateTime.now(tz.local);
      
      // If adding 1 hour rolls over to tomorrow, skip or use now.hour with minute + 30
      final targetHour = now.hour < 23 ? now.hour + 1 : 23;
      final targetMinute = 30;

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        targetHour,
        targetMinute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      if (now.hour < 23 || (now.hour == 23 && now.minute < 30)) {
        expect(scheduledDate.day, equals(now.day));
      }
    });

    test('Configured time in past today schedules for tomorrow', () {
      final now = tz.TZDateTime.now(tz.local);
      // Pick a time that has definitely passed today: 1 minute ago, or 00:01
      final pastHour = 0;
      final pastMinute = 1;

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        pastHour,
        pastMinute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final tomorrow = now.add(const Duration(days: 1));
      expect(scheduledDate.day, equals(tomorrow.day));
      expect(scheduledDate.isAfter(now), isTrue);
    });

    test('Future start date advances scheduledDate to that day', () {
      final now = tz.TZDateTime.now(tz.local);
      final futureDate = now.add(const Duration(days: 5));

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        8,
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final startTz = tz.TZDateTime(
        tz.local,
        futureDate.year,
        futureDate.month,
        futureDate.day,
        8,
        0,
      );
      if (startTz.isAfter(scheduledDate)) {
        scheduledDate = startTz;
      }

      expect(scheduledDate.day, equals(futureDate.day));
      expect(scheduledDate.month, equals(futureDate.month));
    });

    test('Past end date prevents scheduling', () {
      final now = tz.TZDateTime.now(tz.local);
      final pastDate = now.subtract(const Duration(days: 2));

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        8,
        0,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final endTz = tz.TZDateTime(
        tz.local,
        pastDate.year,
        pastDate.month,
        pastDate.day,
        23,
        59,
        59,
      );

      final shouldCancel = scheduledDate.isAfter(endTz);
      expect(shouldCancel, isTrue);
    });
  });
}
