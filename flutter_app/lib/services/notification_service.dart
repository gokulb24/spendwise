import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

/// Schedules on-device reminder notifications. All calls are guarded so they
/// safely no-op on unsupported platforms / in tests (no plugin channel).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // Diagnostic logging (no-op in production; flip to print when debugging).
  static void _log(String m) {}

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Reminders you set in SpendWise',
      importance: Importance.max,
      priority: Priority.high,
      // No custom icon → uses the default from init (the app launcher icon),
      // which is guaranteed to exist in the release APK.
    ),
  );

  static Future<void> init() async {
    if (_ready || !_supported) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      }
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
          settings: const InitializationSettings(android: android));
      // Explicitly create the channel so notifications are guaranteed to show.
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'reminders',
            'Reminders',
            description: 'Reminders you set in SpendWise',
            importance: Importance.max,
          ));
      _ready = true;
      _log('init OK, tz=${tz.local.name}');
    } catch (e) {
      _log('init FAILED: $e');
    }
  }

  /// Ask for notification + exact-alarm permission (Android 13+/12+).
  static Future<bool> requestPermission() async {
    if (!_supported) return false;
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      // Needed for exact reminders on Android 12+.
      await android?.requestExactAlarmsPermission();
      return granted ?? true;
    } catch (_) {
      return false;
    }
  }

  static int _idFor(String docId) => docId.hashCode & 0x7fffffff;

  /// Schedule at [when], trying the most reliable alarm type first and falling
  /// back if permission for it isn't available. `alarmClock` is treated by
  /// Android like a user alarm — exempt from Doze and most OEM battery killing.
  static Future<bool> _scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (!_ready) return false;
    const modes = [
      AndroidScheduleMode.alarmClock,
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ];
    for (final mode in modes) {
      try {
        await _plugin.zonedSchedule(
          id: id,
          scheduledDate: tz.TZDateTime.from(when, tz.local),
          notificationDetails: _details,
          androidScheduleMode: mode,
          title: title,
          body: body,
        );
        _log('scheduled id=$id at $when via $mode (tz=${tz.local.name})');
        return true;
      } catch (e) {
        _log('mode $mode FAILED for id=$id: $e');
      }
    }
    _log('ALL MODES FAILED for id=$id');
    return false;
  }

  static Future<void> schedule(Reminder r) async {
    if (!_supported) {
      _log('schedule skipped: not supported');
      return;
    }
    await init();
    if (!_ready) {
      _log('schedule skipped: not ready');
      return;
    }
    if (r.done) return;
    if (r.dateTime.isBefore(DateTime.now())) {
      _log('schedule skipped: "${r.title}" is in the past (${r.dateTime})');
      return;
    }
    await _scheduleAt(
      id: _idFor(r.id),
      when: r.dateTime,
      title: r.title.isEmpty ? 'Reminder' : r.title,
      body: r.note.isNotEmpty ? r.note : 'Tap to open SpendWise',
    );
  }

  /// Whether the app is currently allowed to show notifications at all.
  static Future<bool> areEnabled() async {
    if (!_supported) return false;
    await init();
    try {
      final a = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return (await a?.areNotificationsEnabled()) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens this app's system notification settings screen.
  static Future<void> openNotificationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (_) {}
  }

  static Future<void> cancel(String docId) async {
    if (!_supported) return;
    await init();
    try {
      await _plugin.cancel(id: _idFor(docId));
    } catch (_) {}
  }

  /// Cancel everything and re-schedule the current set of pending reminders.
  static Future<void> rescheduleAll(List<Reminder> reminders) async {
    if (!_supported) return;
    _log('rescheduleAll called with ${reminders.length} reminder(s)');
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
    for (final r in reminders) {
      await schedule(r);
    }
  }
}
