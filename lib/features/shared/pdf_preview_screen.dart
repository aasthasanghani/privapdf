import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/file_service.dart';

/// Full-screen, scrollable, pinch-to-zoom view of a PDF file.
class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key, required this.path, this.title});

  final String path;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? FileService.fileName(path),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share),
            onPressed: () => SharePlus.instance.share(
              ShareParams(files: [XFile(path)]),
            ),
          ),
        ],
      ),
      body: PdfViewer.file(path),
    );
  }
}

/// Opens the PDF viewer for [path].
void openPdfPreview(BuildContext context, String path, {String? title}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PdfPreviewScreen(path: path, title: title),
    ),
  );
}
