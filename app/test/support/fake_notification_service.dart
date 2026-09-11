import 'package:fieldtally/data/notifications/notification_service.dart';

/// A posted notification, as the fake saw it.
class PostedNotification {
  const PostedNotification({
    required this.id,
    required this.title,
    required this.body,
    this.at,
  });

  final int id;
  final String title;
  final String body;

  /// Set for a scheduled reminder, null for one posted immediately.
  final DateTime? at;
}

/// Stands in for the platform channel in tests.
///
/// Records rather than asserts: what matters about §3.7 is which notifications
/// are posted, when they are due and how they read, and every test wants to
/// look at a different part of that.
class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.permissionGranted = true});

  /// What Android answers when asked.
  bool permissionGranted;

  final shown = <PostedNotification>[];
  final scheduled = <PostedNotification>[];
  int cancels = 0;
  int permissionRequests = 0;

  @override
  Future<bool> ensurePermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    shown.add(PostedNotification(id: id, title: title, body: body));
  }

  @override
  Future<void> scheduleReminder({
    required DateTime at,
    required String title,
    required String body,
  }) async {
    scheduled.add(
      PostedNotification(
        id: PluginNotificationService.reminderId,
        title: title,
        body: body,
        at: at,
      ),
    );
  }

  @override
  Future<void> cancelReminder() async => cancels++;
}
