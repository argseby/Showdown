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

  static FileSaver create() => impl.createFileSaver();
}
