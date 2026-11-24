import 'dart:typed_data';

import 'file_saver.dart';

class _NoFileSaver implements FileSaver {
  @override
  void saveText(
    String fileName,
    String content, {
    String mimeType = 'text/plain',
  }) {}

  @override
  void saveBytes(
    String fileName,
    Uint8List bytes, {
    String mimeType = 'application/octet-stream',
  }) {}
}

FileSaver createFileSaver() => _NoFileSaver();
