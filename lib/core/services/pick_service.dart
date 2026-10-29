import 'package:file_picker/file_picker.dart';

/// Thin wrapper over file_picker for the file types this app consumes.
class PickService {
  const PickService._();

  /// Picks one or more PDF files; returns their on-device paths.
  static Future<List<String>> pdfs() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    return [for (final f in files) if (f.path != null) f.path!];
  }
}
