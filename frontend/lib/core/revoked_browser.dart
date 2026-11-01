import 'revoked_browser_stub.dart'
    if (dart.library.js_interop) 'revoked_browser_web.dart'
    as impl;

/// What came back from a revoked server on this page load.
typedef RevokedReturn = ({String? code, String? error});

/// The browser half of signing in with revoked.
///
/// The sign-in leaves this page: the revoked server has to set eyes on the
/// player, and the server-side leg needs the cookie it set when the
/// sign-in started. So the whole tab goes, and the player comes back to
/// the same tab with a one-time code in the address.
abstract class RevokedBrowser {
  /// Sends this tab to the revoked server. Not a new tab: the answer has
  /// to land where the sign-in began.
  void go(String url);

  /// Hands over what [captureRevokedReturn] found, once.
  RevokedReturn take();

  static RevokedBrowser create() => impl.createRevokedBrowser();
}

/// Lifts the one-time parameters out of the address and strips them.
///
/// This runs in `main`, before the router is built, and that order is the
/// whole point: the router keeps the location it was constructed with and
/// writes it back into history later, so a strip after the fact is undone
/// and the spent code reappears in the address bar. Off the web it does
/// nothing.
void captureRevokedReturn() => impl.captureRevokedReturn();
