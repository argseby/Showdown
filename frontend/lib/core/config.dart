/// Build-time configuration.
///
/// `API_BASE` is supplied with `--dart-define=API_BASE=http://localhost:8080`
/// during development. When empty (the production build) the app talks to its
/// own origin, which Caddy proxies to the API.
class AppConfig {
  const AppConfig._();

  static const String apiBase = String.fromEnvironment('API_BASE');

  /// HTTP base for REST calls, without a trailing slash. Empty means same
  /// origin, which is expressed as a relative path.
  static String get restBase => _stripTrailingSlash(apiBase);

  /// WebSocket base derived from [apiBase]: `http` becomes `ws`, `https`
  /// becomes `wss`. Empty when same-origin; callers then derive the scheme
  /// from the page URL.
  static String get wsBase => deriveWsBase(apiBase);

  static String deriveWsBase(String httpBase) {
    final base = _stripTrailingSlash(httpBase);
    if (base.isEmpty) return '';
    if (base.startsWith('https://')) return 'wss://${base.substring(8)}';
    if (base.startsWith('http://')) return 'ws://${base.substring(7)}';
    return base;
  }

  static String _stripTrailingSlash(String s) =>
      s.endsWith('/') ? s.substring(0, s.length - 1) : s;
}
