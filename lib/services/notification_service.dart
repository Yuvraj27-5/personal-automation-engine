// Stub notification service — web compatible
class NotificationService {
  static Future<void> initialize() async {}

  static Future<void> show({
    required String title,
    required String body,
    int id = 0,
  }) async {
    // No-op on web. On mobile, use flutter_local_notifications
    print('[Notification] $title: $body');
  }

  static Future<void> cancel(int id) async {}
  static Future<void> cancelAll() async {}
}
