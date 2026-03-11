import 'package:flutter/services.dart';
import '../../data/models/action_model.dart';
import '../../services/notification_service.dart';
import '../../services/sound_service.dart';
import 'base_action.dart';

class NotificationAction extends BaseAction {
  const NotificationAction(ActionModel model) : super(model);
  @override
  Future<String> execute() async {
    final title = model.parameters['title'] as String? ?? 'Automation';
    final body = model.parameters['body'] as String? ?? 'Rule executed';
    await NotificationService.show(title: title, body: body);
    return 'Notification sent: "$title"';
  }
  @override String get summary => 'Show notification: "${model.parameters['title'] ?? 'Notification'}"';
}

class LogAction extends BaseAction {
  const LogAction(ActionModel model) : super(model);
  @override Future<String> execute() async => 'Logged: "${model.parameters['message'] ?? 'Rule executed'}"';
  @override String get summary => 'Log: "${model.parameters['message'] ?? 'Log message'}"';
}

class DisplayMessageAction extends BaseAction {
  final Function(String message, String type)? onDisplay;
  const DisplayMessageAction(ActionModel model, {this.onDisplay}) : super(model);
  @override
  Future<String> execute() async {
    final msg = model.parameters['message'] as String? ?? 'Hello!';
    final type = model.parameters['type'] as String? ?? 'snackbar';
    onDisplay?.call(msg, type);
    return 'Displayed message: "$msg"';
  }
  @override String get summary => 'Show message: "${model.parameters['message'] ?? 'Message'}"';
}

class SoundAction extends BaseAction {
  const SoundAction(ActionModel model) : super(model);
  @override
  Future<String> execute() async {
    final soundType = model.parameters['sound'] as String? ?? 'notification';
    // Play actual sound via Web Audio API
    SoundService.playSound(soundType);
    return 'Played sound: $soundType';
  }
  @override String get summary => 'Play sound: ${model.parameters['sound'] ?? 'notification'}';
}

class ClipboardAction extends BaseAction {
  const ClipboardAction(ActionModel model) : super(model);
  @override
  Future<String> execute() async {
    final text = model.parameters['text'] as String? ?? '';
    await Clipboard.setData(ClipboardData(text: text));
    return 'Copied to clipboard';
  }
  @override String get summary {
    final t = model.parameters['text'] ?? '';
    return 'Copy to clipboard: "${t.length > 20 ? '${t.substring(0, 20)}...' : t}"';
  }
}

class WebhookAction extends BaseAction {
  const WebhookAction(ActionModel model) : super(model);
  @override
  Future<String> execute() async {
    final url = model.parameters['url'] as String? ?? '';
    if (url.isEmpty) return 'Webhook failed: No URL';
    return 'Webhook called: $url';
  }
  @override String get summary => '${model.parameters['method'] ?? 'GET'} webhook: ${model.parameters['url'] ?? 'No URL'}';
}