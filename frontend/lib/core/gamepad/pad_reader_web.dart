import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'gamepad.dart';

/// The browser's Gamepad API. A controller shows up only after the user
/// pressed one of its buttons, and only on HTTPS or localhost.
const bool padSupported = true;

bool _broken = false;

/// Where the controller's cursor is, as `window.__padDebug`, so a test
/// harness (or a curious developer) can read it from the console.
void reportPadDebug(String text) {
  globalContext.setProperty('__padDebug'.toJS, text.toJS);
  web.console.log('pad: $text'.toJS);
}

PadFrame? readPad() {
  if (_broken) return null;
  try {
    for (final pad in web.window.navigator.getGamepads().toDart) {
      if (pad == null || !pad.connected) continue;
      final raw = PadFrame(
        pressed: [for (final b in pad.buttons.toDart) b.pressed],
        axes: [for (final a in pad.axes.toDart) a.toDartDouble],
        id: pad.id,
        standard: pad.mapping == 'standard',
      );
      return raw.standard ? raw : remapNonStandard(raw);
    }
  } catch (_) {
    // Not allowed here (an insecure origin, an embedding policy): give up
    // rather than throw sixty times a second.
    _broken = true;
  }
  return null;
}
