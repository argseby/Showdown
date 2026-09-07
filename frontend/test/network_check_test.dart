import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/core/voice/network_check.dart';

ProbeCandidate srflx(
  String address,
  int port, {
  String? related = '192.168.1.5',
  int relatedPort = 50000,
}) => ProbeCandidate(
  type: 'srflx',
  address: address,
  port: port,
  relatedAddress: related,
  relatedPort: relatedPort,
);

const host = ProbeCandidate(type: 'host', address: '192.168.1.5', port: 50000);
const relay = ProbeCandidate(type: 'relay', address: '203.0.113.9', port: 6001);

void main() {
  test('a relay candidate settles it: works from anywhere', () {
    final r = analyzeNetwork(
      direct: [host],
      relay: [relay],
      stunServers: 1,
      turnConfigured: true,
    );
    expect(r.verdict, NetworkVerdict.relayOk);
    expect(r.relayWorks, isTrue);
    expect(r.problem, isFalse);
  });

  test('a configured relay that answers nothing is reported', () {
    final r = analyzeNetwork(
      direct: [host, srflx('198.51.100.7', 40001)],
      relay: const [],
      stunServers: 1,
      turnConfigured: true,
    );
    expect(r.verdict, NetworkVerdict.relayFailed);
    expect(r.problem, isTrue);
  });

  test('no STUN and no TURN means same network only', () {
    final r = analyzeNetwork(
      direct: [host],
      relay: const [],
      stunServers: 0,
      turnConfigured: false,
    );
    expect(r.verdict, NetworkVerdict.noStun);
    expect(r.stunConfigured, isFalse);
    expect(r.problem, isTrue);
  });

  test('STUN configured but no public address came back: blocked', () {
    final r = analyzeNetwork(
      direct: [host],
      relay: const [],
      stunServers: 2,
      turnConfigured: false,
    );
    expect(r.verdict, NetworkVerdict.stunBlocked);
    expect(r.stunReachable, isFalse);
  });

  test('two mappings of one socket: symmetric NAT', () {
    final r = analyzeNetwork(
      direct: [
        host,
        srflx('198.51.100.7', 40001),
        srflx('198.51.100.7', 40777),
      ],
      relay: const [],
      stunServers: 2,
      turnConfigured: false,
    );
    expect(r.verdict, NetworkVerdict.symmetricNat);
    expect(r.symmetric, isTrue);
    expect(r.problem, isTrue);
  });

  test('one mapping with two STUN servers: not symmetric, direct is fine', () {
    final r = analyzeNetwork(
      direct: [host, srflx('198.51.100.7', 40001)],
      relay: const [],
      stunServers: 2,
      turnConfigured: false,
    );
    expect(r.verdict, NetworkVerdict.ok);
    expect(r.symmetric, isFalse);
    expect(r.problem, isFalse);
  });

  test('a single STUN server cannot tell a symmetric NAT', () {
    final r = analyzeNetwork(
      direct: [host, srflx('198.51.100.7', 40001)],
      relay: const [],
      stunServers: 1,
      turnConfigured: false,
    );
    expect(r.verdict, NetworkVerdict.ok);
    expect(r.symmetric, isNull);
  });

  test('hidden local addresses leave the NAT type open', () {
    final r = analyzeNetwork(
      direct: [
        srflx('198.51.100.7', 40001, related: '0.0.0.0', relatedPort: 0),
        srflx('198.51.100.7', 40777, related: '0.0.0.0', relatedPort: 0),
      ],
      relay: const [],
      stunServers: 2,
      turnConfigured: false,
    );
    expect(r.verdict, NetworkVerdict.ok);
    expect(r.symmetric, isNull);
  });

  test('two interfaces are not mistaken for a symmetric NAT', () {
    final r = analyzeNetwork(
      direct: [
        srflx(
          '198.51.100.7',
          40001,
          related: '192.168.1.5',
          relatedPort: 50000,
        ),
        srflx('198.51.100.7', 40777, related: '10.8.0.2', relatedPort: 50001),
      ],
      relay: const [],
      stunServers: 2,
      turnConfigured: false,
    );
    expect(r.symmetric, isFalse);
    expect(r.verdict, NetworkVerdict.ok);
  });
}
