import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int dailyKuralNotificationId = 100;

  // Daily reminder time, pinned to India Standard Time.
  static const int _hour = 8;
  static const int _minute = 0;

  Future<void> init() async {
    // Loads the tz database so zonedSchedule can work. The reminder is pinned
    // to IST (Asia/Kolkata) below, so we don't rely on the device's zone.
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    // Android 13+ needs explicit runtime permission to post notifications.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyReminder() async {
    // Pin to 8:00 AM IST regardless of the device's timezone.
    final ist = tz.getLocation('Asia/Kolkata');
    final now = tz.TZDateTime.now(ist);
    var scheduled =
        tz.TZDateTime(ist, now.year, now.month, now.day, _hour, _minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        dailyKuralNotificationId,
        'இன்றைய திருக்குறள்',
        'Tap to read today\'s kural',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_kural_channel',
            'Daily Kural',
            channelDescription: 'Daily Thirukkural reminder',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // Inexact avoids the SCHEDULE_EXACT_ALARM permission (which Android 14
        // denies by default, making exact scheduling throw). A daily nudge
        // doesn't need to-the-second precision, and this is more reliable
        // across OEMs.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeats daily
      );
    } catch (_) {
      // Scheduling is a best-effort nudge — never let it break app startup.
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
