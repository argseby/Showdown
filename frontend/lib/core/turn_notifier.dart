import 'turn_notifier_stub.dart'
    if (dart.library.js_interop) 'turn_notifier_web.dart'
    as impl;

/// System notification (and a short vibration on phones) when it is the
/// player's turn while the tab is in the background. Uses the browser's
/// Notification API directly; nothing goes through the server.
abstract class TurnNotifier {
  /// False when the platform has no notifications at all.
  bool get supported;

  /// Asks for permission; true when notifications may be shown.
  Future<bool> requestPermission();

  /// Shows a notification (replacing an earlier one with the same tag).
  void notify(String title, String body);

  void vibrate();

  static TurnNotifier create() => impl.createTurnNotifier();
}
