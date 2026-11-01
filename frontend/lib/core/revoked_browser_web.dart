import 'package:web/web.dart' as web;

import 'revoked_browser.dart';

RevokedReturn _captured = (code: null, error: null);
bool _looked = false;

/// Reads the one-time parameters and takes them back out of the address.
///
/// Called from `main` before the router exists. A code has no business
/// staying in the address bar, the history entry or the next referrer, and
/// stripping it late does not work: the router remembers the location it
/// was built with and puts the query back when it next writes history,
/// which would leave a spent code to be found and refused.
void captureRevokedReturn() {
  if (_looked) return;
  _looked = true;
  final q = Uri.base.queryParameters;
  final code = q['revoked'];
  final error = q['revoked_error'];
  if (code == null && error == null) return;
  _captured = (code: code, error: error);
  final rest = Map<String, String>.from(q)
    ..remove('revoked')
    ..remove('revoked_error');
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
  RevokedReturn take() {
    // Whatever remounts the scope, the return is handed over once.
    captureRevokedReturn();
    final ret = _captured;
    _captured = (code: null, error: null);
    return ret;
  }
}

RevokedBrowser createRevokedBrowser() => _WebRevokedBrowser();
