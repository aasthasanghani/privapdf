import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
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

/// Where a page number is stamped, or [none].
enum PageNumberPosition { none, footer, header }

extension PageNumberPositionLabel on PageNumberPosition {
  String get label => switch (this) {
        PageNumberPosition.none => 'None',
        PageNumberPosition.footer => 'Footer',
        PageNumberPosition.header => 'Header',
      };
}

/// A page to place into a rebuilt PDF: rendered JPEG plus the page size in
/// points so dimensions are preserved. [quarterTurns] rotates the page by
/// multiples of 90° clockwise.
class PageSpec {
  const PageSpec(this.jpg, this.widthPt, this.heightPt, {this.quarterTurns = 0});

  final Uint8List jpg;
  final double widthPt;
  final double heightPt;
  final int quarterTurns;
}

class _AssembleParams {
  const _AssembleParams(
    this.pages,
    this.outputPath,
    this.watermark,
    this.pageNumberIndex,
  );

  final List<PageSpec> pages;
  final String outputPath;
  final String? watermark;
  final int pageNumberIndex;
}

/// Rebuilds a PDF from rendered pages, optionally stamping a diagonal
/// watermark and/or page numbers as crisp vector text over each page.
Future<String> _assemblePdf(_AssembleParams p) async {
  final doc = pw.Document();
  final position = PageNumberPosition.values[p.pageNumberIndex];
  final total = p.pages.length;

  for (var i = 0; i < total; i++) {
    final spec = p.pages[i];

    var jpg = spec.jpg;
    var widthPt = spec.widthPt;
    var heightPt = spec.heightPt;
    final turns = ((spec.quarterTurns % 4) + 4) % 4;
    if (turns != 0) {
      final decoded = img.decodeImage(spec.jpg);
      if (decoded != null) {
        final rotated = img.copyRotate(decoded, angle: turns * 90);
        jpg = img.encodeJpg(rotated, quality: 85);
        if (turns.isOdd) {
          final t = widthPt;
          widthPt = heightPt;
          heightPt = t;
        }
      }
    }

    final image = pw.MemoryImage(jpg);
    final format = PdfPageFormat(widthPt, heightPt);

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          final layers = <pw.Widget>[
            pw.Positioned.fill(
              child: pw.Image(image, fit: pw.BoxFit.fill),
            ),
          ];

          if (p.watermark != null && p.watermark!.trim().isNotEmpty) {
            layers.add(
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: 0.6,
                    child: pw.Opacity(
                      opacity: 0.22,
                      child: pw.Text(
                        p.watermark!,
                        style: pw.TextStyle(
                          fontSize: widthPt / 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          if (position != PageNumberPosition.none) {
            final label = pw.Text(
              '${i + 1} / $total',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
            );
            layers.add(
              pw.Positioned(
                left: 0,
                right: 0,
                top: position == PageNumberPosition.header ? 12 : null,
                bottom: position == PageNumberPosition.footer ? 12 : null,
                child: pw.Center(child: label),
              ),
            );
          }

          return pw.Stack(children: layers);
        },
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

  /// Rebuilds a PDF from already-rendered [pages]. Used by merge, split,
  /// reorder/rotate, watermark and page-number tools.
  static Future<String> assemble({
    required List<PageSpec> pages,
    required String outputPath,
    String? watermark,
    PageNumberPosition pageNumbers = PageNumberPosition.none,
  }) {
    return compute(
      _assemblePdf,
      _AssembleParams(pages, outputPath, watermark, pageNumbers.index),
    );
  }
}
