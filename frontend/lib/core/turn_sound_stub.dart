import 'turn_sound.dart';

class _SilentTurnSound implements TurnSound {
  @override
  void play() {}
}

TurnSound createTurnSound() => _SilentTurnSound();
