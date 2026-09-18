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
    expect(poller.step(held, const Duration(milliseconds: 400)), isEmpty);
    expect(poller.step(held, const Duration(milliseconds: 500)), [
      PadButton.down,
    ]);
    expect(poller.step(held, const Duration(milliseconds: 600)), isEmpty);
    expect(poller.step(held, const Duration(milliseconds: 660)), [
      PadButton.down,
    ]);
  });

  test('a non-standard Linux layout is rearranged into the standard one', () {
    // Raw xpad order: A B X Y LB RB Back Start Guide L3 R3; the D-pad as
    // a hat on axes 6/7, the triggers on axes 2/5.
    PadFrame raw({Set<int> down = const {}, List<double> axes = const []}) =>
        PadFrame(
          pressed: [for (var i = 0; i < 11; i++) down.contains(i)],
          axes: axes,
          id: 'xpad',
          standard: false,
        );
    final back = remapNonStandard(raw(down: {6}));
    expect(back.pressed[PadButton.back.index], isTrue);
    expect(back.pressed[PadButton.lt.index], isFalse);
    final start = remapNonStandard(raw(down: {7}));
    expect(start.pressed[PadButton.start.index], isTrue);
    final hat = remapNonStandard(raw(axes: [0, 0, -1, 0, 0, -1, -1, 1]));
    expect(hat.pressed[PadButton.left.index], isTrue);
    expect(hat.pressed[PadButton.down.index], isTrue);
    expect(hat.pressed[PadButton.up.index], isFalse);
    final rt = remapNonStandard(raw(axes: [0, 0, -1, 0, 0, 0.8]));
    expect(rt.pressed[PadButton.rt.index], isTrue);
    expect(rt.pressed[PadButton.lt.index], isFalse);
    // The poller reports the pad, and its last button.
    final poller = GamepadPoller(read: () => null);
    poller.step(back, Duration.zero);
    expect(poller.info.value?.id, 'xpad');
    expect(poller.info.value?.standard, isFalse);
    expect(poller.info.value?.lastButton, PadButton.back);
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
