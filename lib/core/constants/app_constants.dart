class AppConstants {
  // ── Trigger Types ────────────────────────────────────────
  static const String triggerTime = 'time';
  static const String triggerAppOpen = 'app_open';
  static const String triggerManual = 'manual';
  static const String triggerBattery = 'battery';
  static const String triggerConnectivity = 'connectivity';
  static const String triggerInterval = 'interval';

  static const List<String> allTriggerTypes = [
    triggerTime,
    triggerAppOpen,
    triggerManual,
    triggerBattery,
    triggerConnectivity,
    triggerInterval,
  ];

  static const Map<String, String> triggerLabels = {
    triggerTime: '⏰ Time Trigger',
    triggerAppOpen: '📱 App Open',
    triggerManual: '🔘 Manual',
    triggerBattery: '🔋 Battery Level',
    triggerConnectivity: '📶 Connectivity',
    triggerInterval: '⏱️ Interval',
  };

  static const Map<String, String> triggerDescriptions = {
    triggerTime: 'Fires at a specific time every day',
    triggerAppOpen: 'Fires every time the app is opened',
    triggerManual: 'Fires when user taps Run button',
    triggerBattery: 'Fires when battery drops below a threshold',
    triggerConnectivity: 'Fires when WiFi connects or disconnects',
    triggerInterval: 'Fires every X minutes/hours',
  };

  // ── Condition Types ──────────────────────────────────────
  static const String conditionTimeRange = 'time_range';
  static const String conditionDayOfWeek = 'day_of_week';
  static const String conditionCounter = 'counter';

  static const List<String> allConditionTypes = [
    conditionTimeRange,
    conditionDayOfWeek,
    conditionCounter,
  ];

  static const Map<String, String> conditionLabels = {
    conditionTimeRange: '🕐 Time Range',
    conditionDayOfWeek: '📅 Day of Week',
    conditionCounter: '🔢 Counter',
  };

  // ── Action Types ─────────────────────────────────────────
  static const String actionNotification = 'notification';
  static const String actionLog = 'log';
  static const String actionDisplayMessage = 'display_message';
  static const String actionSound = 'sound';
  static const String actionClipboard = 'clipboard';
  static const String actionWebhook = 'webhook';

  static const List<String> allActionTypes = [
    actionNotification,
    actionLog,
    actionDisplayMessage,
    actionSound,
    actionClipboard,
    actionWebhook,
  ];

  static const Map<String, String> actionLabels = {
    actionNotification: '🔔 Send Notification',
    actionLog: '📝 Log Entry',
    actionDisplayMessage: '💬 Show Message',
    actionSound: '🔊 Play Sound',
    actionClipboard: '📋 Copy to Clipboard',
    actionWebhook: '🌐 Call Webhook',
  };

  // ── Priority ─────────────────────────────────────────────
  static const int priorityHigh = 1;
  static const int priorityMedium = 2;
  static const int priorityLow = 3;

  static const Map<int, String> priorityLabels = {
    1: 'High',
    2: 'Medium',
    3: 'Low',
  };

  // ── Condition Operators ──────────────────────────────────
  static const String operatorAnd = 'AND';
  static const String operatorOr = 'OR';

  // ── Hive Box Names ───────────────────────────────────────
  static const String rulesBox = 'rules_box';
  static const String logsBox = 'logs_box';
  static const String settingsBox = 'settings_box';

  // ── Days ─────────────────────────────────────────────────
  static const List<String> weekdays = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
}
