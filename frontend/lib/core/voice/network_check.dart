// What a browser can find out about its own network before the first
// voice connection: a few seconds of ICE gathering with the instance's
// STUN/TURN servers, read back as candidate types. Pure logic here; the
// engine only collects the candidates.

/// One gathered ICE candidate, reduced to what the check needs.
class ProbeCandidate {
  const ProbeCandidate({
    required this.type,
    this.address,
    this.port,
    this.relatedAddress,
    this.relatedPort,
    this.protocol,
  });

  /// host, srflx, prflx or relay.
  final String type;
  final String? address;
  final int? port;

  /// For a srflx candidate: the local socket the mapping belongs to.
  final String? relatedAddress;
  final int? relatedPort;
  final String? protocol;
}

/// The one-line outcome of the check, worst first.
enum NetworkVerdict {
  /// A TURN relay answered: connections work from any network.
  relayOk,

  /// A TURN relay is configured but produced no relay candidate: it is
  /// unreachable or rejects the credentials.
  relayFailed,

  /// STUN servers are configured but none answered: UDP is blocked
  /// (firewall), so nothing beyond the local network will connect.
  stunBlocked,

  /// The NAT maps the same socket differently per destination (symmetric
  /// NAT): direct connections to other networks fail.
  symmetricNat,

  /// No STUN and no TURN configured: same network only.
  noStun,

  /// Address lookup works and nothing speaks against direct connections.
  ok,

  /// The check itself did not run (browser refused, timeout before any
  /// result).
  unknown,
}

/// The result of [analyzeNetwork].
class NetworkReport {
  const NetworkReport({
    required this.verdict,
    this.stunConfigured = false,
    this.stunReachable = false,
    this.symmetric,
    this.turnConfigured = false,
    this.relayWorks,
  });

  const NetworkReport.unknown() : this(verdict: NetworkVerdict.unknown);

  final NetworkVerdict verdict;
  final bool stunConfigured;

  /// At least one srflx candidate came back.
  final bool stunReachable;

  /// Null when it could not be told (fewer than two STUN servers, or the
  /// browser hides the local addresses).
  final bool? symmetric;
  final bool turnConfigured;

  /// Null when no TURN server is configured.
  final bool? relayWorks;

  /// Voice and video to other networks will not work from here.
  bool get problem => switch (verdict) {
    NetworkVerdict.relayFailed ||
    NetworkVerdict.stunBlocked ||
    NetworkVerdict.symmetricNat ||
    NetworkVerdict.noStun => true,
    NetworkVerdict.relayOk ||
    NetworkVerdict.ok ||
    NetworkVerdict.unknown => false,
  };

  @override
  bool operator ==(Object other) =>
      other is NetworkReport &&
      other.verdict == verdict &&
      other.stunConfigured == stunConfigured &&
      other.stunReachable == stunReachable &&
      other.symmetric == symmetric &&
      other.turnConfigured == turnConfigured &&
      other.relayWorks == relayWorks;

  @override
  int get hashCode => Object.hash(
    verdict,
    stunConfigured,
    stunReachable,
    symmetric,
    turnConfigured,
    relayWorks,
  );

  @override
  String toString() =>
      'NetworkReport(${verdict.name}, stun: $stunReachable, '
      'symmetric: $symmetric, relay: $relayWorks)';
}

/// Reads the verdict from two gathering runs: [direct] with the STUN
/// servers only and [relay] with everything but relay candidates allowed
/// (empty when no TURN server is configured). [stunServers] is the number
/// of STUN URLs used for [direct].
///
/// Symmetric NAT: the browser sends its binding requests to every STUN
/// server from the same socket and keeps only distinct mappings, so two
/// srflx candidates with the same related address and port mean the NAT
/// mapped one socket to two public ports, once per destination. That needs
/// at least two STUN servers; with one the answer stays open.
NetworkReport analyzeNetwork({
  required List<ProbeCandidate> direct,
  required List<ProbeCandidate> relay,
  required int stunServers,
  required bool turnConfigured,
}) {
  final srflx = direct.where((c) => c.type == 'srflx').toList();
  final stunReachable = srflx.isNotEmpty;
  final relayWorks = turnConfigured
      ? relay.any((c) => c.type == 'relay')
      : null;
  final symmetric = _symmetric(srflx, stunServers);
  final NetworkVerdict verdict;
  if (relayWorks == true) {
    verdict = NetworkVerdict.relayOk;
  } else if (relayWorks == false) {
    verdict = NetworkVerdict.relayFailed;
  } else if (stunServers == 0) {
    verdict = NetworkVerdict.noStun;
  } else if (!stunReachable) {
    verdict = NetworkVerdict.stunBlocked;
  } else if (symmetric == true) {
    verdict = NetworkVerdict.symmetricNat;
  } else {
    verdict = NetworkVerdict.ok;
  }
  return NetworkReport(
    verdict: verdict,
    stunConfigured: stunServers > 0,
    stunReachable: stunReachable,
    symmetric: symmetric,
    turnConfigured: turnConfigured,
    relayWorks: relayWorks,
  );
}

bool? _symmetric(List<ProbeCandidate> srflx, int stunServers) {
  if (stunServers < 2) return null;
  final mappings = <String, Set<String>>{};
  for (final c in srflx) {
    final ra = c.relatedAddress;
    final rp = c.relatedPort;
    // A hidden local address (0.0.0.0, ::, port 0) cannot be grouped.
    if (ra == null || rp == null || rp == 0 || ra == '0.0.0.0' || ra == '::') {
      continue;
    }
    mappings.putIfAbsent('$ra:$rp', () => {}).add('${c.address}:${c.port}');
  }
  if (mappings.isEmpty) return null;
  return mappings.values.any((m) => m.length >= 2);
}
