import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'file_service.dart';

/// Adds AES-256 password protection to an existing PDF, losslessly (the page
/// content is preserved, not re-rendered). Runs entirely on device.
class PasswordService {
  const PasswordService._();

  static Future<String> protect(String inputPath, String password) async {
    final bytes = await File(inputPath).readAsBytes();
    final document = sf.PdfDocument(inputBytes: bytes);
    try {
      document.security
        ..algorithm = sf.PdfEncryptionAlgorithm.aesx256Bit
        ..userPassword = password
        ..ownerPassword = password;
      final out = await document.save();
      final outPath = await FileService.newOutputPath('Protected', 'pdf');
      await File(outPath).writeAsBytes(out);
      return outPath;
    } finally {
      document.dispose();
    }
  }
}
