import 'package:web/web.dart' as web;

import 'link_opener.dart';

class _WebLinkOpener implements LinkOpener {
  @override
  void open(String url) {
    // noopener keeps the new tab from reaching back into this one.
    web.window.open(url, '_blank', 'noopener,noreferrer');
  }
}

LinkOpener createLinkOpener() => _WebLinkOpener();
