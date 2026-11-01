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

  /// Reads the result out of the current address and takes it back out
  /// again, so a reload does not try to spend a code a second time.
  RevokedReturn take();

  static RevokedBrowser create() => impl.createRevokedBrowser();
}
