import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local notifications (§3.7).
///
/// Behind an interface because everything below is a platform channel: no
/// widget test can schedule a real alarm, and the decisions about *when* and
/// *what* to notify live in the domain where they can be tested.
abstract interface class NotificationService {
  /// Asks for permission if the platform needs it. Returns whether
  /// notifications may be posted.
  Future<bool> ensurePermission();

  /// Posts immediately.
  Future<void> show({
    required int id,
    required String title,
    required String body,
  });

  /// Replaces any pending reminder with one due at [at].
  Future<void> scheduleReminder({
    required DateTime at,
    required String title,
    required String body,
  });

  /// Drops the pending reminder, leaving anything already posted alone.
  Future<void> cancelReminder();
}

/// Implementation backed by `flutter_local_notifications`.
class PluginNotificationService implements NotificationService {
  PluginNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  /// Fixed ids: a reminder replaces the previous reminder rather than stacking,
  /// and a milestone is keyed by its own id so several can coexist.
  static const reminderId = 1;
  static const milestoneBaseId = 1000;

  static const _channelId = 'fieldtally';

  Future<void> _initialise() async {
    if (_ready) return;

    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> ensurePermission() async {
    await _initialise();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;

    // Android 13 and later ask; earlier versions grant it at install time and
    // return null here, which is not a refusal.
    return await android.requestNotificationsPermission() ?? true;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'FieldTally',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await _initialise();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  @override
  Future<void> scheduleReminder({
    required DateTime at,
    required String title,
    required String body,
  }) async {
    await _initialise();
    await cancelReminder();

    await _plugin.zonedSchedule(
      id: reminderId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: _details,
      // Inexact on purpose: an exact alarm needs a separate, intrusive
      // permission on Android 12+, and a nudge about recording stats does not
      // need to land on the minute.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelReminder() async {
    await _initialise();
    await _plugin.cancel(id: reminderId);
  }
}
