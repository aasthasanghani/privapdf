import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/file_service.dart';
import '../../core/services/pdf_render_service.dart';
import '../../core/services/pick_service.dart';
import '../shared/result_screen.dart';

class PdfToImagesScreen extends StatefulWidget {
  const PdfToImagesScreen({super.key});

  @override
  State<PdfToImagesScreen> createState() => _PdfToImagesScreenState();
}

class _PdfToImagesScreenState extends State<PdfToImagesScreen> {
  String? _path;
  int _pages = 0;
  double _dpi = 150;
  bool _busy = false;

  Future<void> _pick() async {
    final picked = await PickService.pdfs();
    if (picked.isEmpty) return;
    setState(() => _busy = true);
    try {
      final count = await PdfRenderService.pageCount(picked.first);
      setState(() {
        _path = picked.first;
        _pages = count;
      });
    } catch (e) {
      _snack('Could not open PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _convert() async {
    final path = _path;
    if (path == null) return;
    setState(() => _busy = true);
    try {
      final rendered = await PdfRenderService.render(path, dpi: _dpi);
      final dir = await FileService.outputDir();
      final stamp =
          DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      final outPaths = <String>[];
      for (var i = 0; i < rendered.length; i++) {
        final p = '${dir.path}/page_${i + 1}_$stamp.jpg';
        await File(p).writeAsBytes(rendered[i].jpg);
        outPaths.add(p);
      }
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen(outputPaths: outPaths, title: 'PDF to Images'),
        ),
      );
    } catch (e) {
      _snack('Could not convert: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('PDF to Images')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_path == null) ...[
              const Spacer(),
              Icon(Icons.photo_library_outlined,
                  size: 64, color: scheme.primary),
              const SizedBox(height: 16),
              Text('Turn each PDF page into a JPG image',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Choose a PDF'),
              ),
              const Spacer(),
            ] else ...[
              Card(
                color: scheme.surfaceContainerHighest,
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined,
                      color: scheme.primary),
                  title: Text(FileService.fileName(_path!),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('$_pages page${_pages == 1 ? '' : 's'}'),
                  trailing: TextButton(
                    onPressed: _busy ? null : _pick,
                    child: const Text('Change'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('QUALITY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: scheme.onSurfaceVariant,
                  )),
              const SizedBox(height: 6),
              SegmentedButton<double>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 96, label: Text('Screen')),
                  ButtonSegment(value: 150, label: Text('Standard')),
                  ButtonSegment(value: 220, label: Text('High')),
                ],
                selected: {_dpi},
                onSelectionChanged: (s) => setState(() => _dpi = s.first),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : _convert,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.image_outlined),
                label: Text(_busy ? 'Converting…' : 'Convert to images'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
