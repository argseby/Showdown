import 'revoked_browser_stub.dart'
    if (dart.library.js_interop) 'revoked_browser_web.dart'
    as impl;

/// The browser half of signing in with revoked.
abstract class RevokedBrowser {
  /// Opens the Revoked app on this device. The page stays: it is waiting for
  /// the answer, and with no app installed nothing happens at all.
  void go(String url);

  /// Hands over, once, the reason a sign-in failed when the answer reached
  /// this page through its address. That happens only when the Revoked app
  /// could not reach this server and passed the answer to a browser.
  String? take();

  static RevokedBrowser create() => impl.createRevokedBrowser();
}

/// Lifts the reason out of the address and strips it.
///
/// This runs in `main`, before the router is built, and that order is the
/// whole point: the router keeps the location it was constructed with and
/// writes it back into history later, so a strip after the fact is undone.
/// Off the web it does nothing.
void captureRevokedReturn() => impl.captureRevokedReturn();
