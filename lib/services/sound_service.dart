// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class SoundService {
  static void playSound(String type) {
    try {
      final script = _buildScript(type);
      js.context.callMethod('eval', [script]);
    } catch (_) {}
  }

  static String _buildScript(String type) {
    switch (type) {
      case 'alert':
        // Sharp descending beep
        return '''
(function() {
  var ctx = new (window.AudioContext || window.webkitAudioContext)();
  function beep(freq, start, dur) {
    var o = ctx.createOscillator();
    var g = ctx.createGain();
    o.connect(g); g.connect(ctx.destination);
    o.type = 'square';
    o.frequency.setValueAtTime(freq, ctx.currentTime + start);
    g.gain.setValueAtTime(0.3, ctx.currentTime + start);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + start + dur);
    o.start(ctx.currentTime + start);
    o.stop(ctx.currentTime + start + dur);
  }
  beep(880, 0, 0.12);
  beep(660, 0.15, 0.12);
  beep(440, 0.30, 0.18);
})();
''';
      case 'success':
        // Happy ascending chime
        return '''
(function() {
  var ctx = new (window.AudioContext || window.webkitAudioContext)();
  function note(freq, start, dur) {
    var o = ctx.createOscillator();
    var g = ctx.createGain();
    o.connect(g); g.connect(ctx.destination);
    o.type = 'sine';
    o.frequency.setValueAtTime(freq, ctx.currentTime + start);
    g.gain.setValueAtTime(0.35, ctx.currentTime + start);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + start + dur);
    o.start(ctx.currentTime + start);
    o.stop(ctx.currentTime + start + dur);
  }
  note(523.25, 0, 0.18);
  note(659.25, 0.12, 0.18);
  note(783.99, 0.24, 0.18);
  note(1046.5, 0.36, 0.35);
})();
''';
      case 'warning':
        // Pulsing warning tone
        return '''
(function() {
  var ctx = new (window.AudioContext || window.webkitAudioContext)();
  function pulse(start) {
    var o = ctx.createOscillator();
    var g = ctx.createGain();
    o.connect(g); g.connect(ctx.destination);
    o.type = 'triangle';
    o.frequency.setValueAtTime(600, ctx.currentTime + start);
    o.frequency.linearRampToValueAtTime(400, ctx.currentTime + start + 0.15);
    g.gain.setValueAtTime(0.4, ctx.currentTime + start);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + start + 0.18);
    o.start(ctx.currentTime + start);
    o.stop(ctx.currentTime + start + 0.2);
  }
  pulse(0); pulse(0.22); pulse(0.44);
})();
''';
      case 'notification':
        return '''
(function() {
  var ctx = new (window.AudioContext || window.webkitAudioContext)();
  var o = ctx.createOscillator();
  var g = ctx.createGain();
  o.connect(g); g.connect(ctx.destination);
  o.type = 'sine';
  o.frequency.setValueAtTime(659.25, ctx.currentTime);
  o.frequency.exponentialRampToValueAtTime(987.77, ctx.currentTime + 0.3);
  g.gain.setValueAtTime(0.35, ctx.currentTime);
  g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.4);
  o.start(ctx.currentTime);
  o.stop(ctx.currentTime + 0.4);
})();
''';
      case 'chime':
        return '''
(function() {
  var ctx = new (window.AudioContext || window.webkitAudioContext)();
  [523.25, 659.25, 783.99, 1046.5].forEach(function(f, i) {
    var o = ctx.createOscillator();
    var g = ctx.createGain();
    o.connect(g); g.connect(ctx.destination);
    o.type = 'sine';
    o.frequency.value = f;
    g.gain.setValueAtTime(0.3, ctx.currentTime + i * 0.1);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + i * 0.1 + 0.5);
    o.start(ctx.currentTime + i * 0.1);
    o.stop(ctx.currentTime + i * 0.1 + 0.6);
  });
})();
''';
      case 'error':
      default:
        return '''
(function() {
  var ctx = new (window.AudioContext || window.webkitAudioContext)();
  var o = ctx.createOscillator();
  var g = ctx.createGain();
  o.connect(g); g.connect(ctx.destination);
  o.type = 'sawtooth';
  o.frequency.setValueAtTime(300, ctx.currentTime);
  o.frequency.exponentialRampToValueAtTime(150, ctx.currentTime + 0.4);
  g.gain.setValueAtTime(0.4, ctx.currentTime);
  g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5);
  o.start(ctx.currentTime);
  o.stop(ctx.currentTime + 0.5);
})();
''';
    }
  }
}