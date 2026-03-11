import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDateTime(DateTime dt) =>
      DateFormat('MMM dd, yyyy • hh:mm a').format(dt);

  static String formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);

  static String formatDate(DateTime dt) => DateFormat('MMM dd, yyyy').format(dt);

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(dt);
  }

  static String formatDuration(int ms) {
    if (ms < 1000) return '${ms}ms';
    if (ms < 60000) return '${(ms / 1000).toStringAsFixed(1)}s';
    return '${(ms / 60000).toStringAsFixed(1)}m';
  }

  static bool isTimeInRange(String startTime, String endTime) {
    final now = DateTime.now();
    final parts = (t) => t.split(':').map(int.parse).toList();
    final s = parts(startTime);
    final e = parts(endTime);
    final start = DateTime(now.year, now.month, now.day, s[0], s[1]);
    final end = DateTime(now.year, now.month, now.day, e[0], e[1]);
    return now.isAfter(start) && now.isBefore(end);
  }

  static bool isCurrentDayIn(List<String> days) {
    const map = {
      1: 'Monday', 2: 'Tuesday', 3: 'Wednesday',
      4: 'Thursday', 5: 'Friday', 6: 'Saturday', 7: 'Sunday'
    };
    return days.contains(map[DateTime.now().weekday]);
  }
}
