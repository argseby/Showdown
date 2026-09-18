import 'gamepad.dart';

/// No Gamepad API here (tests, native builds).
const bool padSupported = false;

PadFrame? readPad() => null;

/// Nowhere to report to.
void reportPadDebug(String text) {}
