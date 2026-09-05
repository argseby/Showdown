import 'turn_sound_stub.dart'
    if (dart.library.js_interop) 'turn_sound_web.dart'
    as impl;

/// A short cue played when it becomes the player's turn. The web build uses
/// the Web Audio API (no audio assets, no network); other platforms are
/// silent until they get their own implementation.
abstract class TurnSound {
  void play();

  static TurnSound create() => impl.createTurnSound();
}
