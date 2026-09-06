import 'table_sounds_stub.dart'
    if (dart.library.js_interop) 'table_sounds_web.dart'
    as impl;

/// The short cues the table plays.
enum SoundCue { turn, deal, check, chips, win, alert }

/// Table sounds synthesised with the Web Audio API (no audio assets, no
/// network). Other platforms are silent until they get an implementation.
abstract class TableSounds {
  void play(SoundCue cue);

  static TableSounds create() => impl.createTableSounds();
}
