import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/protocol/protocol.dart';

/// Re-encodes JSON with sorted keys so two documents compare structurally.
String canonical(Object? value) => jsonEncode(_sorted(value));

Object? _sorted(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return {for (final k in keys) k: _sorted(value[k])};
  }
  if (value is List) return value.map(_sorted).toList();
  return value;
}

const clientTypes = {
  'hello',
  'action',
  'sit_out',
  'sit_in',
  'rebuy',
  'leave',
  'show_cards',
  'say',
  'straddle',
  'run_twice',
  'ping',
};

void main() {
  final dir = Directory('../docs/protocol/fixtures');
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('fixtures directory is populated', () {
    expect(files.length, greaterThanOrEqualTo(21));
  });

  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceAll('.json', '');
    test('fixture $name round-trips', () {
      final raw = file.readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final env = Envelope.fromJson(json);
      final Envelope re;
      if (clientTypes.contains(env.type) || name == 'chat_client') {
        re = encodeClientMessage(decodeClientMessage(env), id: env.id);
      } else {
        re = encodeServerMessage(decodeServerMessage(env));
      }
      expect(canonical(re.toJson()), canonical(json), reason: name);
    });
  }

  test('unknown types throw ProtocolError', () {
    expect(
      () => decodeServerMessage(const Envelope(type: 'nope', payload: {})),
      throwsA(isA<ProtocolError>()),
    );
    expect(
      () => decodeClientMessage(const Envelope(type: 'nope', payload: {})),
      throwsA(isA<ProtocolError>()),
    );
    expect(
      () =>
          decodeServerMessage(const Envelope(type: 'pong', payload: {'x': 1})),
      throwsA(isA<ProtocolError>()),
    );
  });

  test('snapshot omits hole cards when absent', () {
    final env = jsonDecode(
      File('../docs/protocol/fixtures/snapshot.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final snap = Snapshot.fromJson(env['payload'] as Map<String, dynamic>);
    expect(snap.seats[0].player!.holeCards, ['As', 'Kd']);
    expect(snap.seats[2].player!.holeCards, isNull);
    expect(snap.seats[2].player!.toJson().containsKey('hole_cards'), isFalse);
    expect(snap.seats[0].player!.toJson()['last_action'], isNull);
    expect(snap.seats[0].player!.toJson().containsKey('last_action'), isTrue);
  });
}
