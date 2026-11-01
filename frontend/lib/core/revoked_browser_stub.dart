import 'revoked_browser.dart';

/// Off the web there is no address bar to come back to, and the sign-in is
/// never offered.
class _NoRevokedBrowser implements RevokedBrowser {
  @override
  void go(String url) {}

  @override
  String? take() => null;
}

RevokedBrowser createRevokedBrowser() => _NoRevokedBrowser();

void captureRevokedReturn() {}
