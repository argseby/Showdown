import 'package:web/web.dart' as web;

import 'turn_sound.dart';

/// Two short sine beeps generated with the Web Audio API.
class _WebTurnSound implements TurnSound {
  web.AudioContext? _ctx;

  @override
  void play() {
    try {
      final ctx = _ctx ??= web.AudioContext();
      final t0 = ctx.currentTime;
      for (final (offset, freq) in [(0.0, 660.0), (0.18, 880.0)]) {
        final osc = ctx.createOscillator();
        final gain = ctx.createGain();
        osc.frequency.value = freq;
        gain.gain.value = 0.04;
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(t0 + offset);
        osc.stop(t0 + offset + 0.12);
      }
    } on Object catch (_) {
      // Audio may be blocked until the user interacted with the page.
    }
  }
}

TurnSound createTurnSound() => _WebTurnSound();
