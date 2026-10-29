import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/file_service.dart';

/// Shown after a document is produced: confirms success and lets the user
/// send the file out (save to Files, open in a viewer, share).
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.outputPath, required this.title});

  final String outputPath;
  final String title;

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(outputPath)],
        subject: FileService.fileName(outputPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
              'Document ready',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Card(
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            FileService.fileName(outputPath),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          FutureBuilder<String>(
                            future: FileService.readableSize(outputPath),
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
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.ios_share),
              label: const Text('Share / Save'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context)
                  .popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to home'),
            ),
            const Spacer(),
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

/// Small helper so callers can confirm the file exists before navigating.
Future<bool> outputExists(String path) => File(path).exists();
