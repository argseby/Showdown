import 'table_sounds.dart';

class _SilentTableSounds implements TableSounds {
  @override
  void play(SoundCue cue) {}
}

TableSounds createTableSounds() => _SilentTableSounds();
