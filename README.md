# ⚡ Personal Automation Engine

A powerful, extensible personal automation app built with Flutter. Create smart automation rules that react to triggers, evaluate conditions, and execute actions — automatically.

---

## 📱 Screenshots

> Run the app to see the stunning dark glassmorphism UI in action!

---

## 🚀 Features

### Core Features
- ✅ **Rule Management** — Create, edit, enable/disable, and delete automation rules
- ✅ **6 Trigger Types** — Time, App Open, Manual, Battery, Connectivity, Interval
- ✅ **3 Condition Types** — Time Range, Day of Week, Counter (with AND/OR chaining)
- ✅ **6 Action Types** — Notification, Log, Display Message, Sound, Clipboard, Webhook
- ✅ **Rule Priority System** — High / Medium / Low with priority queue execution

### Optional Enhancements (All Implemented!)
- ✅ **Rule Execution Logs** — Full execution history with timeline view
- ✅ **Rule Priority System** — Priority queue ensures high-priority rules run first
- ✅ **Conflict Detection** — Warns when rules have overlapping triggers and actions
- ✅ **JSON Export/Import** — Share rules as `.json` files across devices
- ✅ **Sandbox Mode** — Test rules safely without executing real actions
- ✅ **Performance Monitoring** — Tracks execution time (ms) per rule

### WOW Features
- 🎨 **Glassmorphism UI** — Stunning dark theme with gradient cards
- 🔗 **AND/OR Condition Chaining** — Complex multi-condition logic
- 📊 **Analytics Dashboard** — Bar charts for daily executions + per-rule stats
- 🔍 **Search & Filter** — Search rules by name, filter by enabled/disabled
- 🔄 **Background Execution** — Rules run in background via WorkManager

---

## 🏗️ Architecture

```
personal_automation_engine/
│
├── lib/
│   ├── main.dart                        # App entry point + lifecycle
│   │
│   ├── core/                            # Shared utilities
│   │   ├── constants/app_constants.dart # Trigger/condition/action type IDs
│   │   ├── theme/app_theme.dart         # Glassmorphism dark theme
│   │   └── utils/
│   │       ├── date_utils.dart          # Date formatting helpers
│   │       └── conflict_detector.dart   # Rule conflict detection logic
│   │
│   ├── data/                            # Data layer
│   │   ├── models/                      # Pure Dart data models (toJson/fromJson)
│   │   │   ├── rule_model.dart
│   │   │   ├── trigger_model.dart
│   │   │   ├── condition_model.dart     # Includes AND/OR operator
│   │   │   ├── action_model.dart
│   │   │   └── log_model.dart           # Includes durationMs, isSandbox
│   │   ├── local/
│   │   │   ├── database_helper.dart     # Hive initialization
│   │   │   └── rule_dao.dart            # All CRUD operations
│   │   └── repositories/
│   │       └── rule_repository.dart     # Repository pattern abstraction
│   │
│   ├── engine/                          # 🧠 Automation Engine
│   │   ├── automation_engine.dart       # Priority queue evaluator + executor
│   │   ├── triggers/
│   │   │   ├── base_trigger.dart        # Abstract class
│   │   │   └── triggers.dart            # All 6 trigger implementations
│   │   ├── conditions/
│   │   │   ├── base_condition.dart      # Abstract class
│   │   │   ├── conditions.dart          # All 3 condition implementations
│   │   │   └── condition_evaluator.dart # AND/OR chaining logic
│   │   └── actions/
│   │       ├── base_action.dart         # Abstract class
│   │       └── actions.dart             # All 6 action implementations
│   │
│   ├── services/
│   │   ├── notification_service.dart    # Local notifications
│   │   ├── background_service.dart      # WorkManager background tasks
│   │   ├── json_export_service.dart     # JSON import/export
│   │   └── analytics_service.dart      # Performance stats computation
│   │
│   ├── providers/
│   │   └── providers.dart              # All Riverpod state providers
│   │
│   └── ui/
│       ├── screens/
│       │   ├── home_screen.dart         # Rules list + stats overview
│       │   ├── create_rule_screen.dart  # 4-step wizard to create/edit rules
│       │   ├── logs_screen.dart         # Execution history timeline
│       │   ├── analytics_screen.dart    # Charts + performance monitoring
│       │   └── sandbox_screen.dart      # Safe rule testing mode
│       └── widgets/
│           ├── glass_card.dart          # Glassmorphism card widget
│           └── rule_card.dart           # Animated rule list item
```

