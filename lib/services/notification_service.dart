import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int dailyKuralNotificationId = 100;
  static const int _testNotificationId = 999;
  static const int _scheduledTestId = 998;
  static const String _channelId = 'daily_kural_channel';
  static const String _channelName = 'Daily Kural';

  // Daily reminder time, pinned to India Standard Time.
  static const int _hour = 8;
  static const int _minute = 0;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: 'Daily Thirukkural reminder',
    importance: Importance.max,
    priority: Priority.high,
  );
  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Create the channel up-front so notifications can post on Android 8+.
    await _android?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Daily Thirukkural reminder',
      importance: Importance.max,
    ));

    // Runtime permission (Android 13+) and exact-alarm permission (12+/14).
    await _android?.requestNotificationsPermission();
    await _android?.requestExactAlarmsPermission();
  }

  /// Whether the OS currently allows this app to post notifications.
  Future<bool> notificationsEnabled() async =>
      await _android?.areNotificationsEnabled() ?? true;

  /// Fires a notification immediately — used to verify the pipeline works.
  Future<void> showTestNotification() async {
    await _plugin.show(
      _testNotificationId,
      'இன்றைய திருக்குறள்',
      'Test notification — notifications are working ✅',
      _details,
    );
  }

  /// Schedules a one-off notification ~1 minute out using the SAME
  /// zonedSchedule + exact-alarm path as the daily reminder — so you can
  /// verify the scheduling works without waiting until 8 AM.
  Future<void> scheduleTestInOneMinute() async {
    final ist = tz.getLocation('Asia/Kolkata');
    final when = tz.TZDateTime.now(ist).add(const Duration(minutes: 1));

    Future<void> doIt(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          _scheduledTestId,
          'இன்றைய திருக்குறள்',
          'Scheduled test fired — the daily 8 AM alarm should work too ✅',
          when,
          _details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

    try {
      await doIt(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      await doIt(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> scheduleDailyReminder() async {
    await _plugin.cancel(dailyKuralNotificationId); // clear any stale schedule

    // Pin to 8:00 AM IST regardless of the device's timezone.
    final ist = tz.getLocation('Asia/Kolkata');
    final now = tz.TZDateTime.now(ist);
    var scheduled =
        tz.TZDateTime(ist, now.year, now.month, now.day, _hour, _minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Prefer exact; if the OS refuses exact alarms, fall back to inexact so a
    // reminder still fires (just within a looser window).
    try {
      await _schedule(scheduled, AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      await _schedule(scheduled, AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> _schedule(tz.TZDateTime when, AndroidScheduleMode mode) {
    return _plugin.zonedSchedule(
      dailyKuralNotificationId,
      'இன்றைய திருக்குறள்',
      'Tap to read today\'s kural',
      when,
      _details,
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
