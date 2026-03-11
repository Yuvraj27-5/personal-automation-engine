import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(AppConstants.rulesBox);
    await Hive.openBox<String>(AppConstants.logsBox);
    await Hive.openBox<String>(AppConstants.settingsBox);
  }

  static Box<String> get rulesBox =>
      Hive.box<String>(AppConstants.rulesBox);

  static Box<String> get logsBox =>
      Hive.box<String>(AppConstants.logsBox);

  static Box<String> get settingsBox =>
      Hive.box<String>(AppConstants.settingsBox);
}
