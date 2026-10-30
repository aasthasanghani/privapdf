import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/file_service.dart';

/// Full-screen, pinch-to-zoom view of an image file.
class ImagePreviewScreen extends StatelessWidget {
  const ImagePreviewScreen({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FileService.fileName(path),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          maxScale: 6,
          child: Image.file(File(path), fit: BoxFit.contain),
        ),
      ),
    );
  }
}

void openImagePreview(BuildContext context, String path) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ImagePreviewScreen(path: path)),
  );
}
