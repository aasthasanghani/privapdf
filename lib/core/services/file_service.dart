import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Where finished documents and temporary working files live.
///
/// Output goes to a private app folder; the user takes a copy out through the
/// system share sheet, so nothing is written to shared storage without a prompt.
class FileService {
  const FileService._();

  static Future<Directory> outputDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/PrivaPDF');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// A unique output path like `.../PrivaPDF/Scan_2026-10-29_14-20-05-123.pdf`.
  static Future<String> newOutputPath(String prefix, String ext) async {
    final dir = await outputDir();
    final stamp =
        DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    return '${dir.path}/${prefix}_$stamp.$ext';
  }

  static Future<Directory> tempDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/work');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// All saved output files, newest first.
  static Future<List<File>> listOutputs() async {
    final dir = await outputDir();
    final files = <File>[];
    await for (final e in dir.list()) {
      if (e is File) files.add(e);
    }
    files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  static String fileName(String path) =>
      path.split(Platform.pathSeparator).last.split('/').last;

  static Future<String> readableSize(String path) async {
    final bytes = await File(path).length();
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes bytes';
  }
}
