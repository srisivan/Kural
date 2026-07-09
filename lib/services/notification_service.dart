import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int dailyKuralNotificationId = 100;

  // Daily reminder time (device-local).
  static const int _hour = 8;
  static const int _minute = 5;

  Future<void> init() async {
    // Loads the tz database so zonedSchedule can work. We schedule using
    // absolute UTC instants derived from device-local time (below), so we
    // don't need to resolve the device's IANA zone / set tz.local.
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
    // Dart's DateTime is already in device-local time. Compute the next
    // occurrence of _hour:_minute locally, then convert to an absolute UTC
    // instant. Scheduling the exact instant makes it fire at the right
    // wall-clock time even though tz.local isn't configured — the earlier
    // bug was scheduling "08:05" against tz.local, which defaults to UTC.
    final nowLocal = DateTime.now();
    var whenLocal =
        DateTime(nowLocal.year, nowLocal.month, nowLocal.day, _hour, _minute);
    if (!whenLocal.isAfter(nowLocal)) {
      whenLocal = whenLocal.add(const Duration(days: 1));
    }
    final scheduled = tz.TZDateTime.from(whenLocal.toUtc(), tz.UTC);

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
