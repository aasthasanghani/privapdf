import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Page cleanup filters, Adobe-Scan style.
enum DocFilter { original, grayscale, blackWhite, enhance }

extension DocFilterLabel on DocFilter {
  String get label => switch (this) {
        DocFilter.original => 'Original',
        DocFilter.grayscale => 'Grayscale',
        DocFilter.blackWhite => 'B & W',
        DocFilter.enhance => 'Enhance',
      };
}

class _FilterParams {
  const _FilterParams(this.jpgs, this.filterIndex);
  final List<Uint8List> jpgs;
  final int filterIndex;
}

/// Pure-Dart image processing, safe to run in [compute].
List<Uint8List> _applyFilter(_FilterParams p) {
  final filter = DocFilter.values[p.filterIndex];
  final out = <Uint8List>[];
  for (final bytes in p.jpgs) {
    if (filter == DocFilter.original) {
      out.add(bytes);
      continue;
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      out.add(bytes);
      continue;
    }
    final img.Image result;
    switch (filter) {
      case DocFilter.grayscale:
        result = img.grayscale(decoded);
      case DocFilter.blackWhite:
        final gray = img.grayscale(decoded);
        final leveled = img.normalize(gray, min: 0, max: 255);
        result = img.luminanceThreshold(leveled, threshold: 0.55);
      case DocFilter.enhance:
        final leveled = img.normalize(decoded, min: 0, max: 255);
        result = img.contrast(leveled, contrast: 112);
      case DocFilter.original:
        result = decoded;
    }
    out.add(img.encodeJpg(result, quality: 85));
  }
  return out;
}

class FilterService {
  const FilterService._();

  static Future<List<Uint8List>> apply(
    List<Uint8List> jpgs,
    DocFilter filter,
  ) {
    return compute(_applyFilter, _FilterParams(jpgs, filter.index));
  }
}
