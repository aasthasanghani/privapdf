import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device text recognition (ML Kit). Runs locally; no image or text ever
/// leaves the phone.
class OcrService {
  const OcrService._();

  /// Recognizes Latin-script text across the given image files, in order.
  static Future<String> recognizeFiles(List<String> imagePaths) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final buffer = StringBuffer();
      for (final path in imagePaths) {
        final result =
            await recognizer.processImage(InputImage.fromFilePath(path));
        final text = result.text.trim();
        if (text.isNotEmpty) {
          buffer
            ..writeln(text)
            ..writeln();
        }
      }
      return buffer.toString().trim();
    } finally {
      await recognizer.close();
    }
  }
}
