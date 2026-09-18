import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/core/gamepad/gamepad.dart';

PadFrame frame({
  Set<PadButton> down = const {},
  List<double> axes = const [],
}) => PadFrame(
  pressed: [for (final b in PadButton.values) down.contains(b)],
  axes: axes,
);

void main() {
  test('a button press is reported once, on the way down', () {
    final poller = GamepadPoller(read: () => null);
    expect(poller.step(frame(down: {PadButton.a}), Duration.zero), [
      PadButton.a,
    ]);
    expect(poller.connected.value, isTrue);
    // Held: nothing more (A does not repeat).
    expect(
      poller.step(frame(down: {PadButton.a}), const Duration(seconds: 1)),
      isEmpty,
    );
    expect(poller.step(frame(), const Duration(seconds: 2)), isEmpty);
    expect(
      poller.step(frame(down: {PadButton.a}), const Duration(seconds: 3)),
      [PadButton.a],
    );
    // Unplugged.
    expect(poller.step(null, const Duration(seconds: 4)), isEmpty);
    expect(poller.connected.value, isFalse);
  });

  test('a held direction repeats after the delay', () {
    final poller = GamepadPoller(read: () => null);
    final held = frame(down: {PadButton.down});
    expect(poller.step(held, Duration.zero), [PadButton.down]);
    expect(poller.step(held, const Duration(milliseconds: 300)), isEmpty);
    expect(poller.step(held, const Duration(milliseconds: 400)), [
      PadButton.down,
    ]);
    expect(poller.step(held, const Duration(milliseconds: 450)), isEmpty);
    expect(poller.step(held, const Duration(milliseconds: 520)), [
      PadButton.down,
    ]);
  });

  test('the left stick acts as the directions, with hysteresis', () {
    final poller = GamepadPoller(read: () => null);
    expect(poller.step(frame(axes: [0.3, 0]), Duration.zero), isEmpty);
    expect(poller.step(frame(axes: [0.7, 0]), Duration.zero), [
      PadButton.right,
    ]);
    // Easing back to 0.5 keeps it held; 0.3 releases it.
    expect(poller.step(frame(axes: [0.5, 0]), Duration.zero), isEmpty);
    expect(poller.step(frame(axes: [0.3, 0]), Duration.zero), isEmpty);
    expect(poller.step(frame(axes: [0.7, 0]), Duration.zero), [
      PadButton.right,
    ]);
    expect(poller.step(frame(axes: [0, -0.9]), Duration.zero), [PadButton.up]);
  });
}