---

## 🧠 Engine Design

### Rule Evaluation Flow

```
User Opens App / Background Trigger Fires
         │
         ▼
  Find all ENABLED rules
  with matching trigger type
         │
         ▼
  Sort by PRIORITY (High → Low)
         │
         ▼
  For each rule:
    1. Check trigger.shouldFire()
    2. Evaluate conditions with AND/OR chaining
    3. Execute all actions sequentially
    4. Log result with duration (ms)
         │
         ▼
  Update UI + Execution Count
```

### Condition AND/OR Chaining

```
Condition 1 [operator: AND] ──┐
Condition 2 [operator: OR]  ──┼──► Result
Condition 3                 ──┘

Evaluation: ((C1 AND C2) OR C3)
```

### Conflict Detection Algorithm

Two rules conflict if they:
1. Share the same trigger type
2. AND have identical trigger parameters (exact collision)
3. OR share the same trigger type AND same action types (functional overlap)

---

## ⚙️ Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Android Setup

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- WorkManager background tasks -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>

<!-- Notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Battery -->
<uses-permission android:name="android.permission.BATTERY_STATS"/>

<!-- Network -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- Inside <application> tag -->
<service
    android:name="be.tramckrijte.workmanager.BackgroundWorker"
    android:permission="android.permission.BIND_JOB_SERVICE"
    android:exported="true" />
```

### 3. iOS Setup

Add to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>
<key>NSUserNotificationUsageDescription</key>
<string>Automation Engine uses notifications to alert you when rules execute.</string>
```

### 4. Run the App

```bash
flutter run
```

---

## 🎯 Trigger Types

| Trigger | Description | Parameters |
|---|---|---|
| ⏰ Time | Fires at a specific daily time | `time: "HH:MM"` |
| 📱 App Open | Fires every app launch | none |
| 🔘 Manual | User taps Run button | none |
| 🔋 Battery | Fires at battery threshold | `threshold: int, direction: above/below` |
| 📶 Connectivity | WiFi connect/disconnect | `state: connected/disconnected` |
| ⏱️ Interval | Fires every N minutes | `intervalMinutes: int` |

---

## 🔧 Action Types

| Action | Description | Parameters |
|---|---|---|
| 🔔 Notification | Local push notification | `title, body` |
| 📝 Log | Write to execution log | `message` |
| 💬 Display Message | In-app snackbar | `message` |
| 🔊 Sound | Device haptic/sound | `sound: alert/success/warning` |
| 📋 Clipboard | Copy text to clipboard | `text` |
| 🌐 Webhook | HTTP GET/POST request | `url, method` |

---

## 📊 Performance Monitoring

Every rule execution tracks:
- **Duration (ms)** — How long the rule took to evaluate and execute
- **Success/Failure** — Whether all actions completed without errors
- **Actions Executed** — Which actions ran and their output messages

View these in the **Analytics** tab with 7-day bar charts and per-rule stats.

---

## 🏛️ Design Decisions

1. **Hive with JSON strings** — Chose simple `Box<String>` over typed Hive adapters to avoid code generation, making the project easier to build and extend.

2. **Riverpod for state** — `StateNotifier` + `Provider` pattern gives clean separation between UI and business logic.

3. **Clean Architecture layers** — Data → Repository → Engine → Provider → UI. Each layer only knows about the layer below it.

4. **Extensibility** — Adding a new trigger/condition/action only requires:
   - Creating a class extending `BaseTrigger`/`BaseCondition`/`BaseAction`
   - Adding a case in `AutomationEngine`'s factory methods
   - Adding the type string to `AppConstants`

5. **AND/OR chaining** — The `operator` field on `ConditionModel` determines how each condition joins with the next one, enabling complex logic like `(C1 AND C2) OR C3`.

---

## 👨‍💻 Author

Built as a college club assignment submission.

**Technology:** Flutter (Dart)  
**Storage:** Hive  
**State Management:** Riverpod  
**Background Tasks:** WorkManager  
**Charts:** fl_chart
