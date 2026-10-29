import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import '../../core/services/file_service.dart';
import '../shared/result_screen.dart';

/// Headline tool: uses the on-device ML Kit document scanner (edge detection,
/// perspective correction, filters) and saves the result as a PDF.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  int _pageLimit = 10;
  bool _busy = false;

  Future<void> _scan() async {
    setState(() => _busy = true);
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.pdf},
        mode: ScannerMode.full,
        pageLimit: _pageLimit,
        isGalleryImport: true,
      ),
    );
    try {
      final result = await scanner.scanDocument();
      final pdf = result.pdf;
      if (pdf == null) {
        // User cancelled, or no PDF was produced.
        return;
      }
      final srcPath = pdf.uri.startsWith('file://')
          ? Uri.parse(pdf.uri).toFilePath()
          : pdf.uri;
      final out = await FileService.newOutputPath('Scan', 'pdf');
      await File(srcPath).copy(out);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen(outputPath: out, title: 'Scan Document'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
    } finally {
      await scanner.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Document')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.document_scanner_outlined,
                  size: 68, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 24),
            Text('Scan to PDF',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Point the camera at a document. Edges are detected and corrected '
              'automatically. Everything stays on your phone.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Text('MAXIMUM PAGES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: scheme.onSurfaceVariant,
                )),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _pageLimit > 1
                      ? () => setState(() => _pageLimit--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Text(
                    '$_pageLimit',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _pageLimit < 30
                      ? () => setState(() => _pageLimit++)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _busy ? null : _scan,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.camera_alt_outlined),
              label: Text(_busy ? 'Opening scanner…' : 'Start scan'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
