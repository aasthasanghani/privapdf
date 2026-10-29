import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/file_service.dart';

/// Shown after a document is produced: confirms success and lets the user
/// send the file(s) out (save to Files, open in a viewer, share).
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.outputPaths,
    required this.title,
  });

  /// Convenience for the common single-file case.
  ResultScreen.single({
    super.key,
    required String outputPath,
    required this.title,
  }) : outputPaths = [outputPath];

  final List<String> outputPaths;
  final String title;

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
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Icon(Icons.check_circle_rounded, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              many ? '${outputPaths.length} files ready' : 'Document ready',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: outputPaths.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _FileCard(path: outputPaths[i]),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.ios_share),
              label: Text(many ? 'Share / Save all' : 'Share / Save'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to home'),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline,
                    size: 15, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Saved only on this device',
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isImage = RegExp(r'\.(jpe?g|png)$', caseSensitive: false).hasMatch(path);
    return Card(
      color: scheme.surfaceContainerHighest,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isImage
                  ? Icons.image_outlined
                  : Icons.picture_as_pdf_outlined,
              color: scheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FileService.fileName(path),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  FutureBuilder<String>(
                    future: FileService.readableSize(path),
                    builder: (context, snap) => Text(
                      snap.data ?? '…',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small helper so callers can confirm the file exists before navigating.
Future<bool> outputExists(String path) => File(path).exists();
