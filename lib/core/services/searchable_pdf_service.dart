import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdf/pdf.dart';

import 'file_service.dart';
import 'pdf_render_service.dart';

/// One recognized word with its pixel bounding box (origin top-left).
class _Word {
  const _Word(this.text, this.left, this.top, this.right, this.bottom);
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
}

/// A page ready for assembly: the rendered JPEG, its pixel size, the target
/// page size in points, and the words to place as an invisible layer.
class _SearchablePage {
  const _SearchablePage(
    this.jpg,
    this.pxWidth,
    this.pxHeight,
    this.widthPt,
    this.heightPt,
    this.words,
  );
  final Uint8List jpg;
  final int pxWidth;
  final int pxHeight;
  final double widthPt;
  final double heightPt;
  final List<_Word> words;
}

class _BuildParams {
  const _BuildParams(this.pages, this.outputPath);
  final List<_SearchablePage> pages;
  final String outputPath;
}

/// Runs in a background isolate: draws each page image full-bleed, then stamps
/// the recognized words as invisible text so the PDF is selectable/searchable.
Future<String> _assembleSearchable(_BuildParams p) async {
  final doc = PdfDocument();
  final font = PdfFont.helvetica(doc);

  for (final page in p.pages) {
    final pdfPage =
        PdfPage(doc, pageFormat: PdfPageFormat(page.widthPt, page.heightPt));
    final g = pdfPage.getGraphics();

    final image = PdfImage.jpeg(doc, image: page.jpg);
    g.drawImage(image, 0, 0, page.widthPt, page.heightPt);

    if (page.pxWidth <= 0 || page.pxHeight <= 0) continue;
    final sx = page.widthPt / page.pxWidth;
    final sy = page.heightPt / page.pxHeight;

    for (final w in page.words) {
      final text = w.text.trim();
      if (text.isEmpty) continue;
      final sizePt = (w.bottom - w.top) * sy;
      if (sizePt <= 0) continue;
      final x = w.left * sx;
      // PDF origin is bottom-left; place the text baseline near the box bottom.
      final y = page.heightPt - w.bottom * sy;
      g.drawString(
        font,
        sizePt,
        text,
        x,
        y,
        mode: PdfTextRenderingMode.invisible,
      );
    }
  }

  final bytes = await doc.save();
  await File(p.outputPath).writeAsBytes(bytes);
  return p.outputPath;
}

/// Produces a searchable PDF from an existing (image-only) PDF, entirely on
/// device: render → on-device OCR → invisible text layer.
class SearchablePdfService {
  const SearchablePdfService._();

  static Future<String> build(
    String pdfPath, {
    double dpi = 200,
    void Function(int done, int total)? onProgress,
  }) async {
    final rendered = await PdfRenderService.render(pdfPath, dpi: dpi);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final tempDir = await FileService.tempDir();
    final pages = <_SearchablePage>[];

    try {
      for (var i = 0; i < rendered.length; i++) {
        final rp = rendered[i];
        final tmp = '${tempDir.path}/searchable_$i.jpg';
        await File(tmp).writeAsBytes(rp.jpg);

        final result =
            await recognizer.processImage(InputImage.fromFilePath(tmp));
        final words = <_Word>[];
        for (final block in result.blocks) {
          for (final line in block.lines) {
            for (final el in line.elements) {
              final bb = el.boundingBox;
              words.add(_Word(el.text, bb.left, bb.top, bb.right, bb.bottom));
            }
          }
        }

        try {
          await File(tmp).delete();
        } catch (_) {}

        pages.add(_SearchablePage(
          rp.jpg,
          rp.pxWidth,
          rp.pxHeight,
          rp.widthPt,
          rp.heightPt,
          words,
        ));
        onProgress?.call(i + 1, rendered.length);
      }
    } finally {
      await recognizer.close();
    }

    final out = await FileService.newOutputPath('Searchable', 'pdf');
    return compute(_assembleSearchable, _BuildParams(pages, out));
  }
}
