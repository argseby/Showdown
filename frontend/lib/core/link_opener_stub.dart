import 'link_opener.dart';

class _NoLinkOpener implements LinkOpener {
  @override
  void open(String url) {}
}

LinkOpener createLinkOpener() => _NoLinkOpener();
