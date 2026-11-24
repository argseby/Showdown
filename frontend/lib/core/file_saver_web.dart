import 'dart:js_interop';
import 'dart:typed_data';

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
    _download(fileName, blob);
  }

  @override
  void saveBytes(
    String fileName,
    Uint8List bytes, {
    String mimeType = 'application/octet-stream',
  }) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    _download(fileName, blob);
  }

  void _download(String fileName, web.Blob blob) {
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
