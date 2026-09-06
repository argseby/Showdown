import 'file_saver.dart';

class _NoFileSaver implements FileSaver {
  @override
  void saveText(
    String fileName,
    String content, {
    String mimeType = 'text/plain',
  }) {}
}

FileSaver createFileSaver() => _NoFileSaver();
