import 'link_opener_stub.dart'
    if (dart.library.js_interop) 'link_opener_web.dart'
    as impl;

/// Opens an external address in a new tab. The app itself never talks to
/// anything but its own origin; this only hands a link to the browser when
/// the user asks for it.
abstract class LinkOpener {
  void open(String url);

  static LinkOpener create() => impl.createLinkOpener();
}
