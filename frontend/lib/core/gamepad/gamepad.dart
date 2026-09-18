import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pad_reader_stub.dart'
    if (dart.library.js_interop) 'pad_reader_web.dart';

export 'pad_reader_stub.dart'
    if (dart.library.js_interop) 'pad_reader_web.dart'
    show reportPadDebug;

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
  const PadFrame({
    required this.pressed,
    this.axes = const [],
    this.id = '',
    this.standard = true,
  });

  final List<bool> pressed;
  final List<double> axes;

  /// The browser's name for the pad, for the diagnostics line.
  final String id;

  /// Whether the browser applied the standard layout; false after
  /// [remapNonStandard].
  final bool standard;
}

/// A pad the browser did not map to the standard layout (Firefox on
/// Linux, some Chromium builds with the xpad driver): the buttons come in
/// the raw order A B X Y LB RB Back Start Guide L3 R3, the triggers as
/// axes 2 and 5 (-1 idle) and the D-pad as a hat on axes 6 and 7.
/// Rearranged into the standard order so the rest need not know.
PadFrame remapNonStandard(PadFrame raw) {
  bool down(int i) => i < raw.pressed.length && raw.pressed[i];
  double axis(int i) => i < raw.axes.length ? raw.axes[i] : 0;
  final hatX = axis(6);
  final hatY = axis(7);
  return PadFrame(
    pressed: [
      down(0),
      down(1),
      down(2),
      down(3),
      down(4),
      down(5),
      axis(2) > 0 || down(6) && raw.pressed.length > 11,
      axis(5) > 0 || down(7) && raw.pressed.length > 11,
      raw.pressed.length > 11 ? down(8) : down(6),
      raw.pressed.length > 11 ? down(9) : down(7),
      raw.pressed.length > 11 ? down(10) : down(9),
      raw.pressed.length > 11 ? down(11) : down(10),
      hatY < -0.5 || down(12),
      hatY > 0.5 || down(13),
      hatX < -0.5 || down(14),
      hatX > 0.5 || down(15),
    ],
    axes: [axis(0), axis(1)],
    id: raw.id,
    standard: false,
  );
}

/// What the browser reports about the pad, for the help overlay.
class PadInfo {
  const PadInfo({required this.id, required this.standard, this.lastButton});

  final String id;
  final bool standard;
  final PadButton? lastButton;
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

  static const repeatDelay = Duration(milliseconds: 500);
  static const repeatEvery = Duration(milliseconds: 160);
  static const _stickOn = 0.6;
  static const _stickOff = 0.4;

  /// Whether a controller is connected (the last frame was not null).
  final connected = ValueNotifier<bool>(false);

  /// The pad's name and layout, and the last button pressed.
  final info = ValueNotifier<PadInfo?>(null);

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
    info.dispose();
  }

  /// Consumes one frame at time [now] and reports the presses it produced.
  List<PadButton> step(PadFrame? frame, Duration now) {
    if (frame != null &&
        (info.value?.id != frame.id ||
            info.value?.standard != frame.standard)) {
      info.value = PadInfo(id: frame.id, standard: frame.standard);
    }
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
    if (out.isNotEmpty && info.value != null) {
      info.value = PadInfo(
        id: info.value!.id,
        standard: info.value!.standard,
        lastButton: out.last,
      );
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
    poller.info.addListener(
      () => ref.read(padInfoProvider.notifier).set(poller.info.value),
    );
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

/// What the browser reports about the connected pad (null without one).
class PadInfoNotifier extends Notifier<PadInfo?> {
  @override
  PadInfo? build() => null;

  void set(PadInfo? info) => state = info;
}

final padInfoProvider = NotifierProvider<PadInfoNotifier, PadInfo?>(
  PadInfoNotifier.new,
);
