import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Page margin presets for image-to-PDF conversion.
enum PdfMargin { none, small, large }

/// Page orientation choice; [auto] decides per image from its pixel shape.
enum PdfOrientation { auto, portrait, landscape }

extension PdfMarginPoints on PdfMargin {
  /// Margin in PDF points (72 pt = 1 inch).
  double get points => switch (this) {
        PdfMargin.none => 0,
        PdfMargin.small => 18,
        PdfMargin.large => 54,
      };

  String get label => switch (this) {
        PdfMargin.none => 'None',
        PdfMargin.small => 'Small',
        PdfMargin.large => 'Large',
      };
}

extension PdfOrientationLabel on PdfOrientation {
  String get label => switch (this) {
        PdfOrientation.auto => 'Auto',
        PdfOrientation.portrait => 'Portrait',
        PdfOrientation.landscape => 'Landscape',
      };
}

/// Serializable payload handed to the background isolate.
class _ImagesToPdfParams {
  const _ImagesToPdfParams(
    this.imagePaths,
    this.outputPath,
    this.marginPt,
    this.orientationIndex,
  );

  final List<String> imagePaths;
  final String outputPath;
  final double marginPt;
  final int orientationIndex;
}

/// Builds the PDF off the UI thread. Pure Dart only (no plugins), so it is
/// safe to run inside [compute].
Future<String> _buildImagesPdf(_ImagesToPdfParams p) async {
  final doc = pw.Document();
  final orientation = PdfOrientation.values[p.orientationIndex];

  for (final path in p.imagePaths) {
    final bytes = await File(path).readAsBytes();
    final image = pw.MemoryImage(bytes);

    final bool landscape = switch (orientation) {
      PdfOrientation.portrait => false,
      PdfOrientation.landscape => true,
      PdfOrientation.auto =>
        (image.width ?? 0) > (image.height ?? 0),
    };

    var format = landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
    format = format.copyWith(
      marginTop: p.marginPt,
      marginBottom: p.marginPt,
      marginLeft: p.marginPt,
      marginRight: p.marginPt,
    );

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) =>
            pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );
  }

  final out = File(p.outputPath);
  await out.writeAsBytes(await doc.save());
  return p.outputPath;
}

/// Pure-Dart PDF operations. Heavy work runs in a background isolate so the
/// UI never stutters; no document bytes ever leave the device.
class PdfService {
  const PdfService._();

  static Future<String> imagesToPdf({
    required List<String> imagePaths,
    required String outputPath,
    required PdfMargin margin,
    required PdfOrientation orientation,
  }) {
    return compute(
      _buildImagesPdf,
      _ImagesToPdfParams(
        imagePaths,
        outputPath,
        margin.points,
        orientation.index,
      ),
    );
  }
}
