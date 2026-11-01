import 'package:web/web.dart' as web;

import 'revoked_browser.dart';

String? _captured;
bool _looked = false;

/// Reads the reason and takes it back out of the address. Called from `main`
/// before the router exists: the router remembers the location it was built
/// with and puts the query back when it next writes history.
void captureRevokedReturn() {
  if (_looked) return;
  _looked = true;
  final q = Uri.base.queryParameters;
  final error = q['revoked_error'];
  if (error == null) return;
  _captured = error;
  final rest = Map<String, String>.from(q)..remove('revoked_error');
  final cleaned = Uri.base.replace(queryParameters: rest.isEmpty ? null : rest);
  web.window.history.replaceState(
    null,
    '',
    rest.isEmpty ? cleaned.path : cleaned.toString(),
  );
}

class _WebRevokedBrowser implements RevokedBrowser {
  @override
  void go(String url) => web.window.location.assign(url);

  @override
  String? take() {
    // Whatever remounts the scope, the reason is handed over once.
    captureRevokedReturn();
    final error = _captured;
    _captured = null;
    return error;
  }
}

RevokedBrowser createRevokedBrowser() => _WebRevokedBrowser();
