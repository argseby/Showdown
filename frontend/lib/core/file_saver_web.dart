import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'file_saver.dart';

class _WebFileSaver implements FileSaver {
  @override
  void saveText(
    String fileName,
    String content, {
    String mimeType = 'text/plain',
  }) {
    final blob = web.Blob(
      [content.toJS].toJS,
      web.BlobPropertyBag(type: '$mimeType;charset=utf-8'),
    );
    final url = web.URL.createObjectURL(blob);
    final a = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';
    web.document.body?.append(a);
    a.click();
    a.remove();
    web.URL.revokeObjectURL(url);
  }
}

FileSaver createFileSaver() => _WebFileSaver();
