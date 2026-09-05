/// Extracts a table id from user input: either a bare code or a full link of
/// the form `https://host/t/<id>` (optionally followed by `/play`).
///
/// Table ids are ten characters from the alphabet
/// `abcdefghjkmnpqrstuvwxyz23456789` (no 0/1/i/l/o to avoid confusion).
class TableCode {
  const TableCode._();

  static const String alphabet = 'abcdefghjkmnpqrstuvwxyz23456789';
  static const int length = 10;

  static final RegExp _code = RegExp('^[$alphabet]{$length}\$');
  static final RegExp _inLink = RegExp(
    '/t/([$alphabet]{$length})(?:/|\\?|#|\$)',
  );

  /// Returns the table id contained in [input], or `null` if none is found.
  static String? parse(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final lower = text.toLowerCase();
    if (_code.hasMatch(lower)) return lower;
    final match = _inLink.firstMatch(lower);
    return match?.group(1);
  }
}
