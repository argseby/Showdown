import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'turn_notifier.dart';

class _WebTurnNotifier implements TurnNotifier {
  web.Notification? _last;

  @override
  bool get supported => (web.window as JSObject).has('Notification');

  @override
  String get permission => supported ? web.Notification.permission : 'denied';

  @override
  Future<bool> requestPermission() async {
    if (!supported) return false;
    try {
      final result = await web.Notification.requestPermission().toDart;
      return result.toDart == 'granted';
    } on Object catch (_) {
      return false;
    }
  }

  @override
  void notify(String title, String body) {
    if (!supported || web.Notification.permission != 'granted') return;
    try {
      _last?.close();
      _last = web.Notification(
        title,
        web.NotificationOptions(body: body, tag: 'showdown-turn'),
      );
      _last!.onclick = ((web.Event _) {
        web.window.focus();
        _last?.close();
      }).toJS;
    } on Object catch (_) {
      // Some browsers only allow notifications from a service worker.
    }
  }

  @override
  void vibrate() {
    try {
      web.window.navigator.vibrate([120.toJS, 60.toJS, 120.toJS].toJS);
    } on Object catch (_) {
      // No vibration support: fine.
    }
  }
}

TurnNotifier createTurnNotifier() => _WebTurnNotifier();
