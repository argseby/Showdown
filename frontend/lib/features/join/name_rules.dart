/// Client-side mirror of the display-name rules (docs §5.6). The server is
/// authoritative; this only gives instant feedback.
class NameRules {
  const NameRules._();

  static const reserved = {'system', 'admin', 'dealer'};
  static final _allowed = RegExp(r'^[\p{L}\p{N} _\-.]+$', unicode: true);

  /// Normalizes (trim, collapse spaces) and returns null when invalid.
  static String? normalize(String raw) {
    final name = raw
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .join(' ');
    if (name.isEmpty || name.runes.length > 20) return null;
    if (!_allowed.hasMatch(name)) return null;
    if (reserved.contains(name.toLowerCase())) return null;
    return name;
  }
}
