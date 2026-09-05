import 'package:intl/intl.dart';

import '../app/preferences.dart';

/// Chip amounts with thousands separators in the given locale.
String formatChips(int amount, [String? locale]) =>
    NumberFormat.decimalPattern(locale).format(amount);

/// Formats an amount in the chosen display mode: coins, or big blinds
/// ("3 BB", "2.5 BB") when [mode] is [ChipDisplay.bigBlinds] and a big blind
/// is known.
String formatAmount(
  int amount, {
  required ChipDisplay mode,
  required int bigBlind,
  String? locale,
}) {
  if (mode == ChipDisplay.coins || bigBlind <= 0) {
    return formatChips(amount, locale);
  }
  return '${formatBigBlinds(amount, bigBlind, locale)} BB';
}

/// The number of big blinds an amount represents, with up to two decimals
/// and no trailing zeros ("3", "2.5", "0.25").
String formatBigBlinds(int amount, int bigBlind, [String? locale]) {
  final bb = amount / bigBlind;
  final f = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = 2;
  return f.format(bb);
}

/// Parses a big-blind input ("2,5" or "2.5") into chips, rounded to whole
/// chips; null when the text is not a number.
int? parseBigBlinds(String text, int bigBlind) {
  final v = double.tryParse(text.trim().replaceAll(',', '.'));
  if (v == null) return null;
  return (v * bigBlind).round();
}

/// Suit symbols for card strings such as "As" or "Td".
const suitSymbols = {'s': '♠', 'h': '♥', 'd': '♦', 'c': '♣'};

/// Renders "As" as "A♠" (rank T becomes 10).
String prettyCard(String card) {
  if (card.length != 2) return card;
  final rank = card[0] == 'T' ? '10' : card[0];
  return '$rank${suitSymbols[card[1]] ?? card[1]}';
}

String prettyCards(Iterable<String> cards) => cards.map(prettyCard).join(' ');

/// Initials for the avatar: first letters of the first two words.
String initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

/// Deterministic hue (0..360) for a name, used for chat colors.
double nameHue(String name) {
  var h = 0;
  for (final r in name.toLowerCase().runes) {
    h = (h * 31 + r) & 0x7fffffff;
  }
  return (h % 360).toDouble();
}

String formatClock(int ts) =>
    DateFormat.Hm().format(DateTime.fromMillisecondsSinceEpoch(ts));
