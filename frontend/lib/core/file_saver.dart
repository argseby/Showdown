import 'dart:typed_data';

import 'file_saver_stub.dart'
    if (dart.library.js_interop) 'file_saver_web.dart'
    as impl;

/// Hands a generated text file to the user (a download in the browser).
abstract class FileSaver {
  void saveText(
    String fileName,
    String content, {
    String mimeType = 'text/plain',
  });

  /// Hands a generated binary file to the user (the PDF export).
  void saveBytes(
    String fileName,
    Uint8List bytes, {
    String mimeType = 'application/octet-stream',
  });

  static FileSaver create() => impl.createFileSaver();
}
