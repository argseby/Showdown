import 'package:web/web.dart' as web;

import 'revoked_browser.dart';

class _WebRevokedBrowser implements RevokedBrowser {
  @override
  void go(String url) => web.window.location.assign(url);

  @override
  RevokedReturn take() {
    final q = Uri.base.queryParameters;
    final code = q['revoked'];
    final error = q['revoked_error'];
    if (code == null && error == null) return (code: null, error: null);
    // A one-time code has no business staying in the address bar, the
    // history entry or the next referrer. Drop both parameters and keep
    // whatever else the address carried.
    final rest = Map<String, String>.from(q)
      ..remove('revoked')
      ..remove('revoked_error');
    final cleaned = Uri.base.replace(
      queryParameters: rest.isEmpty ? null : rest,
    );
    web.window.history.replaceState(
      null,
      '',
      rest.isEmpty ? cleaned.path : cleaned.toString(),
    );
    return (code: code, error: error);
  }
}

RevokedBrowser createRevokedBrowser() => _WebRevokedBrowser();
