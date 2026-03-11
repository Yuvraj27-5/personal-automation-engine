import 'dart:convert';
import '../data/models/rule_model.dart';

class JsonExportService {
  static String exportRules(List<RuleModel> rules) {
    final data = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'ruleCount': rules.length,
      'rules': rules.map((r) => r.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static List<RuleModel> importRules(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final rulesJson = data['rules'] as List? ?? [];
    return rulesJson
        .map((r) => RuleModel.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  // Web stub — on mobile these would use share_plus and file_picker
  static Future<void> exportAndShare(List<RuleModel> rules) async {
    final json = exportRules(rules);
    print('[Export] $json');
  }

  static Future<List<RuleModel>?> importFromFile() async {
    return null;
  }
}
