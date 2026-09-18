import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pad_reader_stub.dart'
    if (dart.library.js_interop) 'pad_reader_web.dart';

/// The buttons of a controller in the standard layout of the Gamepad API
/// (Xbox names; the index is the button index of that layout).
enum PadButton {
  a,
  b,
  x,
  y,
  lb,
  rb,
  lt,
  rt,
  back,
  start,
  l3,
  r3,
  up,
  down,
  left,
  right;

  /// Directions repeat while held (stepping an amount, moving focus).
  bool get repeats => index >= PadButton.up.index;

  /// The label on the button, for hints.
  String get label => switch (this) {
    PadButton.a => 'A',
    PadButton.b => 'B',
    PadButton.x => 'X',
    PadButton.y => 'Y',
    PadButton.lb => 'LB',
    PadButton.rb => 'RB',
    PadButton.lt => 'LT',
    PadButton.rt => 'RT',
    PadButton.back => 'Back',
    PadButton.start => 'Start',
    PadButton.l3 => 'L3',
    PadButton.r3 => 'R3',
    PadButton.up => '↑',
    PadButton.down => '↓',
    PadButton.left => '←',
    PadButton.right => '→',
  };
}

/// One reading of the first connected controller: which buttons are down
/// (by standard index) and the axes (left stick first, -1..1).
class PadFrame {
  const PadFrame({required this.pressed, this.axes = const []});

  final List<bool> pressed;
  final List<double> axes;
}

/// Reads the current frame, or null while no controller is connected.
typedef PadReader = PadFrame? Function();

/// Polls a [PadReader] and turns the frames into button presses: one per
/// press, and for the directions a repeat while held. The left stick counts
/// as the directions too (with hysteresis so that it does not flutter).
class GamepadPoller {
  GamepadPoller({
    required this.read,
    this.interval = const Duration(milliseconds: 16),
  });

  final PadReader read;
  final Duration interval;

  static const repeatDelay = Duration(milliseconds: 400);
  static const repeatEvery = Duration(milliseconds: 120);
  static const _stickOn = 0.6;
  static const _stickOff = 0.4;

  /// Whether a controller is connected (the last frame was not null).
  final connected = ValueNotifier<bool>(false);

  final _presses = StreamController<PadButton>.broadcast();
  Stream<PadButton> get presses => _presses.stream;

  Timer? _timer;
  final _clock = Stopwatch();
  List<bool> _down = List.filled(PadButton.values.length, false);
  final _heldSince = <PadButton, Duration>{};
  final _lastRepeat = <PadButton, Duration>{};

  void start() {
    if (_timer != null) return;
    _clock.start();
    _timer = Timer.periodic(interval, (_) => step(read(), _clock.elapsed));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _presses.close();
    connected.dispose();
  }

  /// Consumes one frame at time [now] and reports the presses it produced.
  List<PadButton> step(PadFrame? frame, Duration now) {
    connected.value = frame != null;
    final next = List.filled(PadButton.values.length, false);
    if (frame != null) {
      for (final b in PadButton.values) {
        if (b.index < frame.pressed.length && frame.pressed[b.index]) {
          next[b.index] = true;
        }
      }
      double axis(int i) => i < frame.axes.length ? frame.axes[i] : 0;
      void stick(PadButton b, double v) {
        if (v > _stickOn || (_down[b.index] && v > _stickOff)) {
          next[b.index] = true;
        }
      }

      stick(PadButton.right, axis(0));
      stick(PadButton.left, -axis(0));
      stick(PadButton.down, axis(1));
      stick(PadButton.up, -axis(1));
    }
    final out = <PadButton>[];
    for (final b in PadButton.values) {
      final i = b.index;
      if (next[i] && !_down[i]) {
        out.add(b);
        _heldSince[b] = now;
        _lastRepeat[b] = now;
      } else if (next[i] && b.repeats) {
        if (now - _heldSince[b]! >= repeatDelay &&
            now - _lastRepeat[b]! >= repeatEvery) {
          out.add(b);
          _lastRepeat[b] = now;
        }
      }
    }
    _down = next;
    for (final b in out) {
      _presses.add(b);
    }
    return out;
  }
}

/// Whether a controller is connected; the notifier also hands out the
/// presses. Polling starts with [start] (the table screen does that) and
/// only where the platform has a Gamepad API.
class GamepadNotifier extends Notifier<bool> {
  /// Tests: a fake reader instead of the platform's.
  static PadReader? readerOverride;

  GamepadPoller? _poller;

  @override
  bool build() {
    ref.onDispose(() => _poller?.dispose());
    return false;
  }

  /// Begins polling (idempotent).
  void start() {
    if (_poller != null) return;
    final read = readerOverride ?? (padSupported ? readPad : null);
    if (read == null) return;
    final poller = GamepadPoller(read: read);
    _poller = poller;
    poller.connected.addListener(() {
      state = poller.connected.value;
      // With a controller the focused control must be visible, as with a
      // keyboard; a touch would otherwise hide the ring.
      FocusManager.instance.highlightStrategy = state
          ? FocusHighlightStrategy.alwaysTraditional
          : FocusHighlightStrategy.automatic;
    });
    poller.start();
  }

  /// The button presses, once polling has started.
  Stream<PadButton> get presses =>
      _poller?.presses ?? const Stream<PadButton>.empty();
}

final gamepadProvider = NotifierProvider<GamepadNotifier, bool>(
  GamepadNotifier.new,
);
