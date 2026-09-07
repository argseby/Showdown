import '../../core/voice/network_check.dart';
import '../../l10n/app_localizations.dart';

/// Short status of the network check for the settings row.
String networkStatus(
  AppLocalizations l10n,
  NetworkReport? report, {
  bool checking = false,
}) {
  if (checking) return l10n.networkChecking;
  return switch (report?.verdict) {
    null || NetworkVerdict.unknown => l10n.networkStatusUnknown,
    NetworkVerdict.relayOk => l10n.networkStatusRelay,
    NetworkVerdict.relayFailed => l10n.networkStatusRelayFailed,
    NetworkVerdict.stunBlocked => l10n.networkStatusStunBlocked,
    NetworkVerdict.symmetricNat => l10n.networkStatusSymmetric,
    NetworkVerdict.noStun => l10n.networkStatusNoStun,
    NetworkVerdict.ok => l10n.networkStatusOk,
  };
}

/// The full explanation of a problem and what to do about it; the host
/// also gets the server-side hint that fits the verdict (STUN first when
/// none is configured, TURN for networks that cannot connect directly, a
/// checklist for a relay that stays silent).
String networkExplanation(
  AppLocalizations l10n,
  NetworkReport report, {
  bool host = false,
}) {
  final text = switch (report.verdict) {
    NetworkVerdict.relayFailed => l10n.networkRelayFailed,
    NetworkVerdict.stunBlocked => l10n.networkStunBlocked,
    NetworkVerdict.symmetricNat => l10n.networkSymmetric,
    NetworkVerdict.noStun => l10n.networkNoStun,
    NetworkVerdict.relayOk => l10n.networkStatusRelay,
    NetworkVerdict.ok => l10n.networkStatusOk,
    NetworkVerdict.unknown => l10n.networkStatusUnknown,
  };
  if (!host) return text;
  final hint = switch (report.verdict) {
    NetworkVerdict.noStun => l10n.networkHostHintStun,
    NetworkVerdict.relayFailed => l10n.networkHostHintRelay,
    NetworkVerdict.stunBlocked ||
    NetworkVerdict.symmetricNat => l10n.networkHostHintTurn,
    NetworkVerdict.relayOk ||
    NetworkVerdict.ok ||
    NetworkVerdict.unknown => null,
  };
  return hint == null ? text : '$text $hint';
}
