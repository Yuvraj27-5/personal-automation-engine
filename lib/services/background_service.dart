// Background service is only supported on Android/iOS
// Web-safe stub — does nothing on Chrome

class BackgroundService {
  static Future<void> initialize() async {}
  static Future<void> registerPeriodicTasks() async {}
  static Future<void> cancelAll() async {}
}
