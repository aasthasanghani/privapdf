import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/file_service.dart';
import 'image_preview_screen.dart';
import 'pdf_preview_screen.dart';

/// Shown after a document is produced: a big preview of the result plus a way
/// to send the file(s) out (save to Files, open in a viewer, share).
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.outputPaths,
    required this.title,
  });

  ResultScreen.single({
    super.key,
    required String outputPath,
    required this.title,
  }) : outputPaths = [outputPath];

  final List<String> outputPaths;
  final String title;

  bool get _isPdf =>
      outputPaths.length == 1 &&
      outputPaths.first.toLowerCase().endsWith('.pdf');

  bool get _allImages => outputPaths.every((p) =>
      RegExp(r'\.(jpe?g|png)$', caseSensitive: false).hasMatch(p));

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        files: [for (final p in outputPaths) XFile(p)],
        subject: FileService.fileName(outputPaths.first),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final many = outputPaths.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_isPdf)
            IconButton(
              tooltip: 'Full screen',
              icon: const Icon(Icons.fullscreen),
              onPressed: () =>
                  openPdfPreview(context, outputPaths.first, title: title),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: scheme.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    many ? '${outputPaths.length} files ready' : 'Document ready',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _Preview(this)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.ios_share),
                      label: Text(many ? 'Share / Save all' : 'Share / Save'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Back to home'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview(this.result);

  final ResultScreen result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paths = result.outputPaths;

    Widget framed(Widget child) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        );

    if (result._isPdf) {
      return framed(PdfViewer.file(paths.first));
    }

    if (result._allImages) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: paths.length,
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => openImagePreview(context, paths[i]),
          child: Hero(
            tag: paths[i],
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(paths[i]), fit: BoxFit.cover),
            ),
          ),
        ),
      );
    }

    // Fallback (e.g. a .txt file): a simple card.
    return Center(
      child: framed(
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, size: 56, color: scheme.primary),
              const SizedBox(height: 12),
              Text(FileService.fileName(paths.first)),
            ],
          ),
        ),
      ),
    );
  }
}
