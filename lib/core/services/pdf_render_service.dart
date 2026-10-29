import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

/// One page rendered from an existing PDF: JPEG bytes plus the original page
/// size in PDF points, so a rebuilt PDF keeps the same page dimensions.
class RenderedPage {
  RenderedPage(this.jpg, this.widthPt, this.heightPt);

  final Uint8List jpg;
  final double widthPt;
  final double heightPt;
}

/// Reads existing PDFs via the native PDFium engine (pdfrx). These are plugin
/// calls, so they run on the platform thread — not inside a Dart isolate — but
/// PDFium itself renders on a native worker, so the UI stays responsive.
class PdfRenderService {
  const PdfRenderService._();

  static Future<int> pageCount(String path) async {
    final doc = await PdfDocument.openFile(path);
    try {
      return doc.pages.length;
    } finally {
      await doc.dispose();
    }
  }

  /// Renders [indices] (or all pages) of [path] to JPEG at [dpi].
  static Future<List<RenderedPage>> render(
    String path, {
    double dpi = 150,
    List<int>? indices,
    int quality = 80,
  }) async {
    final doc = await PdfDocument.openFile(path);
    try {
      final pages = doc.pages;
      final wanted = indices ?? List.generate(pages.length, (i) => i);
      final out = <RenderedPage>[];
      for (final i in wanted) {
        if (i < 0 || i >= pages.length) continue;
        final page = pages[i];
        final wPx = (page.width / 72.0 * dpi).round();
        final hPx = (page.height / 72.0 * dpi).round();
        final rendered = await page.render(
          fullWidth: wPx.toDouble(),
          fullHeight: hPx.toDouble(),
          width: wPx,
          height: hPx,
          backgroundColor: 0xFFFFFFFF,
        );
        if (rendered == null) continue;
        final image = rendered.createImageNF();
        rendered.dispose();
        final jpg = img.encodeJpg(image, quality: quality);
        out.add(RenderedPage(jpg, page.width, page.height));
      }
      return out;
    } finally {
      await doc.dispose();
    }
  }
}
