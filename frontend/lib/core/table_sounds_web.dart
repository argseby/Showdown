import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'table_sounds.dart';

/// Cues built from oscillators and short noise bursts.
class _WebTableSounds implements TableSounds {
  web.AudioContext? _ctx;

  @override
  void play(SoundCue cue) {
    try {
      final ctx = _ctx ??= web.AudioContext();
      final t0 = ctx.currentTime;
      switch (cue) {
        case SoundCue.turn:
          _tone(ctx, t0, 660, 0.12, 0.04);
          _tone(ctx, t0 + 0.18, 880, 0.12, 0.04);
        case SoundCue.deal:
          _noise(ctx, t0, 0.05, 0.05, highpass: 1800);
          _noise(ctx, t0 + 0.07, 0.05, 0.04, highpass: 1800);
        case SoundCue.check:
          _tone(ctx, t0, 140, 0.06, 0.08, type: 'triangle');
          _tone(ctx, t0 + 0.09, 120, 0.06, 0.07, type: 'triangle');
        case SoundCue.chips:
          for (var i = 0; i < 4; i++) {
            _tone(ctx, t0 + i * 0.045, 2400 + i * 300, 0.03, 0.025);
          }
        case SoundCue.win:
          for (final (i, f) in [523.0, 659.0, 784.0, 1047.0].indexed) {
            _tone(ctx, t0 + i * 0.11, f, 0.16, 0.035);
          }
        case SoundCue.alert:
          _tone(ctx, t0, 440, 0.1, 0.05, type: 'square');
          _tone(ctx, t0 + 0.14, 440, 0.1, 0.05, type: 'square');
      }
    } on Object catch (_) {
      // Audio may be blocked until the user interacted with the page.
    }
  }

  void _tone(
    web.AudioContext ctx,
    double at,
    double freq,
    double duration,
    double volume, {
    String type = 'sine',
  }) {
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = type;
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(volume, at);
    gain.gain.exponentialRampToValueAtTime(0.0001, at + duration);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(at);
    osc.stop(at + duration + 0.02);
  }

  void _noise(
    web.AudioContext ctx,
    double at,
    double duration,
    double volume, {
    double highpass = 1000,
  }) {
    final rate = ctx.sampleRate;
    final frames = (rate * duration).round();
    final buffer = ctx.createBuffer(1, frames, rate);
    final data = Float32List(frames);
    final rng = math.Random(7);
    for (var i = 0; i < frames; i++) {
      // Fast decay so it reads as a card snap rather than static.
      data[i] = (rng.nextDouble() * 2 - 1) * (1 - i / frames);
    }
    buffer.copyToChannel(data.toJS, 0);
    final src = ctx.createBufferSource()..buffer = buffer;
    final filter = ctx.createBiquadFilter()
      ..type = 'highpass'
      ..frequency.value = highpass;
    final gain = ctx.createGain()..gain.value = volume;
    src.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);
    src.start(at);
  }
}

TableSounds createTableSounds() => _WebTableSounds();
