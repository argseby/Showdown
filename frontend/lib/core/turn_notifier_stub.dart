import 'turn_notifier.dart';

class _NoTurnNotifier implements TurnNotifier {
  @override
  bool get supported => false;
  @override
  Future<bool> requestPermission() async => false;
  @override
  void notify(String title, String body) {}
  @override
  void vibrate() {}
}

TurnNotifier createTurnNotifier() => _NoTurnNotifier();
