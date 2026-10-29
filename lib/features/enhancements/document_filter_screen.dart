import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/services/file_service.dart';
import '../../core/services/filter_service.dart';
import '../../core/services/pdf_render_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/pick_service.dart';
import '../shared/result_screen.dart';

class DocumentFilterScreen extends StatefulWidget {
  const DocumentFilterScreen({super.key});

  @override
  State<DocumentFilterScreen> createState() => _DocumentFilterScreenState();
}

class _DocumentFilterScreenState extends State<DocumentFilterScreen> {
  String? _path;
  Uint8List? _previewSrc; // page 1 at low resolution
  Uint8List? _previewShown; // page 1 with the current filter
  DocFilter _filter = DocFilter.enhance;
  bool _busy = false;

  Future<void> _pick() async {
    final picked = await PickService.pdfs();
    if (picked.isEmpty) return;
    setState(() => _busy = true);
    try {
      final first = await PdfRenderService.render(picked.first,
          dpi: 90, indices: [0]);
      setState(() {
        _path = picked.first;
        _previewSrc = first.isEmpty ? null : first.first.jpg;
      });
      await _refreshPreview();
    } catch (e) {
      _snack('Could not open PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshPreview() async {
    final src = _previewSrc;
    if (src == null) return;
    final result = await FilterService.apply([src], _filter);
    if (!mounted) return;
    setState(() => _previewShown = result.first);
  }

  Future<void> _apply() async {
    final path = _path;
    if (path == null) return;
    setState(() => _busy = true);
    try {
      final rendered = await PdfRenderService.render(path, dpi: 150);
      final filtered =
          await FilterService.apply([for (final r in rendered) r.jpg], _filter);
      final specs = [
        for (var i = 0; i < rendered.length; i++)
          PageSpec(filtered[i], rendered[i].widthPt, rendered[i].heightPt),
      ];
      final out = await FileService.newOutputPath('Filtered', 'pdf');
      final result = await PdfService.assemble(pages: specs, outputPath: out);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen.single(outputPath: result, title: 'Scan Filters'),
        ),
      );
    } catch (e) {
      _snack('Could not apply: $e');
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
      appBar: AppBar(title: const Text('Scan Filters')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _path == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_fix_high_outlined,
                        size: 64, color: scheme.primary),
                    const SizedBox(height: 16),
                    Text('Clean up a PDF: grayscale, crisp B&W, or enhance',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : _pick,
                      icon: const Icon(Icons.file_open_outlined),
                      label: const Text('Choose a PDF'),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(12),
                      child: _previewShown == null
                          ? const CircularProgressIndicator()
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(_previewShown!,
                                  fit: BoxFit.contain),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<DocFilter>(
                    showSelectedIcon: false,
                    segments: [
                      for (final f in DocFilter.values)
                        ButtonSegment(value: f, label: Text(f.label)),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) {
                      setState(() => _filter = s.first);
                      _refreshPreview();
                    },
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _busy ? null : _apply,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: Text(_busy ? 'Applying…' : 'Apply to all pages'),
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
