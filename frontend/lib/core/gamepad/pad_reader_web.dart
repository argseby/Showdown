import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'gamepad.dart';

/// The browser's Gamepad API. A controller shows up only after the user
/// pressed one of its buttons, and only on HTTPS or localhost.
const bool padSupported = true;

bool _broken = false;

PadFrame? readPad() {
  if (_broken) return null;
  try {
    for (final pad in web.window.navigator.getGamepads().toDart) {
      if (pad == null || !pad.connected) continue;
      return PadFrame(
        pressed: [for (final b in pad.buttons.toDart) b.pressed],
        axes: [for (final a in pad.axes.toDart) a.toDartDouble],
      );
    }
  } catch (_) {
    // Not allowed here (an insecure origin, an embedding policy): give up
    // rather than throw sixty times a second.
    _broken = true;
  }
  return null;
}
